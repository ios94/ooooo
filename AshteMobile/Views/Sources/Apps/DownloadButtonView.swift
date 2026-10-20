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
				.background(AshteTheme.violet.opacity(0.12))
				.clipShape(Capsule())
			} else if let currentDownload = downloadManager.getDownload(by: app.currentUniqueId) {
				ZStack {
					Circle()
						.trim(from: 0, to: downloadProgress)
						.stroke(AshteTheme.primary, style: StrokeStyle(lineWidth: 2.8, lineCap: .round))
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
						AshteAutoSigner.markDownloadStart(id: app.currentUniqueId)
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
						.lineLimit(1)
				}
				.buttonStyle(AshteGradientButtonStyle(horizontalPadding: 22, verticalPadding: 6))
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
		
		AshteAutoSigner.signAfterDownload(id: app.currentUniqueId, appName: app.name) { result in
			self.isSigning = false
			
			if case .signed = result {
				NotificationCenter.default.post(name: Notification.Name("AshteMobile.installApp"), object: nil)
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
