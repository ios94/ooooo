//
//  SourceAppsTableView.swift
//  AshteMobile
//
//  Created by samara on 3.05.2025.
//

import SwiftUI
import AltSourceKit

struct SourceAppsTableRepresentableView: UIViewRepresentable {
    var sources: [ASRepository]
    @Binding var searchText: String
    @Binding var sortOption: SourceAppsView.SortOption
    @Binding var sortAscending: Bool
    @Binding var selectedCategory: String
    var onSelect: (SourceAppsView.SourceAppRoute) -> Void
    
    func makeUIView(context: Context) -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.backgroundColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AppCell")
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "SectionHeader")
        
        if #available(iOS 17, *) {
            tableView.allowsSelection = true
        } else {
            tableView.allowsSelection = false
        }
        
        if
            let firstSource = sources.first,
            sources.count == 1,
            let news = firstSource.news,
            !news.isEmpty
        {
            let header = UIHostingController(rootView: SourceNewsView(news: news))
            header.view.translatesAutoresizingMaskIntoConstraints = true
            header.view.backgroundColor = .clear
            let fixedHeight: CGFloat = 161
            let width = tableView.bounds.width
            header.view.frame = CGRect(origin: .zero, size: CGSize(width: width, height: fixedHeight))

            DispatchQueue.main.async {
                tableView.tableHeaderView = header.view
            }
        }
        
        tableView.alpha = 0
        UIView.transition(with: tableView, duration: 0.5, options: [.transitionCrossDissolve], animations: {
            tableView.alpha = 1
        }, completion: nil)
        
        return tableView
    }
    
    func updateUIView(_ tableView: UITableView, context: Context) {
        context.coordinator.uiTableView = tableView
        
        let sourcesChanged = context.coordinator.sources != sources
        let searchChanged = context.coordinator.searchText != searchText
        let sortOptionChanged = context.coordinator.sortOption != sortOption
        let sortDirectionChanged = context.coordinator.sortAscending != sortAscending
        let categoryChanged = context.coordinator.selectedCategory != selectedCategory
        
        context.coordinator.sources = sources
        context.coordinator.searchText = searchText
        context.coordinator.sortOption = sortOption
        context.coordinator.sortAscending = sortAscending
        context.coordinator.selectedCategory = selectedCategory
        
        if sourcesChanged || searchChanged || sortOptionChanged || sortDirectionChanged || categoryChanged {
            context.coordinator.invalidateCache()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            sources: sources,
            searchText: searchText,
            sortOption: sortOption,
            sortAscending: sortAscending,
            selectedCategory: selectedCategory,
            onSelect: onSelect
        )
    }
}

extension SourceAppsTableRepresentableView {
    class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate {
        var sources: [ASRepository]
        var searchText: String
        var sortOption: SourceAppsView.SortOption
        var sortAscending: Bool
        var selectedCategory: String
        let onSelect: (SourceAppsView.SourceAppRoute) -> Void
        
        private var _groupedAppsByNameFirstLetter: [String: [(source: ASRepository, app: ASRepository.App)]] = [:]
        private var _groupedAppsByDate: [String: [(source: ASRepository, app: ASRepository.App)]] = [:]
        private var _sortedSectionTitles: [String] = []
        
        private var _cachedSortedApps: [(source: ASRepository, app: ASRepository.App)] = []
        weak var uiTableView: UITableView?
        
        private var _allAppsWithSource: [(source: ASRepository, app: ASRepository.App)] {
            sources.flatMap { source in source.apps.map { (source: source, app: $0) } }
        }
        
        private var _sortedApps: [(source: ASRepository, app: ASRepository.App)] {
            if !_cachedSortedApps.isEmpty {
                return _cachedSortedApps
            }
            _cachedSortedApps = _calculateSortedApps()
            return _cachedSortedApps
        }
        
        init(
            sources: [ASRepository],
            searchText: String,
            sortOption: SourceAppsView.SortOption,
            sortAscending: Bool,
            selectedCategory: String,
            onSelect: @escaping (SourceAppsView.SourceAppRoute) -> Void
        ) {
            self.sources = sources
            self.searchText = searchText
            self.sortOption = sortOption
            self.sortAscending = sortAscending
            self.selectedCategory = selectedCategory
            self.onSelect = onSelect
            super.init()
            
            if sortOption != .default {
                invalidateCache()
            }
        }
        
