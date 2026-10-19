//
//  SourcesView.swift
//  AshteMobile
//
//  Created by samara on 1.05.2025.
//

import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews

struct SourcesView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #if !NIGHTLY && !DEBUG
    @AppStorage("AshteMobile.shouldStar") private var _shouldStar: Int = 0
    #endif
    @StateObject var viewModel = SourcesViewModel.shared
    @State private var _isAddingPresenting = false
    @State private var _addingSourceLoading = false
    @State private var _searchText = ""
    
    private var _filteredSources: [AltSource] {
        _sources.filter { source in
            let urlString = source.sourceURL?.absoluteString ?? ""
            // ڕێگریکردن لە نیشاندانی سۆرسی گیتھەبی ئاپس لە تابی Sources
            if urlString.contains("ashtemobile94.json") {
                return false
            }
            return _searchText.isEmpty || (source.name?.localizedCaseInsensitiveContains(_searchText) ?? false)
        }
    }
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var _sources: FetchedResults<AltSource>
    
    var body: some View {
        NBNavigationView(.localized("Sources")) {
            List {
                if !_filteredSources.isEmpty {
                    Section {
                        NavigationLink {
                            SourceAppsView(object: Array(_sources), viewModel: viewModel)
                        } label: {
                            HStack(spacing: 16) {
                                AshteIconBadge(
                                    systemName: "square.grid.3x3.fill",
                                    gradient: AshteTheme.candy,
                                    size: 56
                                )
                                .shadow(color: AshteTheme.pink.opacity(0.35), radius: 8, x: 0, y: 4)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(.localized("All Repositories"))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(.localized("Explore all apps from every source"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(AshteTheme.primary.opacity(0.5), lineWidth: 1.5)
                            )
                    )
                    
                    NBSection(
                        .localized("Repositories"),
                        secondary: _filteredSources.count.description
                    ) {
                        ForEach(_filteredSources) { source in
                            NavigationLink {
                                SourceAppsView(object: [source], viewModel: viewModel)
                            } label: {
                                SourcesCellView(source: source)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .ashteScreenBackground()
            .searchable(text: $_searchText, placement: .platform())
            .overlay {
                if _filteredSources.isEmpty {
                    _emptyStateView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        _isAddingPresenting = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, AshteTheme.violet)
                    }
                    .disabled(_addingSourceLoading)
                }
            }
            .refreshable {
                await viewModel.fetchSources(_sources, refresh: true)
            }
            .sheet(isPresented: $_isAddingPresenting) {
                SourcesAddView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .task(id: Array(_sources)) {
            await viewModel.fetchSources(_sources)
        }
        #if !NIGHTLY && !DEBUG
        .onAppear {
            _handleAppRating()
        }
        #endif
    }
}

extension SourcesView {
    @ViewBuilder
    private func _emptyStateView() -> some View {
        AshteEmptyState(
            icon: "globe.asia.australia.fill",
            title: .localized("No Repositories"),
            message: .localized("Stay updated by adding your favorite app repositories here."),
            buttonTitle: .localized("Add First Source"),
            action: { _isAddingPresenting = true }
        )
    }
    
    #if !NIGHTLY && !DEBUG
    private func _handleAppRating() {
        guard _shouldStar < 6 else { return }; _shouldStar += 1
        guard _shouldStar == 6 else { return }
        
        let telegram = UIAlertAction(title: "Telegram", style: .default) { _ in
            UIApplication.open("https://t.me/ashtemobile")
        }
        
        let cancel = UIAlertAction(title: .localized("Dismiss"), style: .cancel)
        
        UIAlertController.showAlert(
            title: "Enjoying AshteMobile?",
            message: "Join our Telegram channel for more updates and support!",
            actions: [telegram, cancel]
        )
    }
    #endif
}
