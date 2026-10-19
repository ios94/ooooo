//
//  SigningView.swift
//  AshteMobile
//
//  Created by samara on 14.04.2025.
//  Modernized UI Integrated - Fixed Concurrent Signing Bug ⚡️
//

import SwiftUI
import PhotosUI
import NimbleViews

// MARK: - View
struct SigningView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var _optionsManager = OptionsManager.shared
    
    @State private var _temporaryOptions: Options = OptionsManager.shared.options
    @State private var _temporaryCertificate: Int
    @State private var _isAltPickerPresenting = false
    @State private var _isFilePickerPresenting = false
    @State private var _isImagePickerPresenting = false
    @State private var _isSigning = false
    @State private var _selectedPhoto: PhotosPickerItem? = nil
    @State var appIcon: UIImage?
    
    // MARK: Fetch
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var certificates: FetchedResults<CertificatePair>
    
    private func _selectedCert() -> CertificatePair? {
        guard certificates.indices.contains(_temporaryCertificate) else { return nil }
        return certificates[_temporaryCertificate]
    }
    
    var app: AppInfoPresentable
    
    init(app: AppInfoPresentable) {
        self.app = app
        let storedCert = UserDefaults.standard.integer(forKey: "ashtemobile.selectedCert")
        __temporaryCertificate = State(initialValue: storedCert)
    }
        
    // MARK: Body
    var body: some View {
        NBNavigationView("", displayMode: .inline) {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        _customizationOptions(for: app)
                        _cert()
                        _customizationProperties(for: app)
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
            }
            .overlay {
                VStack(spacing: 0) {
                    Spacer()
                    NBVariableBlurView()
                        .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 90 : 110)
                        .rotationEffect(.degrees(180))
                        .overlay {
                            Button {
                                _start()
                            } label: {
                                Text(_isSigning ? .localized("Signing...") : .localized("Start Signing"))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(colors: [AshteTheme.violet, AshteTheme.pink], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: AshteTheme.violet.opacity(0.45), radius: 12, x: 0, y: 6)
                            }
                            .padding(.horizontal, 20)
                            .offset(y: UIDevice.current.userInterfaceIdiom == .pad ? -15 : -30)
                            .disabled(_isSigning)
                        }
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .toolbar {
                NBToolbarButton(role: .dismiss)
                ToolbarItem(placement: .principal) {
                    Image("Glyph")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 38)
                }
                NBToolbarButton(
                    .localized("Reset"),
                    style: .text,
                    placement: .topBarTrailing
                ) {
                    _temporaryOptions = OptionsManager.shared.options
                    appIcon = nil
                }
            }
            .sheet(isPresented: $_isAltPickerPresenting) { SigningAlternativeIconView(app: app, appIcon: $appIcon, isModifing: .constant(true)) }
            .sheet(isPresented: $_isFilePickerPresenting) {
                FileImporterRepresentableView(
                    allowedContentTypes:  [.image],
                    onDocumentsPicked: { urls in
                        guard let selectedFileURL = urls.first else { return }
                        self.appIcon = UIImage.fromFile(selectedFileURL)?.resizeToSquare()
                    }
                )
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $_isImagePickerPresenting, selection: $_selectedPhoto)
            .onChange(of: _selectedPhoto) { newValue in
                guard let newValue else { return }
                
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: data)?.resizeToSquare() {
                        appIcon = image
                    }
                }
            }
            .disabled(_isSigning)
            .animation(.smooth, value: _isSigning)
        }
        .onAppear {
            if
                _optionsManager.options.ppqProtection,
                let identifier = app.identifier,
                let cert = _selectedCert(),
                cert.ppQCheck
            {
                _temporaryOptions.appIdentifier = "\(identifier).\(_optionsManager.options.ppqString)"
            }
            
            if
                let currentBundleId = app.identifier,
                let newBundleId = _temporaryOptions.identifiers[currentBundleId]
            {
                _temporaryOptions.appIdentifier = newBundleId
            }
            
            if
                let currentName = app.name,
                let newName = _temporaryOptions.displayNames[currentName]
            {
                _temporaryOptions.appName = newName
            }
        }
    }
}

