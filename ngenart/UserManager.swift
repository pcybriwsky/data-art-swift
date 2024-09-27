import Foundation
import CoreMotion

class UserManager {
    static let shared = UserManager()
    
    private let defaults: UserDefaults
    private let suiteName = "group.com.ngenart.genart"


    
    private init() {
        if let sharedDefaults = UserDefaults(suiteName: suiteName) {
            self.defaults = sharedDefaults
            print("Successfully initialized UserDefaults with suite name: \(suiteName)")
        } else {
            print("Failed to initialize shared UserDefaults. Falling back to standard UserDefaults.")
            self.defaults = UserDefaults.standard
        }
        
        setDefaultValuesIfNeeded()
    }
    
    private func setDefaultValuesIfNeeded() {
        if defaults.object(forKey: "useImperialUnits") == nil {
            defaults.set(true, forKey: "useImperialUnits")
            // print("Set default value for useImperialUnits: true")
        }
        if defaults.object(forKey: "startYear") == nil {
            let currentYear = Calendar.current.component(.year, from: Date())
            defaults.set(currentYear, forKey: "startYear")
            // print("Set default value for startYear: \(currentYear)")
        }
        if defaults.object(forKey: "endYear") == nil {
            defaults.set(2024, forKey: "endYear")
            // print("Set default value for endYear: 2024")
        }
        verifyValues()
    }
    
    private func verifyValues() {
        print("Verification - useImperialUnits: \(defaults.bool(forKey: "useImperialUnits"))")
        print("Verification - startYear: \(defaults.integer(forKey: "startYear"))")
    }
    
    var useImperialUnits: Bool {
        get {
            let value = defaults.bool(forKey: "useImperialUnits")
            print("Retrieved useImperialUnits: \(value)")
            return value
        }
        set {
            print("Attempting to set useImperialUnits to: \(newValue)")
            defaults.set(newValue, forKey: "useImperialUnits")
            verifyValues()
        }
    }
    
    var startYear: Int {
        get {
            let value = defaults.integer(forKey: "startYear")
            print("Retrieved startYear: \(value)")
            return value
        }
        set {
            print("Attempting to set startYear to: \(newValue)")
            defaults.set(newValue, forKey: "startYear")
            verifyValues()
        }
    }
    
    var endYear: Int {
        get {
            let value = defaults.integer(forKey: "endYear")
            print("Retrieved endYear: \(value)")
            return value
        }
        set {
            print("Attempting to set endYear to: \(newValue)")
            defaults.set(newValue, forKey: "endYear")
            verifyValues()
        }
    }
    
    func resetToDefaults() {
        print("Resetting to default values")
        defaults.removeObject(forKey: "useImperialUnits")
        defaults.removeObject(forKey: "startYear")
        defaults.removeObject(forKey: "endYear")
        setDefaultValuesIfNeeded()
    }
}
