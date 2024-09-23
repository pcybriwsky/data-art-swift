import HealthKit
import SwiftUI

class HealthKitManager: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    
    // Check if HealthKit is available on this device
    func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // Request HealthKit authorization
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let readTypes = Set([
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            // Add more types as needed
        ])
        
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            DispatchQueue.main.async {
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
}
