//
//  LibraryView.swift
//  AshteMobile
//
//  Created by samara on 10.04.2025.
//  Modernized UI Design & Fixed Double Install Prompt
//

import SwiftUI
import CoreData
import NimbleViews

// MARK: - View
struct LibraryView: View {
    @StateObject var downloadManager = DownloadManager.shared
    
    @State private var _selectedInfoAppPresenting: AnyApp?
    @State private var _selectedSigningAppPresenting: AnyApp?
    @State private var _selectedInstallAppPresenting: AnyApp?
    @State private var _isImportingPresenting = false
    @State private var _isDownloadingPresenting = false
    @State private var _alertDownloadString: String = "" 
    
    @State private var _showModernImportSheet = false
    
    // MARK: Selection State
    @State private var _selectedAppUUIDs: Set<String> = []
    @State private var _editMode: EditMode = .inactive
    
    @State private var _searchText = ""
    @State private var _selectedScope: Scope = .all
    
    @Namespace private var _namespace
    
    // MARK: Filters
    private func filteredAndSortedApps<T>(from apps: FetchedResults<T>) -> [T] where T: NSManagedObject {
        apps.filter {
            _searchText.isEmpty ||
            (($0.value(forKey: "name") as? String)?.localizedCaseInsensitiveContains(_searchText) ?? false)
        }
    }
    
    private var _filteredSignedApps: [Signed] {
        filteredAndSortedApps(from: _signedApps)
    }
    
    private var _filteredImportedApps: [Imported] {
        filteredAndSortedApps(from: _importedApps)
    }
    
    // MARK: Fetch
    @FetchRequest(
        entity: Signed.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
        animation: .snappy
    ) private var _signedApps: FetchedResults<Signed>
    
