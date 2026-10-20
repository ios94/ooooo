//
//  SourcesAddView.swift
//  AshteMobile
//
//  Created by samara on 10.04.2025.
//

import SwiftUI
import NimbleViews
import AltSourceKit
import NimbleJSON
import OSLog
import UIKit.UIImpactFeedbackGenerator

// MARK: - View
struct SourcesAddView: View {
    typealias RepositoryDataHandler = Result<ASRepository, Error>
    @Environment(\.dismiss) var dismiss

    private let _dataService = NBFetchService()
    
    @State private var _filteredRecommendedSourcesData: [(url: URL, data: ASRepository)] = []
    
    private func _refreshFilteredRecommendedSourcesData() {
        let filtered = recommendedSourcesData
            .filter { (url, data) in
                let id = data.id ?? url.absoluteString
                return !Storage.shared.sourceExists(id)
            }
            .sorted { lhs, rhs in
                let lhsName = lhs.data.name ?? ""
                let rhsName = rhs.data.name ?? ""
                return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
            }
        _filteredRecommendedSourcesData = filtered
    }
    
    @State var recommendedSourcesData: [(url: URL, data: ASRepository)] = []
    let recommendedSources: [URL] = [
        "https://ashtemobile.site/Ashtemobile.json"
    ].map { URL(string: $0)! }
    
    @State private var _isImporting = false
    @State private var _sourceURL = ""
    
    // MARK: Body
    var body: some View {
        NBNavigationView(.localized("Add Source"), displayMode: .inline) {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Input Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(.localized("Source URL"))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                        
                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "link")
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                
                                TextField(.localized("Enter Source URL"), text: $_sourceURL)
                                    .keyboardType(.URL)
                                    .textInputAutocapitalization(.never)
                                    .font(.system(size: 16))
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        Text(.localized("The only supported repositories are AltStore repositories."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                    }
                    .padding(.horizontal)

                    // MARK: - Actions (Import/Export)
                    HStack(spacing: 12) {
                        _actionButton(title: .localized("Import"), icon: "square.and.arrow.down", color: .blue) {
                            _isImporting = true
                            _fetchImportedRepositories(UIPasteboard.general.string) {
                                dismiss()
                            }
                        }
                        
                        _actionButton(title: .localized("Export"), icon: "doc.on.doc", color: .orange) {
                            _exportSources()
                        }
                    }
                    .padding(.horizontal)

                    // MARK: - Featured Sources
                    if !_filteredRecommendedSourcesData.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(.localized("Featured Repository"))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            
                            ForEach(_filteredRecommendedSourcesData, id: \.url) { (url, source) in
                                _modernFeaturedCard(url: url, source: source)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Footer Links
                    VStack(spacing: 8) {
                        Link(String.localized("Telegram..."), destination: URL(string: "https://t.me/ashtemobile")!)
                            .font(.footnote)
                        
                        Text(.localized("Want to be featured? Contact us on Telegram."))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 10)
                }
                .padding(.top, 20)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) { dismiss() }
                }
                
                if !_isImporting {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(.localized("Save")) {
                            FR.handleSource(_sourceURL) { dismiss() }
                        }
                        .fontWeight(.bold)
                        .disabled(_sourceURL.isEmpty)
                    }
                } else {
                    ToolbarItem(placement: .confirmationAction) {
                        ProgressView()
                    }
                }
            }
            .task {
                await _fetchRecommendedRepositories()
            }
        }
    }
}

// MARK: - Extension: Modern UI Helpers
extension SourcesAddView {
    
    @ViewBuilder
    private func _actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func _modernFeaturedCard(url: URL, source: ASRepository) -> some View {
        HStack(spacing: 15) {
            // Icon
            AsyncImage(url: source.currentIconURL) { image in
                image.resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } placeholder: {
                Color.gray.opacity(0.1)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name ?? "Unknown")
                    .font(.system(size: 16, weight: .bold))
                Text(url.host ?? url.absoluteString)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button {
                Storage.shared.addSource(url, repository: source) { _ in
                    _refreshFilteredRecommendedSourcesData()
                }
            } label: {
                Text(.localized("Add"))
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    private func _exportSources() {
        let sources = Storage.shared.getSources()
        guard !sources.isEmpty else {
            UIAlertController.showAlertWithOk(title: .localized("Error"), message: .localized("No sources to export"))
            return
        }
        UIPasteboard.general.string = sources.map { $0.sourceURL!.absoluteString }.joined(separator: "\n")
        UIAlertController.showAlertWithOk(title: .localized("Success"), message: .localized("Sources copied to clipboard")) {
            dismiss()
        }
    }
}

// MARK: - Logic 
extension SourcesAddView {
    private func _fetchRecommendedRepositories() async {
        let fetched = await _concurrentFetchRepositories(from: recommendedSources)
        await MainActor.run {
            recommendedSourcesData = fetched
            _refreshFilteredRecommendedSourcesData()
        }
    }
    
    private func _fetchImportedRepositories(_ code: String?, competion: @escaping () -> Void) {
        guard let code else { return }
        let handler = ASDeobfuscator(with: code)
        let repoUrls = handler.decode().compactMap { URL(string: $0) }
        guard !repoUrls.isEmpty else { return }
        Task {
            let fetched = await _concurrentFetchRepositories(from: repoUrls)
            let dict = Dictionary(fetched, uniquingKeysWith: { first, _ in first })
            await MainActor.run {
                Storage.shared.addSources(repos: dict) { _ in competion() }
            }
        }
    }
    
    private func _concurrentFetchRepositories(from urls: [URL]) async -> [(url: URL, data: ASRepository)] {
        var results: [(url: URL, data: ASRepository)] = []
        let dataService = _dataService
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    await withCheckedContinuation { continuation in
                        // 💡 لێرەدا <ASRepository> لابرا بۆ ڕێگریکردن لە هەڵەی Ambiguous Type
                        dataService.fetch(from: url) { (result: RepositoryDataHandler) in
                            switch result {
                            case .success(let repo):
                                Task { @MainActor in results.append((url: url, data: repo)) }
                            case .failure(let error):
                                Logger.misc.error("Failed to fetch \(url): \(error.localizedDescription)")
                            }
                            continuation.resume()
                        }
                    }
                }
            }
            await group.waitForAll()
        }
        return results
    }
}
