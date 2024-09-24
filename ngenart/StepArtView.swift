import SwiftUI
import HealthKit
import WidgetKit

@available(iOS 16.0, *)
public struct StepArtView: View {
    @State private var totalSteps: Int = 0
    @State private var startYear: Int = UserManager.shared.stepStartYear
    @State private var earliestYear: Int = Calendar.current.component(.year, from: Date())
    @State private var isLoading: Bool = true
    @State private var stepGoal: Int = UserManager.shared.stepGoal
    
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
                        MainAppStepView(steps: totalSteps, startYear: startYear, stepGoal: stepGoal)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .frame(height: 170, alignment: .topLeading)
                            .background(Color(hex: 0xf6f6f6))
                            .cornerRadius(8)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Step Art")
                                .font(.custom("BodoniModa18pt-Italic", size: 24))
                                .padding(8)
                            ScrollView(.vertical, showsIndicators: true) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("The Step Art visualizes your total steps taken since \(String(format: "%d", startYear)).\nIn order to use this piece, you must share access to your health data.")
                                        .font(.system(size: 17))
                                        .padding(8)
                                    Text("Customize")
                                        .font(.custom("BodoniModa18pt-Italic", size: 24))
                                        .padding(8)
                                    HStack(alignment: .top, spacing: 0) {
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
                                        
                                        VStack(spacing: 8) {
                                            Text("Step Goal")
                                                .font(.system(size: 17))
                                            TextField("Step Goal", value: $stepGoal, formatter: NumberFormatter())
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                                .keyboardType(.numberPad)
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
            print("StepArtView appeared")
            requestAuthorization()
            fetchEarliestRecordedYear()
            fetchTotalStepsSince2024()
        }
        .onChange(of: startYear) { oldValue, newValue in
            print("startYear changed in view from \(oldValue) to \(newValue)")
            UserManager.shared.stepStartYear = newValue
            fetchTotalStepsSince2024()
            refreshWidget()
        }
        .onChange(of: stepGoal) { oldValue, newValue in
            print("stepGoal changed from \(oldValue) to \(newValue)")
            UserManager.shared.stepGoal = newValue
            refreshWidget()
        }
    }

    private func refreshWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    func requestAuthorization() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let typesToRead: Set = [stepType]

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            if success {
                print("HealthKit Authorization Success")
            } else {
                print("HealthKit Authorization Failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func fetchEarliestRecordedYear() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let query = HKSampleQuery(sampleType: stepType, predicate: nil, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { _, samples, error in
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

    func fetchTotalStepsSince2024() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        var components = DateComponents()
        components.year = startYear
        components.month = 1
        components.day = 1
        let startDate = Calendar.current.date(from: components)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                guard let result = result, let sum = result.sumQuantity() else {
                    print("Failed to fetch steps: \(error?.localizedDescription ?? "Unknown error")")
                    self.isLoading = false
                    return
                }
                
                self.totalSteps = Int(sum.doubleValue(for: HKUnit.count()))
                print("Total Steps Since \(startYear): \(self.totalSteps)")
                self.isLoading = false
            }
        }

        healthStore.execute(query)
    }
}

public struct MainAppStepView: View {
    let steps: Int
    let startYear: Int
    let stepGoal: Int
    @State private var animationCompletion: Double = 0
    @State private var stepImage: UIImage?
    
    public var body: some View {
        Group {
            if let image = stepImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            updateStepImage()
        }
        .onChange(of: steps) { oldValue, newValue in
            updateStepImage()
        }
        .onChange(of: startYear) { oldValue, newValue in
            updateStepImage()
        }
        .onChange(of: stepGoal) { oldValue, newValue in
            updateStepImage()
        }
    }
    
    private func updateStepImage() {
        withAnimation(.easeOut(duration: 2)) {
            animationCompletion = 1
        }
        stepImage = StepArtRenderer.renderStepArt(
            steps: steps,
            goal: stepGoal,
            size: CGSize(width: 338, height: 158),
            year: startYear
        )
    }
}