        private func _calculateSortedApps() -> [(source: ASRepository, app: ASRepository.App)] {
            let filtered = _allAppsWithSource.filter { appTuple in
                let matchesSearch = searchText.isEmpty ||
                (appTuple.app.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (appTuple.app.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (appTuple.app.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (appTuple.app.localizedDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
                
                var matchesCategory = true
                if selectedCategory != "All" {
                    // بەکارهێنانی category بەپێی فایلی JSONەکەت
                    let categoryString = appTuple.app.category?.lowercased() ?? ""
                    let isGame = categoryString.contains("game")
                    
                    if selectedCategory == "Games" {
                        matchesCategory = isGame
                    } else if selectedCategory == "Apps" {
                        matchesCategory = !isGame
                    }
                }
                
                return matchesSearch && matchesCategory
            }
            
            switch sortOption {
            case .default:
                _groupedAppsByDate = [:]
                _groupedAppsByNameFirstLetter = [:]
                _sortedSectionTitles = []
                return sortAscending ? filtered : filtered.reversed()
            case .date:
                let sorted = filtered.sorted {
                    let d1 = $0.app.currentDate?.date ?? .distantPast
                    let d2 = $1.app.currentDate?.date ?? .distantPast
                    return sortAscending ? (d1 < d2) : (d1 > d2)
                }
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d, yyyy"
                let grouped = Dictionary(grouping: sorted) {
                    $0.app.currentDate?.date.stripTime() ?? .distantPast
                }
                let sortedDates = grouped.keys.sorted(by: { sortAscending ? $0 > $1 : $0 < $1 })
                _groupedAppsByDate = grouped.reduce(into: [:]) { result, pair in
                    let key = formatter.string(from: pair.key)
                    result[key] = pair.value
                }
                _sortedSectionTitles = sortedDates.map { formatter.string(from: $0) }
                return sorted
            case .name:
                let sorted = filtered.sorted {
                    let n1 = $0.app.name ?? ""
                    let n2 = $1.app.name ?? ""
                    let comparison = n1.localizedCaseInsensitiveCompare(n2) == .orderedAscending
                    return sortAscending ? comparison : !comparison
                }
                // دیاریکردنی جۆری دروست بۆ ڕێگریکردن لە هەڵەی Ambiguous Type
                _groupedAppsByNameFirstLetter = Dictionary(grouping: sorted) { (entry: (source: ASRepository, app: ASRepository.App)) -> String in
                    let first = entry.app.name?.trimmingCharacters(in: .whitespacesAndNewlines).first?.uppercased() ?? "#"
                    return first.range(of: "[A-Z]", options: .regularExpression) != nil ? first : "#"
                }
                _sortedSectionTitles = _groupedAppsByNameFirstLetter.keys.sorted(by: {
                    if $0 == "#" { return false }
                    if $1 == "#" { return true }
                    return sortAscending ? $0 < $1 : $0 > $1
                })
                return sorted
            }
        }
        
        func invalidateCache() {
            _cachedSortedApps = _calculateSortedApps()
            if let tableView = uiTableView {
                UIView.transition(with: tableView, duration: 0.3, options: [.transitionCrossDissolve], animations: {
                    tableView.reloadData()
                })
            }
        }
        
        func numberOfSections(in tableView: UITableView) -> Int {
            switch sortOption {
            case .default: 1
            case .name, .date: _sortedSectionTitles.count
            }
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            switch sortOption {
            case .default: _sortedApps.count
            case .name: _groupedAppsByNameFirstLetter[_sortedSectionTitles[section]]?.count ?? 0
            case .date: _groupedAppsByDate[_sortedSectionTitles[section]]?.count ?? 0
            }
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AppCell", for: indexPath)
            cell.backgroundColor = .clear
            let entry: (source: ASRepository, app: ASRepository.App)
            switch sortOption {
            case .default: entry = _sortedApps[indexPath.row]
            case .name: entry = _groupedAppsByNameFirstLetter[_sortedSectionTitles[indexPath.section]]?[indexPath.row] ?? _sortedApps[indexPath.row]
            case .date: entry = _groupedAppsByDate[_sortedSectionTitles[indexPath.section]]?[indexPath.row] ?? _sortedApps[indexPath.row]
            }

            cell.contentConfiguration = UIHostingConfiguration {
                SourceAppsCellView(source: entry.source, app: entry.app)
            }
            return cell
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            if #available(iOS 17, *) {
                tableView.deselectRow(at: indexPath, animated: true)
                let entry: (source: ASRepository, app: ASRepository.App)
                switch sortOption {
                case .default: entry = _sortedApps[indexPath.row]
                case .name: entry = _groupedAppsByNameFirstLetter[_sortedSectionTitles[indexPath.section]]?[indexPath.row] ?? _sortedApps[indexPath.row]
                case .date: entry = _groupedAppsByDate[_sortedSectionTitles[indexPath.section]]?[indexPath.row] ?? _sortedApps[indexPath.row]
                }
                onSelect(SourceAppsView.SourceAppRoute(source: entry.source, app: entry.app))
            }
        }
        
        func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeader")
            let title: String
            switch sortOption {
            case .default: title = .localized("%lld Apps", arguments: _sortedApps.count)
            case .name, .date: title = _sortedSectionTitles[section]
            }
            headerView?.contentConfiguration = UIHostingConfiguration {
                HStack {
                    Text(verbatim: title)
                    Spacer()
                }
                .font(.headline)
                .padding(.vertical, 2)
            }
            return headerView
        }
        
        func sectionIndexTitles(for tableView: UITableView) -> [String]? {
            sortOption == .name ? _sortedSectionTitles : nil
        }
        
        func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
            _sortedSectionTitles.firstIndex(of: title) ?? 0
        }
    }
}
