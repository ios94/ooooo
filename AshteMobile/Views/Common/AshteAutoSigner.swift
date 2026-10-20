//
//  AshteAutoSigner.swift
//  AshteMobile
//
//  One safe place for "download finished -> sign the app that was just imported".
//  Fixes: signing the WRONG (older) app when the import was slower than a fixed delay,
//  double signing from two views, and silent failures.
//

import Foundation
import CoreData
import UIKit

enum AshteAutoSignResult {
	case signed(Imported)
	case skipped
	case failed(Error)
}

enum AshteAutoSignError: LocalizedError {
	case importTimeout
	case noCertificate
	
	var errorDescription: String? {
		switch self {
		case .importTimeout:
			return String.localized("The downloaded app could not be found in your library. Please try again.")
		case .noCertificate:
			return String.localized("No certificate found. Please add a certificate in Settings first.")
		}
	}
}

enum AshteAutoSigner {
	private static var _startTimes: [String: Date] = [:]
	
	/// Call this at the moment the user taps "Get".
	static func markDownloadStart(id: String) {
		_startTimes[id] = Date()
	}
	
	/// Waits for the app that was imported after `markDownloadStart`, then signs it.
	static func signAfterDownload(
		id: String,
		appName: String,
		completion: @escaping (AshteAutoSignResult) -> Void
	) {
		// Only the first caller gets the start time, so two views can never sign twice.
		guard let start = _startTimes.removeValue(forKey: id) else {
			completion(.skipped)
			return
		}
		
		_waitForImport(since: start.addingTimeInterval(-1), appName: appName, attempt: 0) { imported in
			guard let imported else {
				_fail(AshteAutoSignError.importTimeout, completion)
				return
			}
			
			let options = OptionsManager.shared.options
			let certificate = selectedCertificate()
			
			if certificate == nil && options.signingOption == .default {
				_fail(AshteAutoSignError.noCertificate, completion)
				return
			}
			
			FR.signPackageFile(
				imported,
				using: options,
				icon: nil,
				certificate: certificate
			) { error in
				if let error {
					_fail(error, completion)
					return
				}
				
				if options.post_deleteAppAfterSigned {
					Storage.shared.deleteApp(for: imported)
				}
				completion(.signed(imported))
			}
		}
	}
	
	/// Same certificate the Signing screen uses (index into certificates sorted by newest).
	static func selectedCertificate() -> CertificatePair? {
		let request = NSFetchRequest<CertificatePair>(entityName: "CertificatePair")
		request.sortDescriptors = [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
		let certificates = (try? Storage.shared.context.fetch(request)) ?? []
		let index = UserDefaults.standard.integer(forKey: "ashtemobile.selectedCert")
		return certificates.indices.contains(index) ? certificates[index] : certificates.first
	}
	
	// MARK: - Private
	private static func _waitForImport(
		since: Date,
		appName: String,
		attempt: Int,
		found: @escaping (Imported?) -> Void
	) {
		let request = NSFetchRequest<Imported>(entityName: "Imported")
		request.predicate = NSPredicate(format: "date >= %@", since as NSDate)
		request.sortDescriptors = [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]
		let results = (try? Storage.shared.context.fetch(request)) ?? []
		
		let match = results.first(where: {
			let name = $0.name ?? ""
			return !name.isEmpty && (name.localizedCaseInsensitiveContains(appName) || appName.localizedCaseInsensitiveContains(name))
		}) ?? results.first
		
		if let match {
			found(match)
			return
		}
		
		// up to ~30 seconds for big IPA files
		guard attempt < 60 else {
			found(nil)
			return
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			_waitForImport(since: since, appName: appName, attempt: attempt + 1, found: found)
		}
	}
	
	private static func _fail(_ error: Error, _ completion: @escaping (AshteAutoSignResult) -> Void) {
		DispatchQueue.main.async {
			UINotificationFeedbackGenerator().notificationOccurred(.error)
			_presentAlert(message: error.localizedDescription)
			completion(.failed(error))
		}
	}
	
	private static func _presentAlert(message: String) {
		guard
			let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
			var top = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
		else { return }
		
		while let presented = top.presentedViewController {
			top = presented
		}
		
		let alert = UIAlertController(
			title: String.localized("Signing Failed"),
			message: message,
			preferredStyle: .alert
		)
		alert.addAction(UIAlertAction(title: String.localized("OK"), style: .default))
		top.present(alert, animated: true)
	}
}
