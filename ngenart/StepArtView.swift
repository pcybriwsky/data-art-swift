import SwiftUI
import HealthKit

struct StepArtView: View {
    @State private var stepsThisYear: [Int] = []
    @State private var totalSteps: Int = 0
    @State private var averageStepsPerDay: Int = 0
    @State private var startYear: Int = Calendar.current.component(.year, from: Date())
    @State private var isLoading: Bool = true
    
    let healthStore = HKHealthStore()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    ProgressView()
                } else {
                    CircularStepArtView(steps: stepsThisYear, startDate: Calendar.current.date(from: DateComponents(year: startYear))!)
                        .frame(height: 628)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Steps this year: \(totalSteps)")
                        Text("Steps per day: \(averageStepsPerDay)")
                    }
                    .padding(.horizontal)
                    
                    Text("Step Art")
                        .font(.custom("BodoniModa18pt-Italic", size: 24))
                        .padding(.horizontal)
                    
                    Text("The Step Art visualizes your total steps taken since \(startYear).\nIn order to use this piece, you must share access to your health data.")
                        .font(.system(size: 17))
                        .padding(.horizontal)
                    
                    Text("Customize")
                        .font(.custom("BodoniModa18pt-Italic", size: 24))
                        .padding(.horizontal)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start Year")
                            Picker("Start Year", selection: $startYear) {
                                ForEach(2020...Calendar.current.component(.year, from: Date()), id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .onAppear {
            requestAuthorization()
            fetchStepsData()
        }
        .onChange(of: startYear) { _, _ in
            fetchStepsData()
        }
    }
    
    private func requestAuthorization() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, error in
            if success {
                fetchStepsData()
            } else if let error = error {
                print("Authorization failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func fetchStepsData() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = startYear
        let startDate = calendar.date(from: components)!
        let endDate = min(Date(), calendar.date(byAdding: .year, value: 1, to: startDate)!)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(quantityType: stepType,
                                                quantitySamplePredicate: predicate,
                                                options: .cumulativeSum,
                                                anchorDate: startDate,
                                                intervalComponents: DateComponents(day: 1))
        
        query.initialResultsHandler = { query, results, error in
            guard let results = results else {
                print("Failed to fetch steps: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            var steps: [Int] = Array(repeating: 0, count: 365)
            var total = 0
            var daysWithData = 0
            
            results.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                if let sum = statistics.sumQuantity() {
                    let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                    let dayIndex = calendar.dateComponents([.day], from: startDate, to: statistics.startDate).day!
                    if dayIndex < 365 {
                        steps[dayIndex] = stepCount
                        total += stepCount
                        daysWithData += 1
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.stepsThisYear = steps
                self.totalSteps = total
                self.averageStepsPerDay = daysWithData > 0 ? total / daysWithData : 0
                self.isLoading = false
            }
        }
        
        healthStore.execute(query)
    }
}

struct CircularStepArtView: View {
    let steps: [Int] // Array of steps for each day of the year
    let startDate: Date
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let ringOffset: CGFloat = 15.0 // Size of the opening in the center
                
                // Draw the lines for each day
                ForEach(0..<steps.count, id: \.self) { index in
                    let angleDegrees = Double(index) / Double(steps.count) * 360 - 90
                    let angle = Angle(degrees: angleDegrees)
                    
                    // Calculate length and ensure it's non-negative
                    let calculatedLength = normalizedLength(for: steps[index], in: geometry)
                    let length: CGFloat = max(calculatedLength, ringOffset) // Ensure length is non-negative
                    
                    // Calculate the end point of the line
                    let endX = cos(angle.radians) * length
                    let endY = sin(angle.radians) * length
                    
                    // Calculate the starting point
                    let startX = geometry.size.width / 2 + ringOffset * cos(angle.radians)
                    let startY = geometry.size.width / 2 + ringOffset * sin(angle.radians)

                    
                    
                    // Draw the line
                    Path { path in
                        path.move(to: CGPoint(x: startX, y: startY))
                        path.addLine(to: CGPoint(x: geometry.size.width / 2 + endX, y: geometry.size.width / 2 + endY))
                    }
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.red]),
                            startPoint: .init(x: 0.5, y: 0.5), // Center of the line
                            endPoint: .init(x: 0.5 + (endX / length) * 0.5, y: 0.5 + (endY / length) * 0.5) // End of the line
                        ),
                        lineWidth: 2
                    )
                }
                
                // Month labels
                ForEach(0..<12, id: \.self) { month in
                    // Adjust the angle to start from the top (0 degrees) and go clockwise
                    let angle = Angle(degrees: Double(month) / 12.0 * 360 - 90) // Offset by 90 degrees
                    
                    let x = cos(angle.radians) * (geometry.size.width / 2 - 30.0)
                    let y = sin(angle.radians) * (geometry.size.width / 2 - 30.0)
                    
                    Text(monthAbbreviation(for: month))
                        .position(x: geometry.size.width / 2 + x, y: geometry.size.width / 2 + y)
                }
            }
        }
        .frame(height: 400)
    }
    
    private func normalizedLength(for stepCount: Int, in geometry: GeometryProxy) -> CGFloat {
        let maxSteps = steps.max() ?? 1
        return (CGFloat(stepCount) / CGFloat(maxSteps)) * (geometry.size.width / 2 - 40) // Adjust for padding
    }
    
    private func gradientColor(for stepCount: Int) -> Color {
        let maxSteps = steps.max() ?? 1
        let ratio = CGFloat(stepCount) / CGFloat(maxSteps)
        return Color.blue.interpolate(to: Color.red, fraction: ratio)
    }
    
    private func monthAbbreviation(for month: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        let date = Calendar.current.date(from: DateComponents(year: 2000, month: month + 1, day: 1))!
        return dateFormatter.string(from: date)
    }
}

extension Color {
    func interpolate(to color: Color, fraction: CGFloat) -> Color {
        let fromComponents = UIColor(self).cgColor.components ?? [0, 0, 0, 0]
        let toComponents = UIColor(color).cgColor.components ?? [0, 0, 0, 0]
        
        let red = fromComponents[0] + (toComponents[0] - fromComponents[0]) * fraction
        let green = fromComponents[1] + (toComponents[1] - fromComponents[1]) * fraction
        let blue = fromComponents[2] + (toComponents[2] - fromComponents[2]) * fraction
        let alpha = fromComponents[3] + (toComponents[3] - fromComponents[3]) * fraction
        
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
