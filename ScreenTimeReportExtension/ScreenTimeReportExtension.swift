//
//  ScreenTimeReportExtension.swift
//  ScreenTimeReportExtension
//
//  Created by Pedro on 10/16/24.
//

import DeviceActivity
import SwiftUI

@main
struct ScreenTimeReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
    }
}
