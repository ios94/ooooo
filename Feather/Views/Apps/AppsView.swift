//
//  AppsView.swift
//  AshteMobile
//
//  Created by samara on 11.10.2026.
//

import SwiftUI
import AltSourceKit
import NimbleViews

struct AppsView: View {
    @StateObject var viewModel = SourcesViewModel.shared
    @Environment(\.managedObjectContext) private var context
    
    @AppStorage("AshteMobile.sortOptionRawValue") private var _sortOptionRawValue: String = "default"
    @AppStorage("AshteMobile.sortAscending") private var _sortAscending: Bool = true
    
    @State private var _searchText = ""
    @State private var _selectedCategory = "All"
    @State private var _selectedRoute: SourceAppsView.SourceAppRoute?
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        predicate: NSPredicate(format: "sourceURL.absoluteString CONTAINS %@", "ashtemobile94.json"),
        animation: .snappy
    ) private var _sources: FetchedResults<AltSource>
    
    var body: some View {
        NBNavigationView(.localized("Apps")) {
            VStack(spacing: 0) {
                Picker("Categories", selection: $_selectedCategory) {
                    Text("All").tag("All")
                    Text("Games").tag("Games")
                    Text("Apps").tag("Apps")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .padding(.top, 4)
                
                if let firstSource = _sources.first, let repo = viewModel.sources[firstSource] {
                    SourceAppsTableRepresentableView(
                        sources: [repo],
                        searchText: $_searchText,
                        sortOption: .constant(SourceAppsView.SortOption(rawValue: _sortOptionRawValue) ?? .default),
                        sortAscending: $_sortAscending,
                        selectedCategory: $_selectedCategory, // 💡 ئەم دێڕە زیاد کرا بۆ بەستنەوەی تابەکان
                        onSelect: { self._selectedRoute = $0 }
                    )
                    .ignoresSafeArea()
                } else {
                    VStack {
                        Spacer()
                        ProgressView("Loading Apps...")
                        Spacer()
                    }
                }
            }
            .searchable(text: $_searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Apps")
            .refreshable {
                await viewModel.fetchSources(_sources, refresh: true)
            }
            .navigationDestinationIfAvailable(item: $_selectedRoute) { route in
                SourceAppsDetailView(source: route.source, app: route.app)
            }
        }
        .task(id: Array(_sources)) {
            if _sources.isEmpty {
                _addDefaultSource()
            }
            await viewModel.fetchSources(_sources)
        }
    }
    
    private func _addDefaultSource() {
        let defaultURLString = "https://github.com/ios94/ashtejson/raw/refs/heads/main/ashtemobile94.json"
        guard let url = URL(string: defaultURLString) else { return }
        
        let newSource = AltSource(context: context)
        newSource.name = "Ashtemobile Apps"
        newSource.sourceURL = url
        try? context.save()
    }
}
