//
//  SourcesViewModel.swift
//  AshteMobile
//
//  Created by samara on 30.04.2025.
//

import Foundation
import AltSourceKit
import SwiftUI
import NimbleJSON

final class SourcesViewModel: ObservableObject {
    static let shared = SourcesViewModel()
    
    typealias RepositoryDataHandler = Result<ASRepository, Error>
    
    private let _dataService = NBFetchService()
    
    var isFinished = true
    @Published var sources: [AltSource: ASRepository] = [:]
    
    func fetchSources(_ sources: FetchedResults<AltSource>, refresh: Bool = false, batchSize: Int = 4) async {
        guard isFinished else { return }
        
        if !refresh, sources.allSatisfy({ self.sources[$0] != nil }) { return }
        
        isFinished = false
        defer { isFinished = true }
        
        await MainActor.run {
            self.sources = [:]
        }
        
        let sourcesArray = Array(sources)
        
        for startIndex in stride(from: 0, to: sourcesArray.count, by: batchSize) {
            let endIndex = min(startIndex + batchSize, sourcesArray.count)
            let batch = sourcesArray[startIndex..<endIndex]
            
            // 💡 لێرەدا URLەکان دەردەهێنین پێش ئەوەی بچنە ناو Task بۆ ڕێگریکردن لە کێشەی Sendable
            let batchData = batch.compactMap { source -> (AltSource, URL)? in
                guard let url = source.sourceURL else { return nil }
                return (source, url)
            }
            
            let batchResults = await withTaskGroup(of: (AltSource, ASRepository?).self, returning: [AltSource: ASRepository].self) { group in
                for (source, url) in batchData {
                    group.addTask {
                        return await withCheckedContinuation { continuation in
                            self._dataService.fetch(from: url) { (result: RepositoryDataHandler) in
                                switch result {
                                case .success(let repo):
                                    continuation.resume(returning: (source, repo))
                                case .failure(_):
                                    continuation.resume(returning: (source, nil))
                                }
                            }
                        }
                    }
                }
                
                var results = [AltSource: ASRepository]()
                for await (source, repo) in group {
                    if let repo {
                        results[source] = repo
                    }
                }
                return results
            }
            
            await MainActor.run {
                for (source, repo) in batchResults {
                    self.sources[source] = repo
                }
            }
        }
    }
}
