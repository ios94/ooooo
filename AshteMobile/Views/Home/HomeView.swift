//
//  HomeView.swift
//  AshteMobile
//
//  Created for AshteMobile
//  100% Clean Pro UI with Notification Name Fix ⚡️
//

import SwiftUI
import NimbleViews
import AltSourceKit
import Foundation
import UIKit
import Combine
import CoreData

// MARK: - Global Lock
class HomeGlobalLock {
    static var isSigningActive = false
}

// MARK: - Tab Categories
enum HomeCategoryTab: String, CaseIterable, Identifiable {
    case all = "All"
    case apps = "Apps"
    case games = "Games"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .all: return "All"
        case .apps: return "Apps"
        case .games: return "Games"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "sparkles"
        case .apps: return "square.grid.2x2.fill"
        case .games: return "gamecontroller.fill"
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .all: return AshteTheme.primary
        case .apps: return AshteTheme.ocean
        case .games: return AshteTheme.sunset
        }
    }
    
    var color: Color {
        switch self {
        case .all: return AshteTheme.violet
        case .apps: return AshteTheme.cyan
        case .games: return AshteTheme.pink
        }
    }
}

// MARK: - Models
struct AshteHomeAppResponse: Codable {
    let name: String?
    let apps: [AshteHomeAppModel]
}

struct AshteHomeAppModel: Codable, Identifiable {
    var id: Int { idNumber }
    let idNumber: Int
    let name: String
    let version: String?
    let category: String?
    let type: String? 
    let iconURL: String?
    let size: String?
    let developerName: String?
    let bundleIdentifier: String?
    let download_url: String
    let descriptionText: String? 
    
    var stringID: String { return "\(idNumber)" }
    var downloadURLObject: URL? { return URL(string: download_url) }
    
    enum CodingKeys: String, CodingKey {
        case idNumber = "id"
        case name, version, category, type, iconURL, size, developerName, bundleIdentifier, download_url
        case descriptionText = "description"
    }

    var fullImageURL: URL? {
        guard let img = iconURL else { return nil }
        if img.hasPrefix("http") { return URL(string: img) }
        return URL(string: "https://ashtemobile.site/\(img)")
    }
}

// MARK: - Banner Model
struct SocialBanner: Identifiable {
    let id = UUID()
    let imageURL: URL?
    let destinationURL: URL?
}

// MARK: - Main Home View
struct HomeView: View {
    @Environment(\.openURL) var openURL
    @State private var appsList: [AshteHomeAppModel] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var selectedTab: HomeCategoryTab = .all
    
    @State private var _selectedInstallAppPresenting: AnyApp?
    @AppStorage("AshteMobile.installationMethod") private var installationMethod: Int = 0
    
    @FetchRequest(
        entity: Signed.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
        animation: .snappy
    ) private var _signedApps: FetchedResults<Signed>
    
    private var filteredApps: [AshteHomeAppModel] {
        appsList.filter { app in
            let matchesSearch = searchText.isEmpty || app.name.localizedCaseInsensitiveContains(searchText)
            guard matchesSearch else { return false }
            
            let appType = (app.type ?? "").lowercased()
            switch selectedTab {
            case .all: return true
            case .apps: return appType == "apps"
            case .games: return appType == "games"
            }
        }
    }
    
    @State private var _currentBannerIndex = 0
    private let bannerTimer = Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()
    
    let staticBanners = [
        SocialBanner(
            imageURL: URL(string: "https://ashtemobile.site/img/t.png"),
            destinationURL: URL(string: "https://t.me/ashtemobile")
        ),
        SocialBanner(
            imageURL: URL(string: "https://ashtemobile.site/img/i.png"),
            destinationURL: URL(string: "https://instagram.com/ashtemobile")
        )
    ]
    
