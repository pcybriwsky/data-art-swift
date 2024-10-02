import SwiftUI
import HealthKit
import WebKit
import UniformTypeIdentifiers


struct StepArtView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var stepsThisYear: [Int] = []
    @State private var totalSteps: Int = 0
    @State private var averageStepsPerDay: Int = 0
    @State private var startYear: Int = Calendar.current.component(.year, from: Date())
    @State private var isLoading: Bool = true
    @State private var webViewImage: UIImage?
    @State private var isCapturingImage: Bool = false
    @State private var hasCapturedImage: Bool = false
    @State private var webViewLoaded: Bool = false
    @State private var yearlyStepData: [HealthKitManager.YearlyStepData] = []
    @State private var detailedStepData: [HealthKitManager.DetailedStepData] = []
    @State private var errorMessage: String?
    @State private var consoleLog: String = ""
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "tester"    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var pieceTitle: String = "Step Ticker"
    @State private var shouldCaptureImage: Bool = false
    @State private var captureTimer: Timer?
    
    
    


    enum TimeRange: String, CaseIterable {
        case week = "1W"
        case month = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case yearToDate = "YTD"
        case oneYear = "1Y"
        case fiveYears = "5Y"
        case allTime = "Max"
    }

    
    let healthStore = HKHealthStore()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if isLoading {
                    ProgressView()
                } else {
                     VStack {
                         P5WebView(htmlString: p5Sketch, onWebViewLoaded: { webView in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.webViewLoaded = true    
                            }
                        })
                        .frame(height: 428)
                        .id(totalSteps)
                        .cornerRadius(12)

                        HStack {
                            Picker("Time Range", selection: $selectedTimeRange) {
                                ForEach(availableTimeRanges, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                        }

                        if isCapturingImage {
                            ProgressView("Capturing image...")
                        } else if webViewImage != nil {
                            ShareLink(item: Image(uiImage: webViewImage!), preview: SharePreview("My Step Art", image: Image(uiImage: webViewImage!))) {
                                Text("Share \(pieceTitle)")
                            }
                            .foregroundColor(Color(hex: 0xfffef7))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(hex: 0xFF5733))
                            .cornerRadius(8)
                            .shadow(radius: 5)
                        }

                    }
                    
                    .padding(.horizontal)
                    
                    
                    Text("\(pieceTitle)")
                        .font(.custom("BodoniModa18pt-Italic", size: 24))
                        .padding(.horizontal)
                    
                    Text("The \(pieceTitle) visualizes your total steps...")
                        .font(.system(size: 17))
                        .padding(.horizontal)

                    Text("Data Input")
                                .font(.custom("BodoniModa18pt-Italic", size: 17))
                                .padding(.horizontal)

                        VStack {
                            VStack(alignment: .center, spacing: 8) {
                                Image(systemName: "figure.walk")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 48, height: 48)  // Increased size to 48x48
                                    .foregroundColor(Color(hex: 0x0a0a0a))  // Changed color to the red accent color
                                    .padding(8)
                                Text("Step Data")
                                    .font(.system(size: 17))
                                    .padding(8)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    
                    // Text("Customize")
                    //     .font(.custom("BodoniModa18pt-Italic", size: 24))
                    //     .padding(.horizontal)
                    
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .onAppear {
            // startPeriodicCapture()
            requestAuthorization()
            fetchStepsData()
            fetchYearlyStepData()
            fetchDetailedStepData()
        }
       .onChange(of: startYear) { _, _ in
            fetchStepsData()
            hasCapturedImage = false
            webViewLoaded = false
        }
        .onChange(of: webViewLoaded) { _, newValue in
            if newValue && !hasCapturedImage {
                captureWebViewImage()
            }
        }
        .onChange(of: selectedTimeRange) { _, _ in
            hasCapturedImage = false
            webViewLoaded = false
        }
    }

     private func startPeriodicCapture() {
        captureTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            captureWebViewImage()
        }
    }

    private func stopPeriodicCapture() {
        captureTimer?.invalidate()
        captureTimer = nil
    }


    private func captureWebViewImage() {
        guard let window = UIApplication.shared.windows.first,
              let webView = window.viewWithTag(100) as? WKWebView else {
            print("Failed to find WebView")
            return
        }
        
        isCapturingImage = true
        let config = WKSnapshotConfiguration()
        config.rect = webView.bounds

        webView.takeSnapshot(with: config) { image, error in
            DispatchQueue.main.async {
                self.isCapturingImage = false
                if let image = image {
                    self.webViewImage = image
                    self.hasCapturedImage = true
                    print("WebView image captured successfully")
                } else if let error = error {
                    print("Failed to capture WebView image: \(error.localizedDescription)")
                }
            }
        }
    }

    var availableTimeRanges: [TimeRange] {
        let allRanges = TimeRange.allCases
        let dataStartDate = detailedStepData.last?.dailyData.first?.date ?? Date()
        let daysSinceStart = Calendar.current.dateComponents([.day], from: dataStartDate, to: Date()).day ?? 0

        return allRanges.filter { range in
            switch range {
            case .week: return daysSinceStart >= 7
            case .month: return daysSinceStart >= 30
            case .threeMonths: return daysSinceStart >= 90
            case .sixMonths: return daysSinceStart >= 180
            case .yearToDate, .oneYear: return daysSinceStart >= 365
            case .fiveYears: return daysSinceStart >= 1825
            case .allTime: return true
            }
        }
    }

    private func requestAuthorization() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, error in
            if success {
                fetchStepsData()
                fetchYearlyStepData()
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

    private func fetchYearlyStepData() {
        healthKitManager.fetchYearlyStepData { data, error in
            isLoading = false
            if let data = data {
                self.yearlyStepData = data
            } else if let error = error {
                self.errorMessage = "Error: \(error.localizedDescription)"
            }
        }
    }

    private func fetchDetailedStepData() {
        healthKitManager.fetchDetailedStepData { data, error in
            isLoading = false
            if let data = data {
                self.detailedStepData = data
            } else if let error = error {
                self.errorMessage = "Error: \(error.localizedDescription)"
            }
        }
    }

   var p5Sketch: String {
    let fontBase64 = Bundle.main.readFileAsBase64("BodoniModa18pt-Italic.ttf") ?? ""
    let imageBase64 = Bundle.main.readFileAsBase64("favicon-32x32.png") ?? ""
    let detailedStepDataJSON = detailedStepData.p5JSONEncoder()

    return """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.4.0/p5.js"></script>
        <style>
            @font-face {
                font-family: 'CustomFont';
                src: url(data:font/truetype;charset=utf-8;base64,\(fontBase64)) format('truetype');
            }
            body { font-family: 'CustomFont', sans-serif; }
        </style>
    </head>
    <body style="margin:0; padding:0;">
        <script>
            let detailedStepData = \(detailedStepDataJSON);
            let selectedTimeRange = '\(selectedTimeRange.rawValue)';
            let userName = '\(userName)';

            function getRoundedBoundaries(min, max) {
                let range = max - min;
                let padding = range * 0.1; // 10% padding
                
                if (range < 10) {
                    return [Math.floor(min), Math.ceil(max)];
                }
                
                let lowerBound, upperBound;
                
                if (range < 100) {
                    lowerBound = Math.floor((min - padding) / 10) * 10;
                    upperBound = Math.ceil((max + padding) / 10) * 10;
                } else if (range < 1000) {
                    lowerBound = Math.floor((min - padding) / 50) * 50;
                    upperBound = Math.ceil((max + padding) / 50) * 50;
                } else if (range < 10000) {
                    lowerBound = Math.floor((min - padding) / 100) * 100;
                    upperBound = Math.ceil((max + padding) / 100) * 100;
                } else {
                    lowerBound = Math.floor((min - padding) / 1000) * 1000;
                    upperBound = Math.ceil((max + padding) / 1000) * 1000;
                }
                
                return [lowerBound, upperBound];
            }

            function setup() {
                createCanvas(windowWidth, windowHeight);
                textAlign(CENTER, CENTER);
                textSize(12);
                noLoop();
            }

            function draw() {
                background(24);
                let padding = 50;
                let graphWidth = width - 2 * padding;
                let graphHeight = 2 * padding;
                
                let filteredData = filterDataByTimeRange(detailedStepData, selectedTimeRange);
                let rawData = flattenDailyData(detailedStepData);

                let maxSteps = Math.max(...filteredData.map(d => d.steps));
                let minSteps = Math.min(...filteredData.map(d => d.steps));
                let oneDayHigh = Math.max(...rawData.map(d => d.steps));
                let oneDayLow = Math.min(...rawData.map(d => d.steps));
                let averageSteps = Math.round(filteredData.reduce((sum, d) => sum + d.steps, 0) / filteredData.length);
                totalSteps = calculateTotalSteps(rawData, selectedTimeRange);
                
                let [lowerBound, upperBound] = getRoundedBoundaries(minSteps, maxSteps);
                
                // Draw axes
                stroke(221);
                line(padding, height - padding, width - padding, height - padding); // x-axis
                line(padding, graphHeight, padding, height - padding); // y-axis
                
                // Plot data
                noFill();
                stroke("#39743E");
                beginShape();
                for (let i = 0; i < filteredData.length; i++) {
                    let x = map(i, 0, filteredData.length - 1, padding, width - padding);
                    let y = map(filteredData[i].steps, lowerBound, upperBound, height - padding, graphHeight);
                    vertex(x, y);
                    
                    // Draw data point
                    fill("#39743E");
                    ellipse(x, y, 5, 5);
                    noFill();
                }
                endShape();
                
                // Add labels
                fill(221);
                noStroke();
                textAlign(LEFT, CENTER);
                text("Time", width - padding, height - padding);
                
                // Add "Steps" label at the top of y-axis, right-aligned
                textAlign(RIGHT, TOP);
                text("Steps", padding - 5, graphHeight - 20);
                
                // Add tick marks and labels on the right y-axis
                textAlign(RIGHT, CENTER);
                for (let i = 0; i <= 5; i++) {
                    let y = map(i, 0, 5, height - padding, graphHeight);
                    let stepValue = Math.round(map(i, 0, 5, lowerBound, upperBound));
                    line(padding, y, padding - 5, y);
                    text(stepValue.toLocaleString(), padding - 5, y);
                }
                
                // Add title
                textAlign(RIGHT, CENTER);
                let aggregationType = 'Daily ';
                let calculationType = '';
                if (['3M', '6M', 'YTD', '1Y'].includes(selectedTimeRange)) {
                    aggregationType = 'Weekly ';
                    calculationType = 'Average ';
                } else if (['5Y', 'Max'].includes(selectedTimeRange)) {
                    aggregationType = 'Monthly ';
                    calculationType = 'Average ';
                }
                let lineHeight = 18;
                textSize(14);
                text(userName + "'s " + aggregationType + "Step Ticker", width - lineHeight, lineHeight);
                textSize(12);
                text("Total: " + totalSteps.toLocaleString() + " steps", width - lineHeight, lineHeight*2);
                text("One-day High: " + oneDayHigh.toLocaleString() + " steps", width - lineHeight, lineHeight*3);
                text("One-day Low: " + oneDayLow.toLocaleString() + " steps", width - lineHeight, lineHeight*4);
                text("Average: " + averageSteps.toLocaleString() + " steps", width - lineHeight, lineHeight*5);

                
                // Add start and end dates
                textSize(12);
                if (filteredData.length > 0) {
                    textAlign(LEFT, TOP);
                    text(formatDate(filteredData[0].date), padding, height - padding + 5);
                    textAlign(RIGHT, TOP);
                    text(formatDate(filteredData[filteredData.length - 1].date), width - padding, height - padding + 5);
                }
            }

            function calculateTotalSteps(data, range) {
                let endDate = new Date();
                let startDate = new Date(endDate);
                
                switch (range) {
                    case '1W': startDate.setDate(endDate.getDate() - 7); break;
                    case '1M': startDate.setMonth(endDate.getMonth() - 1); break;
                    case '3M': startDate.setMonth(endDate.getMonth() - 3); break;
                    case '6M': startDate.setMonth(endDate.getMonth() - 6); break;
                    case 'YTD': startDate = new Date(endDate.getFullYear(), 0, 1); break;
                    case '1Y': startDate.setFullYear(endDate.getFullYear() - 1); break;
                    case '5Y': startDate.setFullYear(endDate.getFullYear() - 5); break;
                    case 'Max': return data.reduce((sum, d) => sum + d.steps, 0);
                }
                
                return data
                    .filter(day => new Date(day.date) >= startDate && new Date(day.date) <= endDate)
                    .reduce((sum, d) => sum + d.steps, 0);
            }

            function filterDataByTimeRange(data, range) {
                let endDate = new Date();
                let startDate = new Date(endDate);
                
                switch (range) {
                    case '1W': startDate.setDate(endDate.getDate() - 7); break;
                    case '1M': startDate.setMonth(endDate.getMonth() - 1); break;
                    case '3M': startDate.setMonth(endDate.getMonth() - 3); break;
                    case '6M': startDate.setMonth(endDate.getMonth() - 6); break;
                    case 'YTD': startDate = new Date(endDate.getFullYear(), 0, 1); break;
                    case '1Y': startDate.setFullYear(endDate.getFullYear() - 1); break;
                    case '5Y': startDate.setFullYear(endDate.getFullYear() - 5); break;
                    case 'Max': return aggregateDataByMonth(flattenDailyData(data));
                }
                
                let filteredData = flattenDailyData(data).filter(day => new Date(day.date) >= startDate && new Date(day.date) <= endDate);
                
                if (['3M', '6M', 'YTD', '1Y'].includes(range)) {
                    return aggregateDataByWeek(filteredData);
                } else if (['5Y', 'Max'].includes(range)) {
                    return aggregateDataByMonth(filteredData);
                }
                
                return filteredData;
            }

            function aggregateDataByWeek(data) {
                let weeklyData = [];
                let currentWeek = [];
                let currentWeekStart = new Date(data[0].date);
                currentWeekStart.setDate(currentWeekStart.getDate() - currentWeekStart.getDay()); // Set to start of week (Sunday)

                for (let day of data) {
                    let dayDate = new Date(day.date);
                    if (dayDate >= currentWeekStart && dayDate < new Date(currentWeekStart.getTime() + 7 * 24 * 60 * 60 * 1000)) {
                        currentWeek.push(day);
                    } else {
                        if (currentWeek.length > 0) {
                            let avgSteps = Math.round(currentWeek.reduce((sum, day) => sum + day.steps, 0) / currentWeek.length);
                            weeklyData.push({ date: currentWeekStart.toISOString(), steps: avgSteps });
                        }
                        currentWeekStart = new Date(dayDate.getTime());
                        currentWeekStart.setDate(currentWeekStart.getDate() - currentWeekStart.getDay());
                        currentWeek = [day];
                    }
                }
                
                // Add the last week if it's not empty
                if (currentWeek.length > 0) {
                    let avgSteps = Math.round(currentWeek.reduce((sum, day) => sum + day.steps, 0) / currentWeek.length);
                    weeklyData.push({ date: currentWeekStart.toISOString(), steps: avgSteps });
                }

                return weeklyData;
            }

            function aggregateDataByMonth(data) {
                let monthlyData = [];
                let currentMonth = [];
                let currentMonthStart = new Date(data[0].date);
                currentMonthStart.setDate(1); // Set to start of month

                for (let day of data) {
                    let dayDate = new Date(day.date);
                    if (dayDate.getFullYear() === currentMonthStart.getFullYear() && dayDate.getMonth() === currentMonthStart.getMonth()) {
                        currentMonth.push(day);
                    } else {
                        if (currentMonth.length > 0) {
                            let avgSteps = Math.round(currentMonth.reduce((sum, day) => sum + day.steps, 0) / currentMonth.length);
                            monthlyData.push({ date: currentMonthStart.toISOString(), steps: avgSteps });
                        }
                        currentMonthStart = new Date(dayDate.getFullYear(), dayDate.getMonth(), 1);
                        currentMonth = [day];
                    }
                }
                
                // Add the last month if it's not empty
                if (currentMonth.length > 0) {
                    let avgSteps = Math.round(currentMonth.reduce((sum, day) => sum + day.steps, 0) / currentMonth.length);
                    monthlyData.push({ date: currentMonthStart.toISOString(), steps: avgSteps });
                }

                return monthlyData;
            }

            function flattenDailyData(data) {
                return data.flatMap(yearData => yearData.dailyData)
                        .sort((a, b) => new Date(a.date) - new Date(b.date));
            }

            function formatDate(dateString) {
                let date = new Date(dateString);
                return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
            }

            function windowResized() {
                resizeCanvas(windowWidth, windowHeight);
                redraw();
            }
        </script>
    </body>
    </html>
    """
}
}
