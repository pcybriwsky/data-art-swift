import WidgetKit
import SwiftUI
import HealthKit

struct Provider: TimelineProvider {
    let healthStore = HKHealthStore()
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), distance: 0, useImperialUnits: UserManager.shared.useImperialUnits, year: UserManager.shared.startYear)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let useImperialUnits = UserManager.shared.useImperialUnits
        let startYear = UserManager.shared.startYear
        fetchDistanceSince(year: startYear, useImperialUnits: useImperialUnits) { distance in
            let entry = SimpleEntry(date: Date(), distance: distance, useImperialUnits: useImperialUnits, year: startYear)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let useImperialUnits = UserManager.shared.useImperialUnits
        let startYear = UserManager.shared.startYear
        fetchDistanceSince(year: startYear, useImperialUnits: useImperialUnits) { distance in
            let entry = SimpleEntry(date: Date(), distance: distance, useImperialUnits: useImperialUnits, year: startYear)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    func fetchDistanceSince(year: Int, useImperialUnits: Bool, completion: @escaping (Double) -> Void) {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        let startDate = Calendar.current.date(from: components)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch distance: \(error?.localizedDescription ?? "Unknown error")")
                completion(0)
                return
            }
            
            let distance = sum.doubleValue(for: useImperialUnits ? HKUnit.mile() : HKUnit.meter())
            let finalDistance = useImperialUnits ? distance : distance / 1000 // Convert meters to kilometers
            completion(finalDistance)
        }
        
        healthStore.execute(query)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let distance: Double
    let useImperialUnits: Bool
    let year: Int
}

struct GenArtWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color.clear // This ensures the widget has a background
            Image(uiImage: StepArtRenderer.renderOdometer(
                distance: entry.distance,
                unit: entry.useImperialUnits ? "miles" : "km",
                size: widgetSize,
                year: entry.year
            ))
            .resizable()
            .aspectRatio(contentMode: .fit)
        }
        .containerBackground(for: .widget) {
            Color.clear // This sets the container background
        }
    }
    
    var widgetSize: CGSize {
        switch family {
        case .systemSmall:
            return CGSize(width: 158, height: 158)
        case .systemMedium:
            return CGSize(width: 338, height: 158)
        default:
            return CGSize(width: 338, height: 158)
        }
    }
}

struct GenArtWidget: Widget {
    let kind: String = "GenArtWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GenArtWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Distance Odometer")
        .description("Displays total distance walked/run since the selected year")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview {
    GenArtWidgetEntryView(entry: SimpleEntry(date: Date(), distance: 236.9, useImperialUnits: true, year: 2024))
        .previewContext(WidgetPreviewContext(family: .systemMedium))
}