    var body: some View {
        NBNavigationView(.localized("Discover")) {
            ZStack {
                AshteBackground()
                
                if isLoading && appsList.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(AshteTheme.pink)
                        Text(.localized("Loading..."))
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            
                            if searchText.isEmpty {
                                TabView(selection: $_currentBannerIndex) {
                                    ForEach(staticBanners.indices, id: \.self) { index in
                                        let banner = staticBanners[index]
                                        Button {
                                            if let url = banner.destinationURL {
                                                UIApplication.shared.open(url)
                                            }
                                        } label: {
                                            AsyncImage(url: banner.imageURL) { phase in
                                                if let image = phase.image {
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                } else if phase.error != nil {
                                                    Rectangle().fill(Color(uiColor: .secondarySystemBackground))
                                                        .overlay(Image(systemName: "photo.fill").foregroundColor(.secondary))
                                                } else {
                                                    Rectangle().fill(Color(uiColor: .secondarySystemBackground))
                                                        .overlay(ProgressView())
                                                }
                                            }
                                            .frame(height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                    .strokeBorder(AshteTheme.primary, lineWidth: 2.5)
                                            )
                                            .shadow(color: AshteTheme.violet.opacity(0.35), radius: 14, x: 0, y: 8)
                                            .padding(.horizontal, 20)
                                        }
                                        .buttonStyle(.plain)
                                        .tag(index)
                                    }
                                }
                                .frame(height: 230)
                                .tabViewStyle(.page(indexDisplayMode: .always))
                                .onReceive(bannerTimer) { _ in
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        _currentBannerIndex = (_currentBannerIndex + 1) % staticBanners.count
                                    }
                                }
                                .padding(.top, 10)
                            }
                            
                            HStack(spacing: 10) {
                                ForEach(HomeCategoryTab.allCases) { tab in
                                    Button {
                                        let generator = UIImpactFeedbackGenerator(style: .light)
                                        generator.impactOccurred()
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            selectedTab = tab
                                        }
                                    } label: {
                                        Label(tab.title, systemImage: tab.icon)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(selectedTab == tab ? .white : .primary)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 8)
                                            .background(
                                                ZStack {
                                                    if selectedTab == tab {
                                                        Capsule()
                                                            .fill(tab.gradient)
                                                            .matchedGeometryEffect(id: "activeTabBadge", in: tabAnimation)
                                                    } else {
                                                        Capsule()
                                                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                                                    }
                                                }
                                            )
                                            .shadow(color: selectedTab == tab ? tab.color.opacity(0.4) : .black.opacity(0.03), radius: 6, x: 0, y: 3)
                                            .scaleEffect(selectedTab == tab ? 1.05 : 1)
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            if !filteredApps.isEmpty {
                                VStack(spacing: 14) {
                                    AshteSectionTitle(
                                        title: selectedTab.title,
                                        count: filteredApps.count,
                                        gradient: selectedTab.gradient
                                    )
                                    .padding(.horizontal, 22)
                                    
                                    VStack(spacing: 0) {
                                        ForEach(filteredApps) { app in
                                            NavigationLink(destination: AshteHomeAppDetailView(app: app, onDownloadComplete: { handleAutoSign(for: app) })) {
                                                AshteHomeAppCell(app: app, onDownloadComplete: { handleAutoSign(for: app) })
                                                    .padding(.horizontal, 20)
                                                    .padding(.vertical, 14)
                                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                            }
                                            .buttonStyle(.plain)
                                            
                                            if app.idNumber != filteredApps.last?.idNumber {
                                                Divider()
                                                    .padding(.leading, 95)
                                            }
                                        }
                                    }
                                    .ashteCard(cornerRadius: 24, tint: selectedTab.color)
                                    .padding(.horizontal, 16)
                                }
                            } else if !searchText.isEmpty || !isLoading {
                                AshteHomeEmptyView()
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: .localized("Search apps..."))
            .refreshable {
                await loadRemoteApps()
            }
        }
        .task {
            await loadRemoteApps()
        }
        .sheet(item: $_selectedInstallAppPresenting) { app in
            InstallPreviewView(app: app.base, isSharing: app.archive)
                .id(app.base.identifier ?? UUID().uuidString)
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AshteMobile.installApp"))) { notification in
            let startTime = notification.object as? Date ?? Date().addingTimeInterval(-5.0)
            
            let now = Date().timeIntervalSince1970
            let lastTime = UserDefaults.standard.double(forKey: "AshteMobile.GlobalInstallLock")
            
            if now - lastTime > 2.0 {
                UserDefaults.standard.set(now, forKey: "AshteMobile.GlobalInstallLock")
                presentInstallView(since: startTime, retryCount: 0)
            }
        }
    }
    
    @Namespace private var tabAnimation
    
    private func presentInstallView(since targetTime: Date, retryCount: Int) {
        Storage.shared.context.refreshAllObjects()
        let request = NSFetchRequest<Signed>(entityName: "Signed")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Signed.date, ascending: false)]
        request.fetchLimit = 1
        
