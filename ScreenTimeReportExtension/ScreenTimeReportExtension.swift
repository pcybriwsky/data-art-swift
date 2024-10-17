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
        // Use the appropriate context for your needs
        DeviceActivityReport(context: .init(rawValue: "DailyScreenTime"))
    }
}

extension DeviceActivityName {
    static let daily = Self("daily")
}

extension DeviceActivityEvent.Name {
    static let encouraged = Self("encouraged")
}

// Note: The following code should be in your main app, not in the extension
// It's included here for reference, but should be moved to the appropriate place in your main app

/*
class MyModel {
    var selectionToEncourage: FamilyActivitySelection
    var minutes: Int
    
    init() {
        // Initialize with default values
        self.selectionToEncourage = FamilyActivitySelection()
        self.minutes = 60 // Default to 1 hour
    }
}

let schedule = DeviceActivitySchedule(
    intervalStart: DateComponents(hour: 0, minute: 0),
    intervalEnd: DateComponents(hour: 23, minute: 59),
    repeats: true
)

let model = MyModel()

let events: [DeviceActivityEvent.Name: DeviceActivityName] = [
    .encouraged: DeviceActivityName(
        applications: model.selectionToEncourage.applicationsTokens,
        threshold: DateComponents(minute: model.minutes)
    )
]

let center = DeviceActivityCenter()
try? center.startMonitoring(.daily, events: events, during: schedule)

let filter = DeviceActivityFilter(
    segment: .daily(during: schedule),
    users: .all,
    devices: .init([.iPhone, .iPad])
)
*/
