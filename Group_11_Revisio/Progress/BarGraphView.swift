import SwiftUI
import Charts

struct BarChartView: View {
    @ObservedObject var model: StudyChartModel
    let isShowingDaily: Bool
    
    // Track the currently visible page (day or week)
    @State private var scrolledID: Int?

    // MARK: - Computed Properties
    private func getTotalHours(for index: Int) -> String {
        let history = isShowingDaily ? model.dailyHistory : model.weeklyHistory
        guard index >= 0 && index < history.count else { return "0h 0m" }
        
        let totalMinutes = history[index].reduce(0) { $0 + $1.focusMinutes + $1.extraMinutes }
        let h = Int(totalMinutes) / 60
        let m = Int(totalMinutes) % 60
        return "\(h)h \(m)m"
    }
    
    private func getDateLabel(for index: Int) -> String {
        let history = isShowingDaily ? model.dailyHistory : model.weeklyHistory
        guard index >= 0 && index < history.count else { return "" }
        
        let distance = (history.count - 1) - index
        
        if isShowingDaily {
            if distance == 0 { return "Today, \(Date().formatted(.dateTime.day().month(.wide)))" }
            if distance == 1 { return "Yesterday" }
            let date = Calendar.current.date(byAdding: .day, value: -distance, to: Date()) ?? Date()
            return date.formatted(.dateTime.day().month(.wide))
        } else {
            if distance == 0 { return "This Week" }
            if distance == 1 { return "Last Week" }
            if distance == 2 { return "2 Weeks Ago" }
            return "3 Weeks Ago"
        }
    }

