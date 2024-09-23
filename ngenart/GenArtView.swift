import SwiftUI
import HealthKit
import WidgetKit

@available(iOS 16.0, *)
public struct GenArtView: View {
    @State private var totalDistance: Double = 0
    @State private var useImperialUnits: Bool
    @State private var startYear: Int
    @State private var availableYears: [Int] = []
    let healthStore = HKHealthStore()

    public init() {
        _useImperialUnits = State(initialValue: UserManager.shared.useImperialUnits)
        _startYear = State(initialValue: UserManager.shared.startYear)
    }

    public var body: some View {
        VStack {
            MainAppOdometerView(distance: totalDistance, useImperialUnits: useImperialUnits, startYear: startYear)
                .frame(width: 338, height: 158)
                .background(Color(hex: 0xf6f6f6))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Odometer")
                    .font(.custom("BodoniModa18pt-Italic", size: 24))
                    .padding(8)
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("The Odometer is an art piece that visualizes your total \(useImperialUnits ? "miles" : "kilometers") traveled since \(String(format: "%d", startYear)).\nIn order to use this piece, you must share access to your health data.")
                            .font(.system(size: 17))
                            .padding(8)
                        Text("Customize")
                            .font(.custom("BodoniModa18pt-Italic", size: 24))
                            .padding(8)
                        HStack(alignment: .top, spacing: 0) {
                            VStack(spacing: 8) {
                                Text("Imperial Units")
                                    .font(.system(size: 17))
                                Toggle("", isOn: $useImperialUnits)
                                    .labelsHidden()
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(height: 100, alignment: .center)
                            
                            VStack(spacing: 8) {
                                Text("Start Year")
                                    .font(.system(size: 17))
                                Picker("Start Year", selection: $startYear) {
                                    ForEach(availableYears, id: \.self) { year in
                                        Text(String(year)).tag(year)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .disabled(availableYears.isEmpty)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .frame(height: 100, alignment: .center)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(hex: 0xfffef7))
            .padding(1)
            .offset(y: 72)
        }
        .onAppear {
            fetchEarliestRecordedYear()
            fetchTotalDistanceSince2024()
            requestAuthorization()
        }
        .onChange(of: useImperialUnits) { newValue in
            UserManager.shared.useImperialUnits = newValue
            fetchTotalDistanceSince2024()
        }
        .onChange(of: startYear) { newValue in
            UserManager.shared.startYear = newValue
            fetchTotalDistanceSince2024()
        }
    }

    func requestAuthorization() {
        let typesToShare: Set = [HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!]
        let typesToRead: Set = [HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            if success {
                print("Authorization successful")
                self.fetchTotalDistanceSince2024()
            } else {
                if let error = error {
                    print("Authorization failed with error: \(error.localizedDescription)")
                }
            }
        }
    }

    func fetchEarliestRecordedYear() {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(sampleType: distanceType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            if let sample = samples?.first as? HKQuantitySample {
                let earliestYear = Calendar.current.component(.year, from: sample.startDate)
                let currentYear = Calendar.current.component(.year, from: Date())
                DispatchQueue.main.async {
                    self.availableYears = Array(earliestYear...currentYear)
                    if !self.availableYears.contains(self.startYear) {
                        self.startYear = earliestYear
                    }
                }
            }
        }
        healthStore.execute(query)
    }

    func fetchTotalDistanceSince2024() {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let startDate = Calendar.current.date(from: DateComponents(year: startYear, month: 1, day: 1))!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("Failed to fetch total distance")
                return
            }
            
            DispatchQueue.main.async {
                let distanceInMeters = sum.doubleValue(for: HKUnit.meter())
                self.totalDistance = self.useImperialUnits ? distanceInMeters / 1609.34 : distanceInMeters / 1000
            }
        }
        
        healthStore.execute(query)
    }
}

public struct MainAppOdometerView: View {
    let distance: Double
    let useImperialUnits: Bool
    let startYear: Int
    
    public var body: some View {
        GeometryReader { geometry in
            Image(uiImage: StepArtRenderer.renderOdometer(
                distance: distance,
                unit: useImperialUnits ? "miles" : "km",
                size: geometry.size,
                year: startYear
            ))
            .resizable()
            .aspectRatio(contentMode: .fit)
        }
    }
}