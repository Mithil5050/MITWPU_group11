import SwiftUI
import Charts

struct BarChartView: View {
    @ObservedObject var model: StudyChartModel
    @State private var isShowingDaily: Bool = true
    @State private var scrolledID: Int?
    
    private let colors = (
        study: Color.blue,
        games: Color(red: 0.0, green: 0.9, blue: 1.0)
    )
    
    private var history: [[StudyData]] { isShowingDaily ? model.dailyHistory : model.weeklyHistory }
    private var currentIdx: Int { scrolledID ?? max(0, history.count - 1) }
    
    private var isNotAtEnd: Bool {
        guard !history.isEmpty else { return false }
        return currentIdx < history.count - 1
    }
    
    private func getTotalHours(for index: Int) -> String {
        guard index >= 0 && index < history.count else { return "0h 0m" }
        let totalMinutes = history[index].reduce(0.0) { $0 + $1.totalMinutes }
        return "\(Int(totalMinutes) / 60)h \(Int(totalMinutes) % 60)m"
    }
    
    private func getDateLabel(for index: Int) -> String {
        guard index >= 0 && index < history.count else { return "" }
        let distance = (history.count - 1) - index
        let date = Calendar.current.date(byAdding: isShowingDaily ? .day : .weekOfYear, value: -distance, to: Date()) ?? Date()
        return isShowingDaily ? (distance == 0 ? "Today, \(date.formatted(.dateTime.day().month(.wide)))" : date.formatted(.dateTime.day().month(.wide))) : (distance == 0 ? "This Week" : "\(distance) Weeks Ago")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. Segmented Picker
            Picker("Time Frame", selection: $isShowingDaily) {
                Text("Week").tag(false)
                Text("Day").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 8)
            
            // 2. Header
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(getDateLabel(for: currentIdx))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(getTotalHours(for: currentIdx))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if isNotAtEnd {
                    Button(action: {
                        withAnimation(.spring()) {
                            scrolledID = history.count - 1
                        }
                    }) {
                        Text(isShowingDaily ? "Show Today" : "Show This Week")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
            
            // 3. Horizontal Scrollable Graph
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<history.count, id: \.self) { index in
                        chartPage(for: index).containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrolledID)
            .scrollTargetBehavior(.paging)
            .frame(height: 160)
            
            // 4. Centered Legend
            HStack(spacing: 0) {
                Spacer()
                legendItem(label: "Learning", color: colors.study)
                Spacer()
                legendItem(label: "Games", color: colors.games)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        
        // This ensures the view has a solid minimum height
        .frame(minHeight: 330)
        .onAppear { scrolledID = max(0, history.count - 1) }
        .onChange(of: isShowingDaily) {
            scrolledID = history.count - 1
        }
    }
    
    private func dynamicYMax(for index: Int) -> Double {
        guard index >= 0 && index < history.count else { return 120 }
        let maxTotal = history[index].map { $0.studyMinutes + $0.gamesMinutes }.max() ?? 0
        let padded = max(maxTotal * 1.3, 60)
        return (padded / 60.0).rounded(.up) * 60.0
    }

    @ViewBuilder
    private func chartPage(for index: Int) -> some View {
        let yMax = dynamicYMax(for: index)
        let maxHours = Int(yMax) / 60
        // ≤ 2h: always show 0h/1h/2h  |  > 2h: show 0h / half / max (even hours)
        let axisValues: [Double] = maxHours <= 2 ? [0, 60, 120] : [0, yMax / 2, yMax]
        let axisDomain: ClosedRange<Double> = maxHours <= 2 ? 0...120 : 0...yMax
        Chart(history[index]) { item in
            BarMark(x: .value("Day", item.label), y: .value("Study", item.studyMinutes))
                .foregroundStyle(colors.study)
            
            BarMark(x: .value("Day", item.label), y: .value("Games", item.gamesMinutes))
                .foregroundStyle(colors.games)
        }
        .chartYScale(domain: axisDomain)
        .chartYAxis {
            AxisMarks(position: .trailing, values: axisValues) { value in
                AxisGridLine().foregroundStyle(.white.opacity(0.15))
                AxisValueLabel {
                    if let mins = value.as(Double.self) {
                        Text("\(Int(mins) / 60)h").font(.system(size: 9))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: isShowingDaily ? ["00", "06", "12", "18"] : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]) { value in
                AxisGridLine().foregroundStyle(.white.opacity(0.1))
                AxisValueLabel { if let label = value.as(String.self) { Text(label).font(.system(size: 9)) } }
            }
        }
        .frame(height: 155)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 11, weight: .bold)).foregroundColor(color)
        }
    }
}
