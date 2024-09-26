//
//  ngenartApp.swift
//  ngenart
//
//  Created by Pedro on 8/16/24.
//

import SwiftUI
import BackgroundTasks

@main
struct ngenArtApp: App {
    init() {
        registerFonts()
        // UserManager.shared.resetToDefaults()
    }
    @AppStorage("isOnboarding") private var isOnboarding: Bool = true
    @StateObject private var themeManager = ThemeManager()
    var body: some Scene {
        WindowGroup {
           if isOnboarding {
                OnboardingView(isOnboarding: $isOnboarding)
                    .environmentObject(themeManager)
            } else {
                ContentView()
                    .environmentObject(themeManager)
            }
        }
    }
    
    private func registerFonts() {
        let fontNames = ["BodoniModa_18pt-Italic", "BodoniModa_18pt-Regular"]
        fontNames.forEach { fontName in
            if let fontURL = Bundle.main.url(forResource: fontName, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
            } else {
                print("Failed to find font file: \(fontName).ttf")
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerBackgroundTasks()
        return true
    }

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.fetchSteps", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let operation = BlockOperation {
//            let genArtView = GenArtView()
//            genArtView.fetchTotalDistanceSince2024()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        task.expirationHandler = {
            queue.cancelAllOperations()
        }
        
        queue.addOperation(operation)
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourapp.fetchSteps")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
}
