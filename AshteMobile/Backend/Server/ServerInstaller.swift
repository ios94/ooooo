//
//  Server.swift
//  ashtemobile
//
//  Created by samara on 22.08.2024.
//  Copyright © 2024 Lakr Aream. All Rights Reserved.
//  MODIFIED: 100% Cache-Busting for Concurrent Installs ⚡️
//

import Foundation
import Vapor
import NIOSSL
import NIOTLS
import SwiftUI
import IDeviceSwift

// MARK: - Class
class ServerInstaller: Identifiable, ObservableObject {
	let id = UUID()
	let port = Int.random(in: 4000...8000)
	private var _needsShutdown = false
	
	var packageUrl: URL?
	var app: AppInfoPresentable
	@ObservedObject var viewModel: InstallerStatusViewModel
	private var _server: Application?

	init(app: AppInfoPresentable, viewModel: InstallerStatusViewModel) throws {
		self.app = app
		self.viewModel = viewModel
		try _setup()
		try _configureRoutes()
		guard let server = _server else {
			throw NSError(domain: "AshteMobile.ServerInstaller", code: 1,
				userInfo: [NSLocalizedDescriptionKey: "Unable to start the local installation server."])
		}
		try server.server.start()
		_needsShutdown = true
	}
	
	deinit {
		_shutdownServer()
	}
	
	private func _setup() throws {
		self._server = try setupApp(port: port)
	}
		
	private func _configureRoutes() throws {
		_server?.get("*") { [weak self] req in
			guard let self else { return Response(status: .badGateway) }
            
            // 💡 هەموو وەڵامەکان بەبێ کاش دەنێرین بۆ ئەوەی هەرگیز تێکەڵ نەبن کاتێک پێکەوە واژوو دەکرێن
            var headers = HTTPHeaders()
            headers.add(name: .cacheControl, value: "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0")
            headers.add(name: .pragma, value: "no-cache")
            headers.add(name: .expires, value: "0")
            
			switch req.url.path {
			case self.plistEndpoint.path:
				self._updateStatus(.sendingManifest)
                headers.add(name: .contentType, value: "text/xml")
				return Response(status: .ok, version: req.version, headers: headers, body: .init(data: self.installManifestData))
                
			case self.displayImageSmallEndpoint.path:
                headers.add(name: .contentType, value: "image/png")
				return Response(status: .ok, version: req.version, headers: headers, body: .init(data: self.displayImageSmallData))
                
			case self.displayImageLargeEndpoint.path:
                headers.add(name: .contentType, value: "image/png")
				return Response(status: .ok, version: req.version, headers: headers, body: .init(data: self.displayImageLargeData))
                
			case self.payloadEndpoint.path:
				guard let packageUrl = self.packageUrl else {
					return Response(status: .notFound)
				}
				
				self._updateStatus(.sendingPayload)
				
				let response = req.fileio.streamFile(
					at: packageUrl.path
				) { result in
					switch result {
					case .success:
						self._updateStatus(.installing)
					case .failure(let error):
						self._updateStatus(.broken(error))
					}
				}
                // ڕێگری لە کاشکردنی فایلی IPA
                response.headers.add(name: .cacheControl, value: "no-store, no-cache, must-revalidate, max-age=0")
                return response
                
			case "/install":
                headers.add(name: .contentType, value: "text/html")
                
                // 💡 فێڵی کۆتایی: لکاندنی ژمارەی هەڕەمەکی بە لینکی ئینستاڵەکە بۆ ئەوەی ئایفۆن نەتوانێت کۆنەکە بخوێنێتەوە!
                var finalHTML = self.html
                let uuidBuster = UUID().uuidString.replacingOccurrences(of: "-", with: "")
                
                if finalHTML.contains("\"</script>") {
                    finalHTML = finalHTML.replacingOccurrences(of: "\"</script>", with: "%26cb%3D\(uuidBuster)\"</script>")
                }
                
                return Response(status: .ok, headers: headers, body: .init(string: finalHTML))
                
			default:
				return Response(status: .notFound)
			}
		}
	}
	
	private func _shutdownServer() {
		guard _needsShutdown else { return }
		
		_needsShutdown = false
		_server?.server.shutdown()
		_server?.shutdown()
	}
	
	private func _updateStatus(_ newStatus: InstallerStatusViewModel.InstallerStatus) {
		DispatchQueue.main.async {
			self.viewModel.status = newStatus
		}
	}
		
	func getServerMethod() -> Int {
		UserDefaults.standard.integer(forKey: "AshteMobile.serverMethod")
	}
	
	func getIPFix() -> Bool {
		UserDefaults.standard.bool(forKey: "AshteMobile.ipFix")
	}
}