    var body: some View {
        let history = isShowingDaily ? model.dailyHistory : model.weeklyHistory
        // Safely determine current index for header text
        let currentIdx = scrolledID ?? (history.count > 0 ? history.count - 1 : 0)
        
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. DYNAMIC HEADER
            VStack(alignment: .leading, spacing: 0) {
                Text(getDateLabel(for: currentIdx))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(getTotalHours(for: currentIdx))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .padding(.horizontal)
            .padding(.top, 2)

            // 2. PAGING CHART AREA
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<history.count, id: \.self) { index in
                        VStack(spacing: 0) {
                            Chart {
                                ForEach(history[index]) { item in
                                    BarMark(
                                        x: .value("Label", item.label),
                                        y: .value("Minutes", item.focusMinutes)
                                    )
                                    .foregroundStyle(Color.blue.gradient)
                                    .cornerRadius(4)
                                }
                            }
                            // Fixed height scale: 8 hours (480 mins)
                            .chartYScale(domain: 0...480)
                            
                            // Y-AXIS: 2h increments
                            .chartYAxis {
                                AxisMarks(position: .trailing, values: [0, 120, 240, 360, 480]) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                                        .foregroundStyle(.gray.opacity(0.3))
                                    
                                    AxisValueLabel {
                                        if let mins = value.as(Int.self) {
                                            Text("\(mins / 60)h")
                                                .font(.system(size: 9))
                                        }
                                    }
                                }
                            }
                            
                            // X-AXIS: Dynamically switch labels based on Daily/Weekly
                            .chartXAxis {
                                let axisValues = isShowingDaily ? ["00", "06", "12", "18"] : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                                
                                AxisMarks(values: axisValues) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                                        .foregroundStyle(.gray.opacity(0.2))
                                    
                                    AxisTick(length: 20, stroke: StrokeStyle(lineWidth: 1))
                                        .foregroundStyle(.gray.opacity(0.2))
                                    
                                    AxisValueLabel(anchor: .topLeading) {
                                        if let label = value.as(String.self) {
                                            Text(label)
                                                .font(.system(size: 10))
                                                .padding(.leading, isShowingDaily ? -10 : -5)
                                                .padding(.top, 2)
                                        }
                                    }
                                }
                            }
                            .frame(height: 150)
                            .padding(.top, -20)
                            .padding(.horizontal)
                        }
                        .containerRelativeFrame(.horizontal) // Forces one day/week per screen width
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrolledID)
            .scrollTargetBehavior(.paging) // Enables the horizontal swipe paging
            .defaultScrollAnchor(.trailing) // Start on "Today" (the last item)
        }
        .onAppear {
            if !history.isEmpty {
                scrolledID = history.count - 1
            }
        }
        // Force scroll to end when switching between Day and Week
        .onChange(of: isShowingDaily) { _ in
            if !history.isEmpty {
                scrolledID = history.count - 1
            }
        }
    }
}//import SwiftUI
//import Charts
//
//struct BarChartView: View {
//    @ObservedObject var model: StudyChartModel
//    let isShowingDaily: Bool
//    
//    @State private var scrolledID: Int?
//
//    // MARK: - Computed Properties
//    private func getTotalHours(for index: Int) -> String {
//        let history = isShowingDaily ? model.dailyHistory : model.weeklyHistory
//        guard index >= 0 && index < history.count else { return "0h 0m" }
//        let totalMinutes = history[index].reduce(0) { $0 + $1.focusMinutes + $1.extraMinutes }
//        let h = Int(totalMinutes) / 60
//        let m = Int(totalMinutes) % 60
//        return "\(h)h \(m)m"
//    }
//
//    private func getDateLabel(for index: Int) -> String {
//        let history = isShowingDaily ? model.dailyHistory : model.weeklyHistory
//        let distance = (history.count - 1) - index
//        if isShowingDaily {
//            if distance == 0 { return "Today, \(Date().formatted(.dateTime.day().month(.wide)))" }
//            if distance == 1 { return "Yesterday" }
//            let date = Calendar.current.date(byAdding: .day, value: -distance, to: Date()) ?? Date()
//            return date.formatted(.dateTime.day().month(.wide))
//        } else {
//            return distance == 0 ? "This Week" : "Last Week"
//        }
//    }
//
//    var body: some View {
//        let history = isShowingDaily ? model.dailyHistory : model.weeklyHistory
//        let currentIdx = scrolledID ?? (history.count - 1)
//        
//        VStack(alignment: .leading, spacing: 0) {
//            
//            // 1. COMPACT HEADER
//            VStack(alignment: .leading, spacing: 0) {
//                Text(getDateLabel(for: currentIdx))
//                    .font(.system(size: 15, weight: .medium))
//                    .foregroundColor(.secondary)
//                
//                Text(getTotalHours(for: currentIdx))
//                    .font(.system(size: 22, weight: .bold, design: .rounded))
//            }
//            .padding(.horizontal)
//            .padding(.top, 2)
//
//            // 2. CHART AREA
//            ScrollView(.horizontal, showsIndicators: false) {
//                LazyHStack(spacing: 0) {
//                    ForEach(0..<history.count, id: \.self) { index in
//                        VStack(spacing: 0) {
//                            Chart {
//                                ForEach(history[index]) { item in
//                                    BarMark(
//                                        x: .value("Time of Day", item.label),
//                                        y: .value("Minutes", item.focusMinutes)
//                                    )
//                                    .foregroundStyle(Color.blue.gradient)
//                                    .cornerRadius(4)
//                                }
//                            }
//                            .chartYScale(domain: 0...480)
//                            
//                            // Y-AXIS: Horizontal Grid Lines
//                            .chartYAxis {
//                                AxisMarks(position: .trailing, values: [0, 120, 240, 360, 480]) { value in
//                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
//                                        .foregroundStyle(.gray.opacity(0.3))
//                                    
//                                    AxisValueLabel {
//                                        if let mins = value.as(Int.self) {
//                                            Text("\(mins / 60)h")
//                                                .font(.system(size: 9))
//                                        }
//                                    }
//                                }
//                            }
//                            
//                            // X-AXIS: Lines extending down past the labels
//                            .chartXAxis {
//                                AxisMarks(values: ["00", "06", "12", "18"]) { value in
//                                    // 1. The main grid line inside the chart
//                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
//                                        .foregroundStyle(.gray.opacity(0.2))
//                                    
//                                    // 2. The "Tick" that extends the line DOWNWARDS
//                                    // We set length to 20 to make it go past the numbers
//                                    AxisTick(length: 20, stroke: StrokeStyle(lineWidth: 1))
//                                        .foregroundStyle(.gray.opacity(0.2))
//                                    
//                                    // 3. Labels shifted to the right of the long line
//                                    AxisValueLabel(anchor: .topLeading) {
//                                        if let label = value.as(String.self) {
//                                            Text(label)
//                                                .font(.system(size: 10))
//                                                .padding(.leading, -10)
//                                                .padding(.top, 2) // Space from the top of the tick
//                                        }
//                                    }
//                                }
//                            }
//                            .frame(height: 150)
//                            .padding(.top, -20)
//                            .padding(.horizontal)
//                        }
//                        .containerRelativeFrame(.horizontal)
//                    }
//                }
//                .scrollTargetLayout()
//            }
//            .scrollPosition(id: $scrolledID)
//            .scrollTargetBehavior(.paging)
//            .defaultScrollAnchor(.trailing)
//        }
//        .onAppear {
//            scrolledID = history.count - 1
//        }
//    }
//}
