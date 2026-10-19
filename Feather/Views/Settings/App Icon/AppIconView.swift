//
//  AppIconView.swift
//  AshteMobile
//
//  Created by samara on 19.06.2025.
//  Modernized Premium UI Integrated
//

import SwiftUI
import NimbleViews

// MARK: - View extension: Model
extension AppIconView {
    struct AltIcon: Identifiable {
        var displayName: String
        var author: String
        var key: String?
        var image: UIImage
        var id: String { key ?? displayName }
        
        init(displayName: String, author: String, key: String? = nil) {
            self.displayName = displayName
            self.author = author
            self.key = key
            self.image = altImage(key)
        }
    }
    
    static func altImage(_ name: String?) -> UIImage {
        let path = Bundle.main.bundleURL.appendingPathComponent((name ?? "AppIcon60x60") + "@2x.png")
        return UIImage(contentsOfFile: path.path) ?? UIImage()
    }
}

// MARK: - View
struct AppIconView: View {
    @Binding var currentIcon: String?
    
    // 💡 لێرەدا هەموو ئایکۆنە زیادەکان سڕدراونەتەوە و تەنها ناوی خۆت دانراوە
    var sections: [String: [AltIcon]] = [
        "Store Icon": [
            AltIcon(displayName: "AshteMobile", author: "Official", key: nil)
        ]
    ]
    
    var body: some View {
        ZStack {
            // باکگراوندی مۆدێرن بۆ پەڕەکە
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - App Icon Section
                    ForEach(sections.keys.sorted(), id: \.self) { section in
                        if let icons = sections[section] {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(section)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .padding(.leading, 8)
                                
                                VStack(spacing: 0) {
                                    ForEach(icons.indices, id: \.self) { index in
                                        _icon(icon: icons[index])
                                        
                                        if index < icons.count - 1 {
                                            Divider().padding(.leading, 85) // هێڵی جیاکەرەوە
                                        }
                                    }
                                }
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                    
                    // MARK: - Links & Social Media Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Links & Social")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.leading, 8)
                        
                        VStack(spacing: 0) {
                            // 1. Website Link
                            _linkRow(
                                icon: "safari.fill",
                                iconColor: .indigo,
                                title: "Official Website",
                                url: "https://ashtemobile.site"
                            )
                            
                            Divider().padding(.leading, 60)
                            
                            // 2. Telegram Link
                            _linkRow(
                                icon: "paperplane.fill",
                                iconColor: .blue,
                                title: "Telegram Channel",
                                url: "https://t.me/ashtemobile"
                            )
                            
                            Divider().padding(.leading, 60)
                            
                            // 3. TikTok Link
                            _linkRow(
                                icon: "play.tv.fill",
                                iconColor: .pink,
                                title: "TikTok",
                                url: "https://www.tiktok.com/@ashtemobile"
                            )
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    }
                    
                    Spacer().frame(height: 50)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
        }
        .navigationTitle(.localized("App Icon"))
        .onAppear {
            currentIcon = UIApplication.shared.alternateIconName
        }
    }
}

// MARK: - View extension (Helper Views)
extension AppIconView {
    
    // دیزاینی مۆدێرن بۆ ئایکۆنی بەرنامەکە
    @ViewBuilder
    private func _icon(icon: AppIconView.AltIcon) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            UIApplication.shared.setAlternateIconName(icon.key) { _ in
                currentIcon = UIApplication.shared.alternateIconName
            }
        } label: {
            HStack(spacing: 16) {
                Image(uiImage: icon.image)
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(icon.displayName)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(icon.author)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if currentIcon == icon.key {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // دیزاینی مۆدێرن بۆ ڕیزەکانی وێبسایت و سۆشیاڵ میدیا
    @ViewBuilder
    private func _linkRow(icon: String, iconColor: Color, title: String, url: String) -> some View {
        Button(action: {
            if let targetURL = URL(string: url) {
                UIApplication.shared.open(targetURL)
            }
        }) {
            HStack(spacing: 15) {
                ZStack {
                    iconColor.opacity(0.15)
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(width: 32, height: 32)
                .cornerRadius(8)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(UIColor.tertiaryLabel)) // ڕەنگی ستانداردی ئەپڵ
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