// MARK: - Extension: View UI Components
extension SigningView {
    @ViewBuilder
    private func _customizationOptions(for app: AppInfoPresentable) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: .localized("Customization"))
            
            VStack(spacing: 0) {
                HStack {
                    Menu {
                        Button(.localized("Select Alternative Icon"), systemImage: "app.dashed") { _isAltPickerPresenting = true }
                        Button(.localized("Choose from Files"), systemImage: "folder") { _isFilePickerPresenting = true }
                        Button(.localized("Choose from Photos"), systemImage: "photo") { _isImagePickerPresenting = true }
                    } label: {
                        if let icon = appIcon {
                            Image(uiImage: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 65, height: 65)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        } else {
                            FRAppIconView(app: app, size: 65)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                    }
                    Spacer()
                }
                .padding()
                
                Divider().padding(.leading, 16)
                
                _infoCell(icon: "pencil", iconColor: .blue, title: .localized("Name"), desc: _temporaryOptions.appName ?? app.name) {
                    SigningPropertiesView(
                        title: .localized("Name"),
                        initialValue: _temporaryOptions.appName ?? (app.name ?? ""),
                        bindingValue: $_temporaryOptions.appName
                    )
                }
                Divider().padding(.leading, 50)
                _infoCell(icon: "tag.fill", iconColor: .orange, title: .localized("Identifier"), desc: _temporaryOptions.appIdentifier ?? app.identifier) {
                    SigningPropertiesView(
                        title: .localized("Identifier"),
                        initialValue: _temporaryOptions.appIdentifier ?? (app.identifier ?? ""),
                        bindingValue: $_temporaryOptions.appIdentifier
                    )
                }
                Divider().padding(.leading, 50)
                _infoCell(icon: "number", iconColor: .purple, title: .localized("Version"), desc: _temporaryOptions.appVersion ?? app.version) {
                    SigningPropertiesView(
                        title: .localized("Version"),
                        initialValue: _temporaryOptions.appVersion ?? (app.version ?? ""),
                        bindingValue: $_temporaryOptions.appVersion
                    )
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
    
    @ViewBuilder
    private func _cert() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: .localized("Signing"))
            
            VStack(spacing: 0) {
                if let cert = _selectedCert() {
                    NavigationLink {
                        CertificatesView(selectedCert: $_temporaryCertificate)
                    } label: {
                        HStack(spacing: 16) {
                            
                            ZStack {
                                LinearGradient(
                                    colors: [Color(hex: "#baf2d1"), Color(hex: "#e2f9eb")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(Color(hex: "#15a84e"))
                                    .font(.system(size: 28, weight: .bold))
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.green.opacity(0.2), radius: 6, x: 0, y: 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
                            )
                            
                            CertificatesCellView(cert: cert)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(UIColor.tertiaryLabel))
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Text(.localized("No Certificate"))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
    
    @ViewBuilder
    private func _customizationProperties(for app: AppInfoPresentable) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: .localized("Advanced"))
            
            VStack(spacing: 0) {
                DisclosureGroup {
                    VStack(spacing: 0) {
                        Divider().padding(.leading, 16)
                        _navRow(title: .localized("Existing Dylibs")) { SigningDylibView(app: app, options: $_temporaryOptions.optional()) }
                        
                        Divider().padding(.leading, 16)
                        _navRow(title: .localized("Frameworks & PlugIns")) { SigningFrameworksView(app: app, options: $_temporaryOptions.optional()) }
                        
                        #if NIGHTLY || DEBUG
                        Divider().padding(.leading, 16)
                        _navRow(title: .localized("Entitlements") + " (BETA)") { SigningEntitlementsView(bindingValue: $_temporaryOptions.appEntitlementsFile) }
                        #endif
                        
                        Divider().padding(.leading, 16)
                        _navRow(title: .localized("Tweaks")) { SigningTweaksView(options: $_temporaryOptions) }
                    }
                    .padding(.leading, 16)
                } label: {
                    ActionRow(icon: "wrench.adjustable.fill", iconColor: .teal, title: .localized("Modify"), showChevron: false)
                }
                .tint(Color(UIColor.tertiaryLabel))
                .padding(.trailing, 16)
                
                Divider().padding(.leading, 16)
                
                NavigationLink {
                    Form { SigningOptionsView(options: $_temporaryOptions, temporaryOptions: _optionsManager.options) }
                    .navigationTitle(.localized("Properties"))
                } label: {
                    ActionRow(icon: "slider.horizontal.3", iconColor: .indigo, title: .localized("Properties"), showChevron: true)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
    
    @ViewBuilder
    private func _infoCell<V: View>(icon: String, iconColor: Color, title: String, desc: String?, @ViewBuilder destination: () -> V) -> some View {
        NavigationLink {
            destination()
        } label: {
            InfoRow(icon: icon, iconColor: iconColor, title: title, value: desc ?? .localized("Unknown"))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func _navRow<V: View>(title: String, @ViewBuilder destination: () -> V) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Extension: Action (import)
extension SigningView {
    private func _start() {
        guard
            _selectedCert() != nil || _temporaryOptions.signingOption != .default
        else {
            UIAlertController.showAlertWithOk(
                title: .localized("No Certificate"),
                message: .localized("Please go to settings and import a valid certificate"),
                isCancel: true
            )
            return
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        _isSigning = true
        
        FR.signPackageFile(
            app,
            using: _temporaryOptions,
            icon: appIcon,
            certificate: _selectedCert()
        ) { error in
            if let error {
                let ok = UIAlertAction(title: .localized("Dismiss"), style: .cancel) { _ in
                    dismiss()
                }
                
                UIAlertController.showAlert(
                    title: "Error",
                    message: error.localizedDescription,
                    actions: [ok]
                )
            } else {
                if
                    _temporaryOptions.post_deleteAppAfterSigned,
                    !app.isSigned
                {
                    Storage.shared.deleteApp(for: app)
                }
                
                // 💡 چارەسەرە گەورەکە لێرەدایە! ناوی ئەپەکە دەگرین و لەگەڵ زەنگەکە دەینێرین بۆ HomeView
                let signedName = _temporaryOptions.appName ?? app.name ?? ""
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    NotificationCenter.default.post(name: Notification.Name("AshteMobile.installApp"), object: signedName)
                }
                
                dismiss()
            }
        }
    }
}

// MARK: - Reusable UI Components
struct SectionTitle: View {
    var title: String
    var body: some View {
        Text(title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(.primary)
            .padding(.bottom, -6)
            .padding(.leading, 8)
    }
}

struct InfoRow: View {
    var icon: String
    var iconColor: Color
    var title: String
    var value: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                iconColor.opacity(0.15)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(width: 30, height: 30)
            .cornerRadius(8)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Image(systemName: "chevron.right")
                .foregroundColor(Color(UIColor.tertiaryLabel))
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

struct ActionRow: View {
    var icon: String? = nil
    var iconColor: Color? = nil
    var title: String
    var showChevron: Bool = true
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon, let iconColor = iconColor {
                ZStack {
                    iconColor.opacity(0.15)
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(width: 30, height: 30)
                .cornerRadius(8)
            }
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .padding(.vertical, 12)
        .padding(.leading, 16)
        .padding(.trailing, showChevron ? 16 : 0)
        .contentShape(Rectangle())
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
