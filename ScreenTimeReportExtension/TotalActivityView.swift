//
//  TotalActivityView.swift
//  ScreenTimeReportExtension
//
//  Created by Pedro on 10/16/24.
//

import SwiftUI
import DeviceActivity

struct TotalActivityView: View {
    let totalActivity: DeviceActivityReport.TotalActivityReport

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Screen Time Report")
                .font(.title)
            
            Text("Total Screen Time: \(formatDuration(totalActivity.totalDuration))")
            
            Text("Device Pickups: \(totalActivity.pickupCount)")
            
            Text("App Usage:")
            ForEach(totalActivity.applications.sorted(by: { $0.value > $1.value }), id: \.key) { app, duration in
                HStack {
                    Text(app.localizedDisplayName ?? "Unknown App")
                    Spacer()
                    Text(formatDuration(duration))
                }
            }
        }
        .padding()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "N/A"
    }
}

// In order to support previews for your extension's custom views, make sure its source files are
// members of your app's Xcode target as well as members of your extension's target. You can use
// Xcode's File Inspector to modify a file's Target Membership.
#Preview {
    TotalActivityView(totalActivity: "1h 23m")
}