    @FetchRequest(
        entity: Imported.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)],
        animation: .snappy
    ) private var _importedApps: FetchedResults<Imported>
    
    // MARK: Body
    var body: some View {
        NBNavigationView(.localized("Library")) {
            List {
                if !_editMode.isEditing && _searchText.isEmpty {
                    Section {
                        HStack(spacing: 15) {
                            LibraryStatCard(
                                title: "Signed",
                                count: _signedApps.count,
                                icon: "checkmark.seal.fill",
                                gradient: AshteTheme.fresh,
                                color: AshteTheme.mint
                            )
                            
                            LibraryStatCard(
                                title: "Imported",
                                count: _importedApps.count,
                                icon: "tray.and.arrow.down.fill",
                                gradient: AshteTheme.ocean,
                                color: AshteTheme.cyan
                            )
                        }
                        .padding(.vertical, 5)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                }
                
                if !_filteredSignedApps.isEmpty, _selectedScope == .all || _selectedScope == .signed {
                    NBSection(.localized("Signed Apps"), secondary: _filteredSignedApps.count.description) {
                        ForEach(_filteredSignedApps, id: \.uuid) { app in
                            LibraryCellView(
                                app: app,
                                selectedInfoAppPresenting: $_selectedInfoAppPresenting,
                                selectedSigningAppPresenting: $_selectedSigningAppPresenting,
                                selectedInstallAppPresenting: $_selectedInstallAppPresenting,
                                selectedAppUUIDs: $_selectedAppUUIDs
                            )
                            .compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
                        }
                    }
                }
                
                if !_filteredImportedApps.isEmpty, _selectedScope == .all || _selectedScope == .imported {
                    NBSection(.localized("Imported Apps"), secondary: _filteredImportedApps.count.description) {
                        ForEach(_filteredImportedApps, id: \.uuid) { app in
                            LibraryCellView(
                                app: app,
                                selectedInfoAppPresenting: $_selectedInfoAppPresenting,
                                selectedSigningAppPresenting: $_selectedSigningAppPresenting,
                                selectedInstallAppPresenting: $_selectedInstallAppPresenting,
                                selectedAppUUIDs: $_selectedAppUUIDs
                            )
                            .compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .ashteScreenBackground()
            .searchable(text: $_searchText, placement: .platform())
            .compatSearchScopes($_selectedScope) {
                ForEach(Scope.allCases, id: \.displayName) { scope in
                    Text(scope.displayName).tag(scope)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .overlay {
                if _filteredSignedApps.isEmpty && _filteredImportedApps.isEmpty {
                    AshteEmptyState(
                        icon: "square.stack.3d.up.badge.a.fill",
                        title: .localized("Your Library is Empty"),
                        message: .localized("Get started by importing your first IPA file. It will appear here once processed."),
                        buttonTitle: .localized("Import App"),
                        action: { _showModernImportSheet = true }
                    )
                    .background(AshteBackground())
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                
                if _editMode.isEditing {
                    NBToolbarButton(
                        .localized("Delete"),
                        systemImage: "trash",
                        isDisabled: _selectedAppUUIDs.isEmpty
                    ) {
                        _bulkDeleteSelectedApps()
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            _showModernImportSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, AshteTheme.violet)
                        }
                    }
                }
            }
            .environment(\.editMode, $_editMode)
            .sheet(item: $_selectedInfoAppPresenting) { app in
                LibraryInfoView(app: app.base)
            }
            .sheet(item: $_selectedInstallAppPresenting) { app in
                InstallPreviewView(app: app.base, isSharing: app.archive)
                    .presentationDetents([.height(200)])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(item: $_selectedSigningAppPresenting) { app in
                SigningView(app: app.base)
                    .compatNavigationTransition(id: app.base.uuid ?? "", ns: _namespace)
            }
            .sheet(isPresented: $_showModernImportSheet) {
                VStack(spacing: 20) {
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 10)
                    
                    Text(.localized("Import App"))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            _showModernImportSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                _isDownloadingPresenting = true
                            }
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(width: 52, height: 52)
                                    Image(systemName: "globe")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(.localized("Import from URL"))
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text(.localized("Download and install directly from a web link."))
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray.opacity(0.4))
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .padding(16)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            _showModernImportSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                _isImportingPresenting = true
                            }
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.purple.opacity(0.15))
                                        .frame(width: 52, height: 52)
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(.purple)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(.localized("Import from Files"))
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text(.localized("Browse your device to install local IPA files."))
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray.opacity(0.4))
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .padding(16)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .presentationDetents([.height(290)])
                .presentationDragIndicator(.hidden)
                .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            }
            .sheet(isPresented: $_isImportingPresenting) {
                FileImporterRepresentableView(
                    allowedContentTypes:  [.ipa, .tipa],
                    allowsMultipleSelection: true,
                    onDocumentsPicked: { urls in
                        guard !urls.isEmpty else { return }
                        
                        for url in urls {
                            let id = "AshteMobileManualDownload_\(UUID().uuidString)"
                            let dl = downloadManager.startArchive(from: url, id: id)
                            try? downloadManager.handlePachageFile(url: url, dl: dl)
                        }
                    }
                )
                .ignoresSafeArea()
            }
            .alert(.localized("Import from URL"), isPresented: $_isDownloadingPresenting) {
                TextField(.localized("URL"), text: $_alertDownloadString)
                    .textInputAutocapitalization(.never)
                Button(.localized("Cancel"), role: .cancel) {
                    _alertDownloadString = ""
                }
                Button(.localized("OK")) {
                    if let url = URL(string: _alertDownloadString) {
                        _ = downloadManager.startDownload(from: url, id: "AshteMobileManualDownload_\(UUID().uuidString)")
                    }
                }
            }
            // 💡 قفڵی گشتی بە UserDefaults
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AshteMobile.installApp"))) { _ in
                let now = Date().timeIntervalSince1970
                let lastTime = UserDefaults.standard.double(forKey: "AshteMobile.GlobalInstallLock")
                
                if now - lastTime > 2.0 {
                    UserDefaults.standard.set(now, forKey: "AshteMobile.GlobalInstallLock")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let latest = _signedApps.first {
                            _selectedInstallAppPresenting = AnyApp(base: latest)
                        }
                    }
                }
            }
            .onChange(of: _editMode) { mode in
                if mode == .inactive {
                    _selectedAppUUIDs.removeAll()
                }
            }
        }
    }
}

// MARK: - Extension: Custom Components
extension LibraryView {
    struct LibraryStatCard: View {
        let title: String
        let count: Int
        let icon: String
        var gradient: LinearGradient = AshteTheme.primary
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(.white.opacity(0.25)))
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text(.localized(title))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding()
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: color.opacity(0.4), radius: 10, x: 0, y: 6)
        }
    }
}

// MARK: - Extension: Bulk Delete
extension LibraryView {
    private func _bulkDeleteSelectedApps() {
        let selectedApps = _getAllApps().filter { app in
            guard let uuid = app.uuid else { return false }
            return _selectedAppUUIDs.contains(uuid)
        }
        
        for app in selectedApps {
            Storage.shared.deleteApp(for: app)
        }
        
        _selectedAppUUIDs.removeAll()
    }
    
    private func _getAllApps() -> [AppInfoPresentable] {
        var allApps: [AppInfoPresentable] = []
        
        if _selectedScope == .all || _selectedScope == .signed {
            allApps.append(contentsOf: _filteredSignedApps)
        }
        
        if _selectedScope == .all || _selectedScope == .imported {
            allApps.append(contentsOf: _filteredImportedApps)
        }
        
        return allApps
    }
}

// MARK: - Extension: Sort Scope
extension LibraryView {
    enum Scope: CaseIterable {
        case all
        case signed
        case imported
        
        var displayName: String {
            switch self {
            case .all: return .localized("All")
            case .signed: return .localized("Signed")
            case .imported: return .localized("Imported")
            }
        }
    }
}
