//
//  ActivityReportContext.swift
//  Unhooked
//
//  Constants for DeviceActivity reporting
//

import Foundation

/// Constants for report contexts (must match extension's context names)
struct ActivityReportContextNames {
    static let totalActivity = "Total Activity"
}

/// Filter for specific app usage
struct ActivityReportFilter: Codable, Hashable {
    let segment: String
    let appTokens: [String]  // Base64 encoded app tokens
    
    init(segment: String = "daily", appTokens: [String] = []) {
        self.segment = segment
        self.appTokens = appTokens
    }
}

