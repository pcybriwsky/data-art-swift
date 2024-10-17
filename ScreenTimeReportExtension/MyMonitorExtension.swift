import DeviceActivity
import ManagedSettings

class MyMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // You can add any specific actions you want to perform when the interval starts
        print("Interval started for activity: \(activity)")
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // You can add any specific actions you want to perform when the interval ends
        print("Interval ended for activity: \(activity)")
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name,
                                         activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        // This is where you can implement your logic when an event reaches its threshold
        print("Event \(event) reached threshold for activity: \(activity)")
        
        // Example: Disable all applications when the threshold is reached
        store.shield.applications = nil
    }
}
