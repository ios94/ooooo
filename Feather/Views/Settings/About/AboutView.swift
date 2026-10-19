//
//  AboutView.swift
//  AshteMobile
//
//  Modified for AshteMobile
//

import SwiftUI
import NimbleViews

// MARK: - View
struct AboutView: View {
	
	// MARK: Body
	var body: some View {
		NBList("About") {
			Section {
				VStack {
					// وێنەی لۆگۆکەت
					AsyncImage(url: URL(string: "https://ashtemobile.site/a.png")) { image in
						image.resizable().scaledToFit()
					} placeholder: {
						ProgressView()
					}
					.frame(width: 80, height: 80)
					.clipShape(RoundedRectangle(cornerRadius: 16))
					
					// ناوی ئەپەکە
					Text("AshteMobile")
						.font(.largeTitle)
						.bold()
						.foregroundStyle(Color.accentColor)
					
					HStack(spacing: 4) {
						Text("Version")
						Text(Bundle.main.version)
					}
					.font(.footnote)
					.foregroundStyle(.secondary)
				}
				.padding(.vertical)
			}
			.frame(maxWidth: .infinity)
			.listRowBackground(EmptyView())
			
			// بەشی سۆشیاڵ میدیاکان
			NBSection("Social Media") {
				_socialRow(name: "Telegram", url: "https://t.me/ashtemobile", icon: "paperplane.fill", color: .blue)
				_socialRow(name: "Instagram", url: "https://www.instagram.com/ashtemobile", icon: "camera.fill", color: .purple)
				_socialRow(name: "TikTok", url: "https://www.tiktok.com/@ashtemobile", icon: "play.tv.fill", color: .primary)
				_socialRow(name: "Snapchat", url: "https://www.snapchat.com//add/ashtemzere", icon: "camera.filters", color: .yellow)
			}
			
			// ناوی خۆت لە خوارەوە
			Section {
				Text("BY AshteMobile❤️")
					.font(.callout)
					.bold()
					.foregroundStyle(.secondary)
					.frame(maxWidth: .infinity, alignment: .center)
					.padding(.top, 10)
			}
			.listRowBackground(EmptyView())
		}
	}
}

// MARK: - Extension: view
extension AboutView {
	@ViewBuilder
	private func _socialRow(name: String, url: String, icon: String, color: Color) -> some View {
		Button {
			if let parsedUrl = URL(string: url) {
				UIApplication.shared.open(parsedUrl)
			}
		} label: {
			HStack {
				Image(systemName: icon)
					.foregroundColor(color)
					.frame(width: 30)
				
				Text(name)
					.foregroundColor(.primary)
				
				Spacer()
				
				Image(systemName: "arrow.up.right")
					.foregroundColor(.secondary.opacity(0.65))
			}
			.padding(.vertical, 4)
		}
	}
}
