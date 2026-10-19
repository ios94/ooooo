//
//  AppearanceView.swift
//  AshteMobile
//
//  Created by samara on 7.05.2025.
//  Modernized Premium UI Integrated
//

import SwiftUI
import NimbleViews
import UIKit

// MARK: - View
struct AppearanceView: View {
    @AppStorage("AshteMobile.userInterfaceStyle")
    private var _userIntefacerStyle: Int = UIUserInterfaceStyle.unspecified.rawValue
    
    @AppStorage("AshteMobile.shouldTintIcons")
    private var _shouldTintIcons: Bool = false
    
    @AppStorage("AshteMobile.shouldChangeIconsBasedOffStyle")
    private var _shouldChangeIconsBasedOffStyle: Bool = false
    
    @AppStorage("AshteMobile.storeCellAppearance")
    private var _storeCellAppearance: Int = 0
    private let _storeCellAppearanceMethods: [(name: String, desc: String)] = [
        (.localized("Standard"), .localized("Default style for the app, only includes subtitle.")),
        (.localized("Big Description"), .localized("Adds the localized description of the app."))
    ]
    
    @AppStorage("AshteMobile.userTintColor")
    private var _selectedColorHex: String = "#7C5CFF"
    
    private var _tintColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: _selectedColorHex) },
            set: { _selectedColorHex = $0.toHex() }
        )
    }
    
    // MARK: Body
    var body: some View {
        ZStack {
            // باکگراوندی مۆدێرن بۆ پەڕەکە
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // MARK: - Appearance Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(.localized("Appearance"))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.leading, 8)
                        
                        VStack {
                            Picker(.localized("Appearance"), selection: $_userIntefacerStyle) {
                                ForEach(UIUserInterfaceStyle.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { style in
                                    Text(style.label).tag(style.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    }
                    
                    // MARK: - Theme Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(.localized("Theme"))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.leading, 8)
                        
                        VStack(spacing: 0) {
                            AppearanceTintColorView()
                                .padding(.vertical, 16)
                            
                            Divider().padding(.leading, 16)
                            
                            // Color Picker Row with Icon
                            ColorPicker(selection: _tintColorBinding, supportsOpacity: false) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Color.blue.opacity(0.15)
                                        Image(systemName: "paintpalette.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .frame(width: 32, height: 32)
                                    .cornerRadius(8)
                                    
                                    Text(.localized("Custom Theme Color"))
                                        .font(.system(size: 16))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                    }
                    
                    // MARK: - Library Section (iOS 18+)
                    if #available(iOS 18.0, *) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(.localized("Library"))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .padding(.leading, 8)
                            
                            VStack(spacing: 0) {
                                Toggle(isOn: $_shouldChangeIconsBasedOffStyle) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Color.orange.opacity(0.15)
                                            Image(systemName: "app.dashed")
                                                .foregroundColor(.orange)
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .frame(width: 32, height: 32)
                                        .cornerRadius(8)
                                        
                                        Text(.localized("Dynamic Icons"))
                                            .font(.system(size: 16))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                
                                if #available(iOS 18.2, *) {
                                    Divider().padding(.leading, 60)
                                    Toggle(isOn: $_shouldTintIcons) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Color.purple.opacity(0.15)
                                                Image(systemName: "drop.fill")
                                                    .foregroundColor(.purple)
                                                    .font(.system(size: 14, weight: .semibold))
                                            }
                                            .frame(width: 32, height: 32)
                                            .cornerRadius(8)
                                            
                                            Text(.localized("Tinted Icons"))
                                                .font(.system(size: 16))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                            }
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                        }
                    }
                    
                    // MARK: - Sources Section (Custom Radio List)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(.localized("Sources"))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.leading, 8)
                        
                        VStack(spacing: 0) {
                            ForEach(0..<_storeCellAppearanceMethods.count, id: \.self) { index in
                                let method = _storeCellAppearanceMethods[index]
                                
                                Button(action: {
                                    // گۆڕینی هەڵبژاردن بە شێوەی ئەنیمەیشن
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        _storeCellAppearance = index
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(method.name)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.primary)
                                            Text(method.desc)
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                        
                                        if _storeCellAppearance == index {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(Color(hex: _selectedColorHex)) // ڕەنگەکەی دەگۆڕێت بەپێی تیمی بەرنامەکە
                                                .font(.system(size: 16, weight: .bold))
                                        }
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if index < _storeCellAppearanceMethods.count - 1 {
                                    Divider().padding(.leading, 16)
                                }
                            }
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
        .navigationTitle(.localized("Appearance"))
        .onChange(of: _userIntefacerStyle) { value in
            if let style = UIUserInterfaceStyle(rawValue: value) {
                UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
            }
        }
    }
}
