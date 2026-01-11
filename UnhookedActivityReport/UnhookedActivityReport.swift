//
//  UnhookedActivityReport.swift
//  UnhookedActivityReport
//
//  Created by Simon Chen on 11/11/25.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
@MainActor
struct UnhookedActivityReport: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // Create a report for each DeviceActivityReport.Context that your app supports.
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
    }
}
