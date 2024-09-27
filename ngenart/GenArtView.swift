import SwiftUI
import HealthKit
import WidgetKit

@available(iOS 16.0, *)
public struct GenArtView: View {
    @State private var totalDistance: Double = 0
    @State private var useImperialUnits: Bool = UserManager.shared.useImperialUnits
    @State private var startYear: Int = UserManager.shared.startYear
    @State private var endYear: Int = UserManager.shared.endYear
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
                    VStack(alignment: .leading, spacing: 8) {
                        StepArtRenderer.animatedOdometer(
                distance: totalDistance,
                unit: useImperialUnits ? "miles" : "km",
                size: CGSize(width: 338, height: 158),
                year: startYear,
                endYear: endYear
            )
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .cornerRadius(8)
                        .onChange(of: totalDistance) { oldValue, newValue in
                            Task { @MainActor in
                                captureOdometerImage()
                            }
                        }
                        
                        if let image = odometerImage {
                            ZStack {
                                ShareLink(item: Image(uiImage: image), preview: SharePreview("My Odometer", image: Image(uiImage: image))) {
                                Text("Share Odometer")
                                }
                                .foregroundColor(Color(hex: 0xfffef7))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color(hex: 0xFF5733))
                                .cornerRadius(8)
                                .shadow(radius: 5)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                        } else {
                        Text("Odometer image not available")
                                .foregroundColor(.red)
                                .padding()
                        }
                        ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Odometer")
                                .font(.custom("BodoniModa18pt-Italic", size: 24))
                                Text("A data art piece that visualizes your total \(useImperialUnits ? "miles" : "kilometers") traveled on foot over time.")
                                    .font(.system(size: 17))
                            Text("Data Input")
                                .font(.custom("BodoniModa18pt-Italic", size: 17))

                           VStack {
                            VStack(alignment: .center, spacing: 8) {
                                Image(systemName: "figure.walk")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 48, height: 48)  // Increased size to 48x48
                                    .foregroundColor(Color(hex: 0xFF5733))  // Changed color to the red accent color
                                    .padding(8)
                                Text("Walking + Running Distance")
                                    .font(.system(size: 17))
                                    .padding(8)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        

                            Text("Units Selection")
                                .font(.custom("BodoniModa18pt-Italic", size: 17))
                            Picker("Units", selection: $useImperialUnits) {
                                Text("Miles").tag(true)
                                Text("Kilometers").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .padding(8)
                            .accentColor(Color(hex: 0xFF5733))
                        
                            HStack(alignment: .top, spacing: 8) {
                                VStack(alignment: .leading) {
                                    Text("Start Year")
                                        .font(.custom("BodoniModa18pt-Italic", size: 17))
                                    Picker("Start Year", selection: $startYear) {
                                        ForEach(earliestYear...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                                            Text(String(year)).tag(year)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 100)
                                    .background(Color(hex: 0xf6f6f6))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                }
                                .padding()
                                VStack(alignment: .leading) {
                                    Text("End Year")
                                        .font(.custom("BodoniModa18pt-Italic", size: 17))
                                    Picker("End Year", selection: $endYear) {
                                        ForEach(startYear...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                                            Text(String(year)).tag(year)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 100)
                                    .background(Color(hex: 0xf6f6f6))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                }
                                .padding()
                                .background(Color(hex: 0xfffef7))
                            }
                            // .frame(maxWidth: 200, height: 200)
                            Spacer(minLength: 100)
                        }
                        }
                    }
                }
            .padding(16)
            .background(Color(hex: 0xfffef7))
            .padding(1)
            .offset(y: 72)
            
            .frame(maxWidth: UIScreen.main.bounds.width, alignment: .topLeading)
            .ignoresSafeArea()
            
            
            }

        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .onAppear {            
            // Check if values are different and update if necessary
            if startYear != UserManager.shared.startYear {
                startYear = UserManager.shared.startYear
            }
            if useImperialUnits != UserManager.shared.useImperialUnits {
                useImperialUnits = UserManager.shared.useImperialUnits
            }
            if endYear != UserManager.shared.endYear {
                endYear = UserManager.shared.endYear
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
            UserManager.shared.startYear = newValue
            if UserManager.shared.startYear >= UserManager.shared.endYear {
                UserManager.shared.endYear = UserManager.shared.startYear
                print("startYear changed in view from \(oldValue) to \(newValue)")
            }
            fetchTotalDistanceSince2024()
            refreshWidget()
        }

        .onChange(of: endYear) { oldValue, newValue in
            print("endYear changed in view from \(oldValue) to \(newValue)")
            UserManager.shared.endYear = newValue
            print("UserManager endYear after change: \(UserManager.shared.endYear)")
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
        
        let renderer = ImageRenderer(content: MainAppOdometerView(distance: totalDistance, useImperialUnits: useImperialUnits, startYear: startYear, endYear: endYear))
        
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

        var endComponents = DateComponents()
        endComponents.year = endYear
        endComponents.month = 12
        endComponents.day = 31
        let endDate = Calendar.current.date(from: endComponents)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
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
    let endYear: Int
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
        .onChange(of: endYear) { oldValue, newValue in
            updateOdometerImage()
        }
    }
    
    private func updateOdometerImage() {
        withAnimation(.easeOut(duration: 2)) {
            animationCompletion = 1
        }
        odometerImage = StepArtRenderer.animateOdometer(
            distance: distance,
            unit: useImperialUnits ? "miles" : "km",
            size: CGSize(width: 338, height: 158),
            year: startYear,
            endYear: endYear
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
