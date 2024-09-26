import SwiftUI
import HealthKit
import WidgetKit

@available(iOS 16.0, *)
public struct GenArtView: View {
    @State private var totalDistance: Double = 0
    @State private var useImperialUnits: Bool = UserManager.shared.useImperialUnits
    @State private var startYear: Int = UserManager.shared.startYear
    @State private var earliestYear: Int = Calendar.current.component(.year, from: Date())
    @State private var isLoading: Bool = true
    @State private var odometerImage: UIImage?
    
    let healthStore = HKHealthStore()

    public var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: 0x333333)))
            } else {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 16) {
                        MainAppOdometerView(distance: totalDistance, useImperialUnits: useImperialUnits, startYear: startYear)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .frame(height: 170, alignment: .topLeading)
                            .background(Color(hex: 0xf6f6f6))
                            .cornerRadius(8)
                            .onChange(of: totalDistance) { oldValue, newValue in
                                Task { @MainActor in
                                    captureOdometerImage()
                                }
                            }
                        
                        if let image = odometerImage {
                            ShareLink(item: Image(uiImage: image), preview: SharePreview("My Odometer", image: Image(uiImage: image))) {
                                Text("Share Odometer")
                            }
                            .padding()
                        } else {
                            Text("Odometer image not available")
                                .foregroundColor(.red)
                                .padding()
                        }
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
                                                ForEach(earliestYear...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                                                    Text(String(year)).tag(year)
                                                }
                                            }
                                            .pickerStyle(MenuPickerStyle())
                                        }
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .frame(height: 100, alignment: .center)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(hex: 0xfffef7))
                    .padding(1)
                    .offset(y: 72)
                }
                .frame(maxWidth: UIScreen.main.bounds.width, alignment: .topLeading)
                .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .onAppear {
            print("GenArtView appeared")
            print("UserManager values - startYear: \(UserManager.shared.startYear), useImperialUnits: \(UserManager.shared.useImperialUnits)")
            print("GenArtView @State values - startYear: \(startYear), useImperialUnits: \(useImperialUnits)")
            
            // Check if values are different and update if necessary
            if startYear != UserManager.shared.startYear {
                print("Updating startYear to match UserManager")
                startYear = UserManager.shared.startYear
            }
            if useImperialUnits != UserManager.shared.useImperialUnits {
                print("Updating useImperialUnits to match UserManager")
                useImperialUnits = UserManager.shared.useImperialUnits
            }
            
            requestAuthorization()
            fetchEarliestRecordedYear()
            fetchTotalDistanceSince2024()
            Task { @MainActor in
                captureOdometerImage()
            }
        }
        .onChange(of: useImperialUnits) { oldValue, newValue in
            print("useImperialUnits changed from \(oldValue) to \(newValue)")
            UserManager.shared.useImperialUnits = newValue
            fetchTotalDistanceSince2024()
            refreshWidget()
        }
        .onChange(of: startYear) { oldValue, newValue in
            print("startYear changed in view from \(oldValue) to \(newValue)")
            UserManager.shared.startYear = newValue
            print("UserManager startYear after change: \(UserManager.shared.startYear)")
            fetchTotalDistanceSince2024()
            refreshWidget()
        }
        .onChange(of: totalDistance) { oldValue, newValue in
            print("Total distance changed from \(oldValue) to \(newValue)")
            Task { @MainActor in
                captureOdometerImage()
            }
        }
    }

    @MainActor
    private func captureOdometerImage() {
        if totalDistance == 0 {
            print("Total distance is 0, skipping image capture")
            return
        }
        
        let renderer = ImageRenderer(content: MainAppOdometerView(distance: totalDistance, useImperialUnits: useImperialUnits, startYear: startYear))
        
        // Increase the scale factor to 10x
         renderer.scale = 16.0 * UIScreen.main.scale
    
    // Set the proposedSize to 16x the original size
    renderer.proposedSize = ProposedViewSize(width: 5408, height: 2528) // 16x the original size
    
        
        if let uiImage = renderer.uiImage {
            // Convert to lossless PNG format
            if let pngData = uiImage.pngData(), let pngImage = UIImage(data: pngData) {
                self.odometerImage = pngImage
                print("Image captured successfully in PNG format at 10x resolution")
            } else {
                print("Failed to convert image to PNG")
            }
        } else {
            print("Failed to capture image")
        }
    }

     private func refreshWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    func requestAuthorization() {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let typesToRead: Set = [distanceType]

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            if success {
                print("HealthKit Authorization Success")
            } else {
                print("HealthKit Authorization Failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func fetchEarliestRecordedYear() {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        
        let query = HKSampleQuery(sampleType: distanceType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, error in
            DispatchQueue.main.async {
                guard let earliestSample = samples?.first as? HKQuantitySample else {
                    print("Failed to fetch earliest sample: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let year = Calendar.current.component(.year, from: earliestSample.startDate)
                self.earliestYear = year
            }
        }
        
        healthStore.execute(query)
    }

    func fetchTotalDistanceSince2024() {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        
        var components = DateComponents()
        components.year = startYear
        components.month = 1
        components.day = 1
        let startDate = Calendar.current.date(from: components)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                guard let result = result, let sum = result.sumQuantity() else {
                    print("Failed to fetch distance: \(error?.localizedDescription ?? "Unknown error")")
                    self.isLoading = false
                    return
                }
                
                let distance = sum.doubleValue(for: useImperialUnits ? HKUnit.mile() : HKUnit.meter())
                self.totalDistance = useImperialUnits ? distance : distance / 1000 // Convert meters to kilometers
                print("Total Distance Since \(startYear): \(self.totalDistance) \(useImperialUnits ? "miles" : "kilometers")")
                self.isLoading = false
            }
        }

        healthStore.execute(query)
    }
}

public struct MainAppOdometerView: View {
    let distance: Double
    let useImperialUnits: Bool
    let startYear: Int
    @State private var animationCompletion: Double = 0
    @State private var odometerImage: UIImage?
    
    public var body: some View {
        Group {
            if let image = odometerImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            updateOdometerImage()
        }
        .onChange(of: distance) { oldValue, newValue in
            updateOdometerImage()
        }
        .onChange(of: useImperialUnits) { oldValue, newValue in
            updateOdometerImage()
        }
        .onChange(of: startYear) { oldValue, newValue in
            updateOdometerImage()
        }
    }
    
    private func updateOdometerImage() {
        withAnimation(.easeOut(duration: 2)) {
            animationCompletion = 1
        }
        odometerImage = StepArtRenderer.renderOdometer(
            distance: distance,
            unit: useImperialUnits ? "miles" : "km",
            size: CGSize(width: 338, height: 158),
            year: startYear
        )
    }
}

public struct Switch1: View {
    @State private var toggleIsOn_r8s = true
    public var body: some View {
        Toggle("", isOn: $toggleIsOn_r8s).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .green))
    }
}

#Preview {
    GenArtView()
}