        if let latestApp = try? Storage.shared.context.fetch(request).first,
           let appDate = latestApp.value(forKey: "date") as? Date,
           appDate >= targetTime { 
            
            _selectedInstallAppPresenting = AnyApp(base: latestApp)
            
        } else if retryCount < 15 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                presentInstallView(since: targetTime, retryCount: retryCount + 1)
            }
        } else {
            if let fallback = try? Storage.shared.context.fetch(request).first {
                 _selectedInstallAppPresenting = AnyApp(base: fallback)
            }
        }
    }
    
    private func handleAutoSign(for app: AshteHomeAppModel) {
        if installationMethod == 1 { return }
        
        let signStartTime = Date().addingTimeInterval(-2.0)
        
        AshteAutoSigner.signAfterDownload(id: app.stringID, appName: app.name) { result in
            if case .signed = result {
                NotificationCenter.default.post(name: Notification.Name("AshteMobile.ShowSignSuccess"), object: app.name)
                NotificationCenter.default.post(name: Notification.Name("AshteMobile.installApp"), object: signStartTime)
            }
        }
    }
    
    private func loadRemoteApps() async {
        isLoading = true
        guard let url = URL(string: "https://ashtemobile.site/Ashtemobile.json") else {
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(AshteHomeAppResponse.self, from: data)
            DispatchQueue.main.async {
                self.appsList = decoded.apps
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async { self.isLoading = false }
        }
    }
}

// MARK: - Empty State View
struct AshteHomeEmptyView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(AshteTheme.candy)
            Text(.localized("No Applications Found"))
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.primary)
            Text(.localized("Try selecting another category or searching again."))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Sleek App Cell
struct AshteHomeAppCell: View {
    let app: AshteHomeAppModel
    var onDownloadComplete: () -> Void
    
