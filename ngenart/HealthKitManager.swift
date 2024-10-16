import HealthKit
import SwiftUI

class HealthKitManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var isAuthorized: Bool = false
    @Published var stepCountAuthorized: Bool = false
    @Published var sleepAuthorized: Bool = false
    @Published var distanceWalkingRunningAuthorized: Bool = false
    
    // Check if HealthKit is available on this device
    func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    func checkAuthorizationStatus() {
        checkStepCountAccess { success in
            DispatchQueue.main.async {
                self.stepCountAuthorized = success
            }
        }
        
        checkSleepAnalysisAccess { success in
            DispatchQueue.main.async {
                self.sleepAuthorized = success
            }
        }
        
        checkDistanceWalkingRunningAccess { success in
            DispatchQueue.main.async {
                self.distanceWalkingRunningAuthorized = success
            }
        }
        
        DispatchQueue.main.async {
            self.isAuthorized = self.stepCountAuthorized && self.sleepAuthorized && self.distanceWalkingRunningAuthorized
            
            print("Step count authorized: \(self.stepCountAuthorized)")
            print("Sleep analysis authorized: \(self.sleepAuthorized)")
            print("Distance walking/running authorized: \(self.distanceWalkingRunningAuthorized)")
            print("Overall HealthKit authorized: \(self.isAuthorized)")
            
            if self.isAuthorized {
                print("HealthKit authorization confirmed for all required data types")
                self.testFetchSleepData()
            } else {
                print("HealthKit authorization not confirmed for all required data types")
            }
        }
        
    }
    
    private func checkStepCountAccess(completion: @escaping (Bool) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let query = HKSampleQuery(sampleType: stepType, predicate: nil, limit: 1, sortDescriptors: nil) { (query, samples, error) in
            let success = error == nil && samples != nil
            print("Step count access: \(success ? "Granted" : "Denied")")
            completion(success)
        }
        healthStore.execute(query)
    }
    
    private func checkSleepAnalysisAccess(completion: @escaping (Bool) -> Void) {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let query = HKSampleQuery(sampleType: sleepType, predicate: nil, limit: 1, sortDescriptors: nil) { (query, samples, error) in
            let success = error == nil && samples != nil
            print("Sleep analysis access: \(success ? "Granted" : "Denied")")
            completion(success)
        }
        healthStore.execute(query)
    }
    
    private func checkDistanceWalkingRunningAccess(completion: @escaping (Bool) -> Void) {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let query = HKSampleQuery(sampleType: distanceType, predicate: nil, limit: 1, sortDescriptors: nil) { (query, samples, error) in
            let success = error == nil && samples != nil
            print("Distance walking/running access: \(success ? "Granted" : "Denied")")
            completion(success)
        }
        healthStore.execute(query)
    }
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if success {
                self.checkAuthorizationStatus()
            }
            completion(success, error)
        }
    }
    
    func testFetchSleepData() {
        fetchSleepData { sleepHours, error in
            if let sleepHours = sleepHours {
                print("Sleep data fetched successfully. Total sleep in the last 7 days: \(sleepHours) hours")
            } else if let error = error {
                print("Error fetching sleep data: \(error.localizedDescription)")
            } else {
                print("No sleep data available for the last 7 days")
            }
        }
    }
    
    // Request HealthKit authorization

    func fetchSleepData(completion: @escaping (Double?, Error?) -> Void) {
        print("In sleep fetch")
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("Sleep Analysis type is not available")
            completion(nil, NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sleep Analysis type is not available"]))
            return
        }
        
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        print("Fetching sleep data from \(startDate) to \(Date())")
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            if let error = error {
                print("Error fetching sleep data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            guard let samples = samples as? [HKCategorySample] else {
                print("No sleep samples found or unable to cast samples")
                DispatchQueue.main.async {
                    completion(nil, NSError(domain: "HealthKitManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No sleep samples found"]))
                }
                return
            }
            
            print("Found \(samples.count) sleep samples")
            
            let sleepTimeInHours = samples.reduce(0.0) { (result, sample) -> Double in
                let sleepTimeInSeconds = sample.endDate.timeIntervalSince(sample.startDate)
                return result + (sleepTimeInSeconds / 3600.0) // Convert seconds to hours
            }
            
            print("Total sleep time: \(sleepTimeInHours) hours")
            
            DispatchQueue.main.async {
                completion(sleepTimeInHours, nil)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch step count data
    func fetchStepCount(completion: @escaping (Double?, Error?) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let startDate = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let stepCount = sum.doubleValue(for: HKUnit.count())
            DispatchQueue.main.async {
                completion(stepCount, nil)
            }
        }
        
        healthStore.execute(query)
    }
    
    // Fetch all-time step count data
    func fetchTotalSteps(completion: @escaping (Double?, Error?) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: Date(), options: .strictEndDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let stepCount = sum.doubleValue(for: HKUnit.count())
            DispatchQueue.main.async {
                completion(stepCount, nil)
            }
        }
        
        healthStore.execute(query)
    }

    struct DailyStepRecord: Codable {
        let date: Date
        let steps: Int
    }

    struct DetailedStepData: Codable, Identifiable {
        let id: UUID
        let year: Int
        var monthlyData: [MonthlyStepData]
        var weeklyData: [WeeklyStepData]
        var dailyData: [DailyStepData]
    }

    struct MonthlyStepData: Codable, Identifiable {
        let id: UUID
        let month: Int
        var totalSteps: Int
        var averageSteps: Double
    }

    struct WeeklyStepData: Codable, Identifiable {
        let id: UUID
        let weekOfYear: Int
        var totalSteps: Int
        var averageSteps: Double
    }

    struct DailyStepData: Codable, Identifiable {
        let id: UUID
        let date: Date
        let steps: Int
    }

    struct YearlyStepData: Identifiable, Codable {
        let id: UUID
        let year: Int
        let totalSteps: Int
        let averageSteps: Double
        let mostStepsInDay: DailyStepRecord
        let leastStepsInDay: DailyStepRecord

        // Custom coding keys to ensure 'id' is encoded/decoded
        enum CodingKeys: String, CodingKey {
            case id, year, totalSteps, averageSteps, mostStepsInDay, leastStepsInDay
        }

        init(year: Int, totalSteps: Int, averageSteps: Double, mostStepsInDay: DailyStepRecord, leastStepsInDay: DailyStepRecord) {
            self.id = UUID()
            self.year = year
            self.totalSteps = totalSteps
            self.averageSteps = averageSteps
            self.mostStepsInDay = mostStepsInDay
            self.leastStepsInDay = leastStepsInDay
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            year = try container.decode(Int.self, forKey: .year)
            totalSteps = try container.decode(Int.self, forKey: .totalSteps)
            averageSteps = try container.decode(Double.self, forKey: .averageSteps)
            mostStepsInDay = try container.decode(DailyStepRecord.self, forKey: .mostStepsInDay)
            leastStepsInDay = try container.decode(DailyStepRecord.self, forKey: .leastStepsInDay)
        }
    }

    func fetchYearlyStepData(completion: @escaping ([YearlyStepData]?, Error?) -> Void) {
    let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    
    let calendar = Calendar.current
    let now = Date()
    let anchorDate = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))! // Start from year 2000
    
    let daily = DateComponents(day: 1)
    let query = HKStatisticsCollectionQuery(quantityType: stepType,
                                            quantitySamplePredicate: nil,
                                            options: [.cumulativeSum],
                                            anchorDate: anchorDate,
                                            intervalComponents: daily)
    
    query.initialResultsHandler = { query, results, error in
        if let error = error {
            DispatchQueue.main.async {
                completion(nil, error)
            }
            return
        }
        
        guard let results = results else {
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No results returned"]))
            }
            return
        }
        
        var yearlyData: [Int: (total: Int, count: Int, most: DailyStepRecord?, least: DailyStepRecord?)] = [:]
        
        results.enumerateStatistics(from: anchorDate, to: now) { statistics, stop in
            let year = calendar.component(.year, from: statistics.startDate)
            if let sum = statistics.sumQuantity() {
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                let dailyRecord = DailyStepRecord(date: statistics.startDate, steps: steps)
                
                if var yearData = yearlyData[year] {
                    yearData.total += steps
                    yearData.count += 1
                    
                    if steps > (yearData.most?.steps ?? Int.min) {
                        yearData.most = dailyRecord
                    }
                    
                    if steps < (yearData.least?.steps ?? Int.max) {
                        yearData.least = dailyRecord
                    }
                    
                    yearlyData[year] = yearData
                } else {
                    yearlyData[year] = (total: steps, count: 1, most: dailyRecord, least: dailyRecord)
                }
            }
        }
        
        let yearlyStepData = yearlyData.compactMap { year, data -> YearlyStepData? in
            guard let most = data.most, let least = data.least else { return nil }
            return YearlyStepData(
                year: year,
                totalSteps: data.total,
                averageSteps: Double(data.total) / Double(data.count),
                mostStepsInDay: most,
                leastStepsInDay: least
            )
        }.sorted { $0.year > $1.year }
        
        DispatchQueue.main.async {
            completion(yearlyStepData, nil)
        }
    }
    
    healthStore.execute(query)
}

