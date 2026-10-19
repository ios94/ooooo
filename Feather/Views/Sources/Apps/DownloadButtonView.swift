//
//  DownloadButtonView.swift
//  AshteMobile
//
//  Created by samsam on 7/25/25.
//

import SwiftUI
import Combine
import AltSourceKit
import NimbleViews
import CoreData
import UIKit

// 💡 قفڵی گشتی بۆ ڕێگریکردن لە دوو جار جێبەجێبوونی فەرمانەکان
class SigningLock {
	static var activeSigningId: String? = nil
}

struct DownloadButtonView: View {
	let app: ASRepository.App
	@ObservedObject private var downloadManager = DownloadManager.shared

	@State private var downloadProgress: Double = 0
	@State private var cancellable: AnyCancellable?
    
	@State private var isDownloading = false
	@State private var isSigning = false
    
	@AppStorage("AshteMobile.installationMethod") private var installationMethod: Int = 0

	var body: some View {
		ZStack {
			if isSigning {
				HStack(spacing: 6) {
					ProgressView()
						.controlSize(.small)
					Text(.localized("Signing..."))
						.font(.subheadline.bold())
						.foregroundStyle(Color.accentColor)
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 6)
				.background(Color(uiColor: .quaternarySystemFill))
				.clipShape(Capsule())
			} else if let currentDownload = downloadManager.getDownload(by: app.currentUniqueId) {
				ZStack {
					Circle()
						.trim(from: 0, to: downloadProgress)
						.stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2.3, lineCap: .round))
						.rotationEffect(.degrees(-90))
						.frame(width: 31, height: 31)
                        .safeSmoothAnimation(value: downloadProgress)

					Image(systemName: downloadProgress >= 0.75 ? "archivebox" : "square.fill")
						.foregroundStyle(.tint)
						.font(.footnote.weight(.bold))
				}
				.onTapGesture {
					if downloadProgress <= 0.75 {
						downloadManager.cancelDownload(currentDownload)
					}
				}
				.compatTransition()
			} else {
				Button {
					if let url = app.currentDownloadUrl {
                        // 💡 لێرەدا کێشەکەمان بەتەواوی بنبڕ کرد! ناو و لۆگۆکە دەنێرین
						_ = downloadManager.startDownload(
                            from: url, 
                            id: app.currentUniqueId,
                            appName: app.name,           // 💡 ناوی یارییەکە
                            appIconURL: app.iconURL      // 💡 لۆگۆی یارییەکە
                        )
					}
				} label: {
					Text(.localized("Get")) 
						.lineLimit(0)
						.font(.headline.weight(.bold))
						.foregroundStyle(Color.accentColor) 
						.padding(.horizontal, 22) 
						.padding(.vertical, 6)
						.background(Color(uiColor: .tertiarySystemFill)) 
						.clipShape(Capsule())
				}
				.buttonStyle(.borderless)
				.compatTransition()
			}
		}
		.onAppear(perform: setupObserver)
		.onDisappear { cancellable?.cancel() }
		.onChange(of: downloadManager.downloads.count) { _ in
			let isCurrentlyDownloading = downloadManager.getDownload(by: app.currentUniqueId) != nil
            
			if isCurrentlyDownloading {
				isDownloading = true
				setupObserver()
			} else if isDownloading && !isCurrentlyDownloading {
				isDownloading = false
                
				if downloadProgress >= 0.98 {
					let generator = UINotificationFeedbackGenerator()
					generator.notificationOccurred(.success)
					isSigning = true
					handleAutoSign()
				}
			}
		}
		.animation(.easeInOut(duration: 0.3), value: downloadManager.getDownload(by: app.currentUniqueId) != nil)
		.animation(.easeInOut(duration: 0.3), value: isSigning)
	}

	private func setupObserver() {
		cancellable?.cancel()
		guard let download = downloadManager.getDownload(by: app.currentUniqueId) else {
			downloadProgress = 0
			return
		}
		downloadProgress = download.overallProgress

		let publisher = Publishers.CombineLatest(
			download.$progress,
			download.$unpackageProgress
		)

		cancellable = publisher.sink { _, _ in
			downloadProgress = download.overallProgress
		}
	}
    
	private func handleAutoSign() {
		if installationMethod == 1 {
			self.isSigning = false
			return
		}
        
		if SigningLock.activeSigningId == app.currentUniqueId {
			self.isSigning = false
			return
		}
		SigningLock.activeSigningId = app.currentUniqueId 
        
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
			let request = NSFetchRequest<Imported>(entityName: "Imported")
			request.sortDescriptors = [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]
			request.fetchLimit = 1 
            
			guard let importedApps = try? Storage.shared.context.fetch(request),
				  let importedApp = importedApps.first else {
				self.isSigning = false
				SigningLock.activeSigningId = nil
				return
			}
            
			let options = OptionsManager.shared.options
			let certRequest = NSFetchRequest<CertificatePair>(entityName: "CertificatePair")
			certRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
			let certs = try? Storage.shared.context.fetch(certRequest)
			let storedCertIndex = UserDefaults.standard.integer(forKey: "ashtemobile.selectedCert")
			let selectedCert = (certs?.indices.contains(storedCertIndex) == true) ? certs![storedCertIndex] : certs?.first
            
			FR.signPackageFile(
				importedApp,
				using: options,
				icon: nil,
				certificate: selectedCert
			) { error in
				DispatchQueue.main.async {
					self.isSigning = false
					SigningLock.activeSigningId = nil 
                    
					if error == nil {
						if options.post_deleteAppAfterSigned {
							Storage.shared.deleteApp(for: importedApp)
						}
						NotificationCenter.default.post(name: Notification.Name("AshteMobile.installApp"), object: nil)
					} else {
						let errorGenerator = UINotificationFeedbackGenerator()
						errorGenerator.notificationOccurred(.error)
					}
				}
			}
		}
	}
}

// MARK: - Compatibility Extensions
private extension View {
    @ViewBuilder
    func safeSmoothAnimation<V: Equatable>(value: V) -> some View {
        if #available(iOS 17.0, *) {
            self.animation(.smooth, value: value)
        } else {
            self.animation(.easeInOut, value: value)
        }
    }
}