    @ObservedObject private var downloadManager = DownloadManager.shared
    @State private var downloadProgress: Double = 0
    @State private var cancellable: AnyCancellable?
    @State private var hasTriggeredDownloadAction = false

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(UIColor.tertiarySystemGroupedBackground)
            }
            .frame(width: 65, height: 65)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: AshteTheme.violet.opacity(0.18), radius: 6, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(app.type == "games" ? "Game" : "App") • v\(app.version ?? "1.0")")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 10)
            
            ZStack {
                if let currentDownload = downloadManager.getDownload(by: app.stringID) {
                    ZStack {
                        Circle()
                            .trim(from: 0, to: downloadProgress)
                            .stroke(AshteTheme.primary, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 32, height: 32)
                            .animation(.smooth, value: downloadProgress)

                        Image(systemName: downloadProgress >= 0.75 ? "archivebox.fill" : "stop.fill")
                            .foregroundStyle(.tint)
                            .font(.system(size: 11, weight: .black))
                    }
                    .onTapGesture {
                        if downloadProgress <= 0.75 {
                            downloadManager.cancelDownload(currentDownload)
                        }
                    }
                } else {
                    Button(action: { triggerDownload() }) {
                        Text(.localized("Get"))
                    }
                    .buttonStyle(AshteGradientButtonStyle(
                        gradient: app.type == "games" ? AshteTheme.sunset : AshteTheme.primary,
                        shadowColor: app.type == "games" ? AshteTheme.pink : AshteTheme.violet
                    ))
                }
            }
        }
        .onAppear(perform: setupObserver)
        .onDisappear { cancellable?.cancel() }
        .onChange(of: downloadManager.downloads.count) { _ in
            let isCurrentlyDownloading = downloadManager.getDownload(by: app.stringID) != nil
            if isCurrentlyDownloading {
                setupObserver()
                hasTriggeredDownloadAction = false 
            } else if downloadProgress >= 0.98 && !hasTriggeredDownloadAction {
                hasTriggeredDownloadAction = true 
                onDownloadComplete()
            }
        }
    }
    
    // 💡 ئەوەتە ئێرەمان چاککرد تا ناوەکەی بنێرێت بۆ شاشەکە
    private func triggerDownload() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        if let dlURL = app.downloadURLObject {
            AshteAutoSigner.markDownloadStart(id: app.stringID)
            _ = DownloadManager.shared.startDownload(
                from: dlURL, 
                id: app.stringID,
                appName: app.name,            // 💡 دڵنیابە ئەمە هەیە
                appIconURL: app.fullImageURL  // 💡 دڵنیابە ئەمە هەیە
            )
        }
    }
    
    private func setupObserver() {
        cancellable?.cancel()
        guard let download = downloadManager.getDownload(by: app.stringID) else {
            downloadProgress = 0
            return
        }
        downloadProgress = download.overallProgress
        let publisher = Publishers.CombineLatest(download.$progress, download.$unpackageProgress)
        cancellable = publisher.sink { _, _ in downloadProgress = download.overallProgress }
    }
}

// MARK: - Premium Detail View
struct AshteHomeAppDetailView: View {
    let app: AshteHomeAppModel
    var onDownloadComplete: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject private var downloadManager = DownloadManager.shared
    @State private var downloadProgress: Double = 0
    @State private var cancellable: AnyCancellable?
    @State private var hasTriggeredDownloadAction = false 
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    GeometryReader { proxy in
                        let minY = proxy.frame(in: .global).minY
                        AsyncImage(url: app.fullImageURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: proxy.size.width, height: proxy.size.height + (minY > 0 ? minY : 0))
                        .clipped()
                        .offset(y: minY > 0 ? -minY : 0)
                        .blur(radius: 30, opaque: true)
                        .overlay(Color.black.opacity(0.2))
                        .overlay(
                            AshteTheme.primary.opacity(0.55)
                                .blendMode(.softLight)
                        )
                    }
                    .frame(height: 250)
                    
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        Spacer()
                        if let shareURL = URL(string: app.download_url) {
                            ShareLink(item: shareURL) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(.ultraThinMaterial, in: Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, _topSafeAreaInset)
                }
                
                VStack(spacing: 16) {
                    AsyncImage(url: app.fullImageURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color(UIColor.secondarySystemBackground)
                    }
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(AshteTheme.candy, lineWidth: 3)
                    )
                    .shadow(color: AshteTheme.pink.opacity(0.35), radius: 16, x: 0, y: 8)
                    .padding(.top, -55)
                    
