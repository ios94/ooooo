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
        .background(AshteBackground())
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
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, AshteTheme.violet)
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
                        .fill(isSelected ? AshteTheme.primary : LinearGradient(colors: [Color.gray.opacity(0.12), Color.gray.opacity(0.12)], startPoint: .top, endPoint: .bottom))
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
                        .foregroundStyle(AshteTheme.violet)
                        .font(.title3)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.all, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: isSelected ? AshteTheme.violet.opacity(0.25) : Color.black.opacity(0.03), 
                            radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? AshteTheme.primary : LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom), lineWidth: 2.5)
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

    private func _emptyStateView() -> some View {
        AshteEmptyState(
            icon: "shield.lefthalf.filled",
            title: .localized("No Certificates"),
            message: .localized("Get started signing by importing your first certificate. Your keys will be stored securely."),
            buttonTitle: .localized("Import Now"),
            action: { _isAddingPresenting = true }
        )
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
