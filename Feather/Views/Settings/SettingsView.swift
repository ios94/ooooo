import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

// MARK: - View
struct SettingsView: View {
    @AppStorage("ashtemobile.selectedCert") private var _storedSelectedCert: Int = 0
    @State private var _currentIcon: String? = UIApplication.shared.alternateIconName
    
    // MARK: Fetch
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var _certificates: FetchedResults<CertificatePair>
    
    private var selectedCertificate: CertificatePair? {
        guard
            _storedSelectedCert >= 0,
            _storedSelectedCert < _certificates.count
        else {
            return nil
        }
        return _certificates[_storedSelectedCert]
    }

    // MARK: Body
    var body: some View {
        NBNavigationView(.localized("Settings")) {
            Form {
                // MARK: - Modern Header (Logo & Social)
                Section {
                    VStack(spacing: 16) {
                        // Profile Image with Modern Shadow
                        AsyncImage(url: URL(string: "https://ashtemobile.site/a.png")) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .shadow(color: AshteTheme.pink.opacity(0.35), radius: 14, x: 0, y: 6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .strokeBorder(AshteTheme.candy, lineWidth: 3)
                                )
                        } placeholder: {
                            ProgressView()
                                .frame(width: 90, height: 90)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                        .padding(.top, 5)
                        
                        Text("AshteMobile")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundStyle(AshteTheme.candy)
                        
                        HStack(spacing: 15) {
                            // Telegram Button
                            Button(action: {
                                if let url = URL(string: "https://t.me/ashtemobile") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "paperplane.fill")
                                    Text("Telegram")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(width: 130, height: 40)
                                .background(AshteTheme.ocean)
                                .clipShape(Capsule())
                                .shadow(color: AshteTheme.cyan.opacity(0.4), radius: 6, x: 0, y: 3)
                            }
                            
                            // Instagram Button
                            Button(action: {
                                if let url = URL(string: "https://www.instagram.com/ashtemobile") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "camera.fill")
                                    Text("Instagram")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(width: 130, height: 40)
                                .background(
                                    AshteTheme.candy
                                )
                                .clipShape(Capsule())
                                .shadow(color: AshteTheme.pink.opacity(0.4), radius: 6, x: 0, y: 3)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .listRowBackground(Color.clear)

                // MARK: - About & Appearance
                NBSection(.localized("About")) {
                    NavigationLink(destination: AboutView()) {
                        HStack(spacing: 15) {
                            FRAppIconView(size: 32)
                                .frame(width: 32, height: 32)
                                .cornerRadius(8)
                            
                            Text("AshteMobile")
                                .font(.system(size: 17))
                        }
                    }
                    NavigationLink(destination: AppearanceView()) {
                        settingRow(title: .localized("Appearance"), icon: "paintbrush.fill", gradient: AshteTheme.primary)
                    }
                    NavigationLink(destination: AppIconView(currentIcon: $_currentIcon)) {
                        settingRow(title: .localized("App Icon"), icon: "app.badge.fill", gradient: AshteTheme.sunset)
                    }
                }
                
                // MARK: - Certificates
                NBSection(.localized("Certificates")) {
                    if let cert = selectedCertificate {
                        CertificatesCellView(cert: cert)
                            .padding(.vertical, 4)
                    } else {
                        Text(.localized("No Certificate"))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    NavigationLink(destination: CertificatesView()) {
                        settingRow(title: .localized("Manage Certificates"), icon: "checkmark.seal.fill", gradient: AshteTheme.fresh)
                    }
                } footer: {
                    Text(.localized("Add and manage certificates used for signing applications."))
                }
                
                // MARK: - Features
                NBSection(.localized("Features")) {
                    NavigationLink(destination: ConfigurationView()) {
                        settingRow(title: .localized("Signing Options"), icon: "signature", gradient: AshteTheme.primary)
                    }
                    NavigationLink(destination: ArchiveView()) {
                        settingRow(title: .localized("Archive & Compression"), icon: "archivebox.fill", gradient: AshteTheme.sunset)
                    }
                    NavigationLink(destination: InstallationView()) {
                        settingRow(title: .localized("Installation"), icon: "arrow.down.circle.fill", gradient: AshteTheme.ocean)
                    }
                } footer: {
                    Text(.localized("Configure the apps way of installing, its zip compression levels, and custom modifications to apps."))
                }
                
                // MARK: - Reset
                Section {
                    NavigationLink(destination: ResetView()) {
                        settingRow(title: .localized("Reset All Data"), icon: "trash.fill", gradient: LinearGradient(colors: [.red, AshteTheme.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                }
            }
            .ashteScreenBackground()
        }
    }
    
    // MARK: - Modern Setting Row Helper
    @ViewBuilder
    private func settingRow(title: String, icon: String, gradient: LinearGradient) -> some View {
        HStack(spacing: 15) {
            AshteIconBadge(systemName: icon, gradient: gradient, size: 32)
            
            Text(title)
                .font(.system(size: 17, weight: .medium, design: .rounded))
        }
    }
}
