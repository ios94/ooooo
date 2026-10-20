//
//  FileManager+documents.swift
//  AshteMobile
//
//  Created by samara on 11.04.2025.
//

import Foundation.NSFileManager

extension FileManager {
    
    // 💡 ئەمە فۆڵدەرە شاراوەکەی ناو سیستەمە کە هیچ کەس نایبینێت
    private var hiddenDirectory: URL {
        return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
    }
    
	/// Gives apps Archives directory
	var archives: URL {
        hiddenDirectory.appendingPathComponent("Archives")
	}
	
	/// Gives apps Signed directory
	var signed: URL {
        hiddenDirectory.appendingPathComponent("Signed")
	}
	
	/// Gives apps Signed directory with a UUID appending path
	func signed(_ uuid: String) -> URL {
		signed.appendingPathComponent(uuid)
	}
	
	/// Gives apps Unsigned directory
	var unsigned: URL {
        hiddenDirectory.appendingPathComponent("Unsigned")
	}
	
	/// Gives apps Unsigned directory with a UUID appending path
	func unsigned(_ uuid: String) -> URL {
		unsigned.appendingPathComponent(uuid)
	}
	
	/// Gives apps Certificates directory
	var certificates: URL {
        hiddenDirectory.appendingPathComponent("Certificates")
	}
    
	/// Gives apps Certificates directory with a UUID appending path
	func certificates(_ uuid: String) -> URL {
		certificates.appendingPathComponent(uuid)
	}
}
