import SwiftUI
import NimbleViews

// MARK: - View
struct CertificatesView: View {
    @AppStorage("ashtemobile.selectedCert") private var _storedSelectedCert: Int = 0
    
    @State private var _isAddingPresenting = false
    @State private var _isSelectedInfoPresenting: CertificatePair?

    // MARK: Fetch
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var _certificates: FetchedResults<CertificatePair>
    
    private var _bindingSelectedCert: Binding<Int>?
    private var _selectedCertBinding: Binding<Int> {
        _bindingSelectedCert ?? $_storedSelectedCert
    }
    
    init(selectedCert: Binding<Int>? = nil) {
        self._bindingSelectedCert = selectedCert
    }
    
    // MARK: Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Header Info
                if !_certificates.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Active Certificates")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 5)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }

                // Grid of Certificates
                LazyVStack(spacing: 15) {
                    ForEach(Array(_certificates.enumerated()), id: \.element.uuid) { index, cert in
                        _modernCell(for: cert, at: index)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(.localized("Certificates"))
        .overlay {
            if _certificates.isEmpty {
                _emptyStateView()
            }
        }
        .toolbar {
            if _bindingSelectedCert == nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        _isAddingPresenting = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
        .sheet(item: $_isSelectedInfoPresenting) { cert in
            CertificatesInfoView(cert: cert)
        }
        .sheet(isPresented: $_isAddingPresenting) {
            CertificatesAddView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Modern UI Extension
extension CertificatesView {
    
    @ViewBuilder
    private func _modernCell(for cert: CertificatePair, at index: Int) -> some View {
        let isSelected = _selectedCertBinding.wrappedValue == index
        
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                _selectedCertBinding.wrappedValue = index
            }
        } label: {
            HStack(spacing: 16) {
                // Icon Area
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
                        .frame(width: 45, height: 45)
                    
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(isSelected ? .white : .secondary)
                        .font(.system(size: 20))
                }
                
                // Content
                CertificatesCellView(cert: cert)
                    .layoutPriority(1)
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.all, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: isSelected ? Color.accentColor.opacity(0.15) : Color.black.opacity(0.03), 
                            radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .contextMenu {
                _contextActions(for: cert)
                if cert.isDefault != true {
                    Divider()
                    _actions(for: cert)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }

    @ViewBuilder
    private func _emptyStateView() -> some View {
        if #available(iOS 17, *) {
            ContentUnavailableView {
                Label(.localized("No Certificates"), systemImage: "shield.slash.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.accentColor)
            } description: {
                Text(.localized("Get started signing by importing your first certificate. Your keys will be stored securely."))
            } actions: {
                Button {
                    _isAddingPresenting = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text(.localized("Import Now"))
                    }
                    .fontWeight(.bold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private func _actions(for cert: CertificatePair) -> some View {
        Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
            Storage.shared.deleteCertificate(for: cert)
        }
    }
    
    @ViewBuilder
    private func _contextActions(for cert: CertificatePair) -> some View {
        Button(.localized("Get Info"), systemImage: "info.circle") {
            _isSelectedInfoPresenting = cert
        }
        Divider()
        Button(.localized("Check Revokage"), systemImage: "person.text.rectangle") {
            Storage.shared.revokagedCertificate(for: cert)
        }
    }
}
