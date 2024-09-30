import HealthKit
import SwiftUI

class HealthKitManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var isAuthorized: Bool = false
    // Check if HealthKit is available on this device
    func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }

    func checkAuthorizationStatus() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let status = healthStore.authorizationStatus(for: stepType)
        DispatchQueue.main.async {
            self.isAuthorized = (status == .sharingAuthorized)
        }
    }
    
    // Request HealthKit authorization
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let readTypes = Set([
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            // Add more types as needed
        ])
        
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                completion(success, error)
            }
        }
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

}
