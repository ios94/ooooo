//
//  TabEnum.swift
//  ashtemobile
//
//  Modified for AshteMobile
//

import SwiftUI
import NimbleViews

enum TabEnum: String, CaseIterable, Hashable {
    case home
    case apps        // 💡 ١. زیادکردنی تابی نوێ بۆ بەرنامەکان
    case sources
    case library
    case settings
    case certificates
    
    var title: String {
        switch self {
        case .home:         return .localized("Home")
        case .apps:         return .localized("Apps") // 💡 ناوی تابەکە
        case .sources:      return .localized("Sources")
        case .library:      return .localized("Library")
        case .settings:     return .localized("Settings")
        case .certificates: return .localized("Certificates")
        }
    }
    
    var icon: String {
        switch self {
        case .home:         return "house.fill"
        case .apps:         return "app.badge.fill" // 💡 ئایکۆنی تابەکە
        case .sources:      return "globe.desk"
        case .library:      return "square.grid.2x2"
        case .settings:     return "gearshape.2"
        case .certificates: return "person.text.rectangle"
        }
    }
    
    @ViewBuilder
    static func view(for tab: TabEnum) -> some View {
        switch tab {
        case .home:         HomeView() 
        case .apps:         AppsView() // 💡 ٢. بەستنەوەی بە فایلی بەرنامەکانەوە
        case .sources:      SourcesView()
        case .library:      LibraryView()
        case .settings:     SettingsView()
        case .certificates: NBNavigationView(.localized("Certificates")) { CertificatesView() }
        }
    }
    
    static var defaultTabs: [TabEnum] {
        return [
            .home,
            .apps,    // 💡 ٣. دانانی لە ڕیزی خوارەوە ڕێک لە تەنیشت Home
            .sources,
            .library,
            .settings
        ]
    }
    
    static var customizableTabs: [TabEnum] {
        return [
            .certificates
        ]
    }
}
