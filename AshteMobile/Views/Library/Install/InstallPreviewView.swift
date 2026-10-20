//
//  InstallPreview.swift
//  AshteMobile
//
//  Created by samara on 22.04.2025.
//

import SwiftUI
import NimbleViews
import IDeviceSwift
import OSLog

// MARK: - View
struct InstallPreviewView: View {
	@Environment(\.dismiss) var dismiss

	@AppStorage("AshteMobile.useShareSheetForArchiving") private var _useShareSheet: Bool = false
	@AppStorage("AshteMobile.installationMethod") private var _installationMethod: Int = 0
	@State private var _isWebviewPresenting = false
	@State private var progressTask: Task<Void, Never>?
	@State private var installRequestWatchdog: Task<Void, Never>?
	
	var app: AppInfoPresentable
	@StateObject var viewModel: InstallerStatusViewModel
	@StateObject var installer: ServerInstaller
	
	@State var isSharing: Bool
	
	init(app: AppInfoPresentable, isSharing: Bool = false) {
		self.app = app
		self.isSharing = isSharing
		let viewModel = InstallerStatusViewModel(isIdevice: UserDefaults.standard.integer(forKey: "AshteMobile.installationMethod") == 1)
		self._viewModel = StateObject(wrappedValue: viewModel)
		self._installer = StateObject(wrappedValue: try! ServerInstaller(app: app, viewModel: viewModel))
	}
	
	// MARK: Body
	var body: some View {
		let cornerRadius = {
			if #available(iOS 26.0, *) {
				28.0
			} else {
				10.5
			}
		}()
		
		ZStack {
			InstallProgressView(app: app, viewModel: viewModel)
			_status()
			_button()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
		.background(Color(UIColor.secondarySystemBackground))
		.cornerRadius(cornerRadius)
		.padding()
		.sheet(isPresented: $_isWebviewPresenting) {
			SafariRepresentableView(url: installer.pageEndpoint).ignoresSafeArea()
		}
		.onReceive(viewModel.$status) { newStatus in
			if _installationMethod == 0 {
				if case .ready = newStatus {
					_launchOTAInstall()
				}
				
				if case .sendingManifest = newStatus {
					installRequestWatchdog?.cancel()
					installRequestWatchdog = nil
				}

				if case .sendingPayload = newStatus {
					installRequestWatchdog?.cancel()
					installRequestWatchdog = nil
					_isWebviewPresenting = false
				}
				
				if case .installing = newStatus {
					if progressTask == nil {
						progressTask = startInstallProgressPolling(
							bundleID: app.identifier!,
							viewModel: viewModel
						)
					}
				}
                
				switch newStatus {
				case .completed, .broken(_):
					progressTask?.cancel()
					progressTask = nil
					BackgroundAudioManager.shared.stop()
				default:
					break
				}
			}
		}
        // 💡 لێرەدا کێشەی هێنانەوەی ناوی ئەپە کۆنەکەمان بە یەکجاری ڕیشەکێش کرد!
		.onAppear {
            self.installer.app = self.app // 👈 سێرڤەرەکە ناچار دەکەین ئەپە نوێیەکە بخوێنێتەوە
            BackgroundAudioManager.shared.start()
            _install()
        }
		.onDisappear {
			progressTask?.cancel()
			progressTask = nil
			installRequestWatchdog?.cancel()
			installRequestWatchdog = nil
            BackgroundAudioManager.shared.stop()
        }
	}
	
	@ViewBuilder
	private func _status() -> some View {
		Label(viewModel.statusLabel, systemImage: viewModel.statusImage)
			.padding()
			.labelStyle(.titleAndIcon)
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
			.animation(.smooth, value: viewModel.statusImage)
	}
	