                    VStack(spacing: 8) {
                        Text(app.name)
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text(app.developerName ?? "AshteMobile")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(AshteTheme.violet)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 5)
                            .background(AshteTheme.violet.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 16) {
                        if downloadManager.getDownload(by: app.stringID) != nil {
                            VStack(spacing: 8) {
                                HStack {
                                    ProgressView()
                                        .tint(AshteTheme.pink)
                                        .padding(.trailing, 4)
                                    Text(.localized("Downloading..."))
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                    Spacer()
                                    Text("\(Int(downloadProgress * 100))%")
                                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                                }
                                .foregroundColor(AshteTheme.violet)
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(AshteTheme.violet.opacity(0.15))
                                        Capsule()
                                            .fill(AshteTheme.primary)
                                            .frame(width: geo.size.width * CGFloat(min(max(downloadProgress, 0), 1)))
                                            .animation(.smooth, value: downloadProgress)
                                    }
                                }
                                .frame(height: 8)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(AshteTheme.violet.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        } else {
                            Button(action: { triggerDownload() }) {
                                Text(.localized("Get"))
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            }
                            .buttonStyle(AshteGradientButtonStyle(
                                gradient: app.type == "games" ? AshteTheme.sunset : AshteTheme.primary,
                                shadowColor: app.type == "games" ? AshteTheme.pink : AshteTheme.violet,
                                horizontalPadding: 0, verticalPadding: 0
                            ))
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                    
                    HStack(spacing: 15) {
                        AshteInfoCard(title: "Version", value: app.version ?? "1.0", icon: "v.circle.fill", gradient: AshteTheme.primary)
                        AshteInfoCard(title: "Size", value: app.size ?? "N/A", icon: "shippingbox.fill", gradient: AshteTheme.ocean)
                        AshteInfoCard(title: "Category", value: app.type == "games" ? "Game" : "App", icon: "square.grid.2x2.fill", gradient: AshteTheme.sunset)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 15)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        AshteSectionTitle(title: "About this app")
                        
                        Text(app.descriptionText ?? "No description available for \(app.name). Discover the amazing features inside.")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .ashteCard(cornerRadius: 26)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                .padding(.bottom, 50)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .background(AshteBackground())
        .navigationBarHidden(true)
        .onAppear(perform: setupObserver)
        .onDisappear { cancellable?.cancel() }
        .onChange(of: downloadManager.downloads.count) { _ in
            let isCurrentlyDownloading = downloadManager.getDownload(by: app.stringID) != nil
            if isCurrentlyDownloading {
                setupObserver()
                hasTriggeredDownloadAction = false
            } else if downloadProgress >= 0.98 && !hasTriggeredDownloadAction {
                hasTriggeredDownloadAction = true 
                onDownloadComplete()
            }
        }
    }
    
    private var _topSafeAreaInset: CGFloat {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
        return scene?.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.top ?? 50
    }
    
    // 💡 لێرەشدا چاکمان کرد تا ناوەکەی بنێرێت بۆ شاشەکە
    private func triggerDownload() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        if let dlURL = app.downloadURLObject {
            AshteAutoSigner.markDownloadStart(id: app.stringID)
            _ = DownloadManager.shared.startDownload(
                from: dlURL, 
                id: app.stringID,
                appName: app.name,            // 💡 دڵنیابە ئەمە هەیە
                appIconURL: app.fullImageURL  // 💡 دڵنیابە ئەمە هەیە
            )
        }
    }
    
    private func setupObserver() {
        cancellable?.cancel()
        guard let download = downloadManager.getDownload(by: app.stringID) else {
            downloadProgress = 0
            return
        }
        downloadProgress = download.overallProgress
        let publisher = Publishers.CombineLatest(download.$progress, download.$unpackageProgress)
        cancellable = publisher.sink { _, _ in downloadProgress = downloadManager.getDownload(by: app.stringID)?.overallProgress ?? 0 }
    }
}

// MARK: - Modern Info Card
struct AshteInfoCard: View {
    let title: String
    let value: String
    let icon: String
    var gradient: LinearGradient = AshteTheme.primary
    
    var body: some View {
        VStack(spacing: 8) {
            AshteIconBadge(systemName: icon, gradient: gradient, size: 34)
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .ashteCard(cornerRadius: 20)
    }
}