func fetchDetailedStepData(completion: @escaping ([DetailedStepData]?, Error?) -> Void) {
    let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    
    let calendar = Calendar.current
    let now = Date()
    let anchorDate = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1))!
    
    let daily = DateComponents(day: 1)
    let query = HKStatisticsCollectionQuery(quantityType: stepType,
                                            quantitySamplePredicate: nil,
                                            options: [.cumulativeSum],
                                            anchorDate: anchorDate,
                                            intervalComponents: daily)
    
    query.initialResultsHandler = { query, results, error in
        if let error = error {
            DispatchQueue.main.async {
                completion(nil, error)
            }
            return
        }
        
        guard let results = results else {
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No results returned"]))
            }
            return
        }
        
        var yearlyData: [Int: DetailedStepData] = [:]
        
        results.enumerateStatistics(from: anchorDate, to: now) { statistics, stop in
            let date = statistics.startDate
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            let weekOfYear = calendar.component(.weekOfYear, from: date)
            
            if let sum = statistics.sumQuantity() {
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                
                if yearlyData[year] == nil {
                    yearlyData[year] = DetailedStepData(id: UUID(), year: year, monthlyData: [], weeklyData: [], dailyData: [])
                }
                
                // Update monthly data
                if let monthIndex = yearlyData[year]?.monthlyData.firstIndex(where: { $0.month == month }) {
                    yearlyData[year]?.monthlyData[monthIndex].totalSteps += steps
                } else {
                    yearlyData[year]?.monthlyData.append(MonthlyStepData(id: UUID(), month: month, totalSteps: steps, averageSteps: Double(steps)))
                }
                
                // Update weekly data
                if let weekIndex = yearlyData[year]?.weeklyData.firstIndex(where: { $0.weekOfYear == weekOfYear }) {
                    yearlyData[year]?.weeklyData[weekIndex].totalSteps += steps
                } else {
                    yearlyData[year]?.weeklyData.append(WeeklyStepData(id: UUID(), weekOfYear: weekOfYear, totalSteps: steps, averageSteps: Double(steps)))
                }
                
                // Add daily data
                yearlyData[year]?.dailyData.append(DailyStepData(id: UUID(), date: date, steps: steps))
            }
        }
        
        // Calculate averages
        for (year, data) in yearlyData {
            for i in 0..<data.monthlyData.count {
                let daysInMonth = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: year, month: data.monthlyData[i].month, day: 1))!)!.count
                yearlyData[year]?.monthlyData[i].averageSteps = Double(data.monthlyData[i].totalSteps) / Double(daysInMonth)
            }
            
            for i in 0..<data.weeklyData.count {
                yearlyData[year]?.weeklyData[i].averageSteps = Double(data.weeklyData[i].totalSteps) / 7.0
            }
        }
        
        let detailedStepData = Array(yearlyData.values).sorted { $0.year > $1.year }
        
        DispatchQueue.main.async {
            completion(detailedStepData, nil)
        }
    }
    
    healthStore.execute(query)
}

func getFirstRecordedStep(completion: @escaping (Date?, Error?) -> Void) {
    let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    let predicate = HKQuery.predicateForSamples(withStart: nil, end: Date(), options: .strictEndDate)
    
    let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
        if let error = error {
            DispatchQueue.main.async {
                completion(nil, error)
            }
            return
        }
        
        guard let result = result, let sum = result.sumQuantity() else {
            DispatchQueue.main.async {
                completion(nil, NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No results returned"]))
            }
            return
        }
    
        let startDate = result.startDate
        DispatchQueue.main.async {
            completion(startDate, nil)
        }
    }
    
    healthStore.execute(query)
}
}