	@ViewBuilder
	private func _button() -> some View {
		ZStack {
			if viewModel.isCompleted {
				Button {
					UIApplication.openApp(with: app.identifier ?? "")
				} label: {
					NBButton("Open", systemImage: "", style: .text)
				}
				.padding()
				.compatTransition()
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
		.animation(.easeInOut(duration: 0.3), value: viewModel.isCompleted)
	}
	
	private func _install() {
		guard isSharing || app.identifier != Bundle.main.bundleIdentifier! || _installationMethod == 1 else {
			UIAlertController.showAlertWithOk(
				title: .localized("Install"),
				message: .localized("You cannot update ‘%@‘ with itself, please use an alternative tool to update it.", arguments: Bundle.main.name)
			)
			return
		}
				
		Task.detached {
			do {
				let handler = await ArchiveHandler(app: app, viewModel: viewModel)
				try await handler.move()
				
				let packageUrl = try await handler.archive()
				
				if await !isSharing {
					if await _installationMethod == 0 {
						await MainActor.run {
							installer.packageUrl = packageUrl
							viewModel.status = .ready
						}
						
						if case .installing = await viewModel.status {
							let task = await startInstallProgressPolling(
								bundleID: app.identifier!,
								viewModel: viewModel
							)

							await MainActor.run {
								progressTask = task
							}
						}
					} else if await _installationMethod == 1 {
						let handler = await InstallationProxy(viewModel: viewModel)
						try await handler.install(at: packageUrl, suspend: app.identifier == Bundle.main.bundleIdentifier!)
					}
				} else {
					let package = try await handler.moveToArchive(packageUrl, shouldOpen: !_useShareSheet)
					
					if await !_useShareSheet {
						await MainActor.run {
							dismiss()
						}
					} else {
						if let package {
							await MainActor.run {
								dismiss()
								UIActivityViewController.show(activityItems: [package])
							}
						}
					}
				}
			} catch {
				await progressTask?.cancel()
				
				await MainActor.run {
					UIAlertController.showAlertWithOk(
						title: .localized("Install"),
						message: String(describing: error),
						action: {
							HeartbeatManager.shared.start(true)
							dismiss()
						}
					)
				}
			}
		}
	}

	private func _launchOTAInstall() {
		BackgroundAudioManager.shared.start()
		guard let url = URL(string: installer.iTunesLinkExternal) else {
			viewModel.status = .broken(NSError(
				domain: "AshteMobile.Install",
				code: 1,
				userInfo: [NSLocalizedDescriptionKey: "Unable to create the AshteMobile installation link."]
			))
			return
		}

		UIApplication.shared.open(url) { opened in
			guard opened else {
				viewModel.status = .broken(NSError(
					domain: "AshteMobile.Install",
					code: 2,
					userInfo: [NSLocalizedDescriptionKey: "iOS could not open the AshteMobile installation link. Please retry."]
				))
				return
			}

			installRequestWatchdog?.cancel()
			installRequestWatchdog = Task {
				try? await Task.sleep(nanoseconds: 12_000_000_000)
				guard !Task.isCancelled else { return }
				if case .ready = viewModel.status {
					viewModel.status = .broken(NSError(
						domain: "AshteMobile.Install",
						code: 3,
						userInfo: [NSLocalizedDescriptionKey: "iOS did not request the installation. Keep AshteMobile open and retry."]
					))
				}
			}
		}
	}
		
	private func startInstallProgressPolling(
		bundleID: String,
		viewModel: InstallerStatusViewModel
	) -> Task<Void, Never> {

		Task.detached(priority: .background) {
			var hasStarted = false

			while !Task.isCancelled {
				let rawProgress = await UIApplication.installProgress(for: bundleID) ?? 0.0

				if rawProgress > 0 {
					hasStarted = true
				}

				let progress = await hasStarted
					? _normalizeInstallProgress(rawProgress)
					: 0.0

				Logger.misc.info("Install progress for \(bundleID): \(progress)")

				await MainActor.run {
					viewModel.installProgress = progress
				}

				if hasStarted && rawProgress == 0 {
					await MainActor.run {
						viewModel.installProgress = 1.0
						viewModel.status = .completed(.success(()))
					}
					break
				}

				try? await Task.sleep(nanoseconds: 1_000_000) // 1 ms
			}
		}
	}

	private func _normalizeInstallProgress(_ rawProgress: Double) -> Double {
		min(1.0, max(0.0, (rawProgress - 0.6) / 0.3))
	}
}
