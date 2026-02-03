import SwiftUI
import Charts

struct BarChartView: View {
    @ObservedObject var model: StudyChartModel
    @State private var isShowingDaily: Bool = true
    @State private var scrolledID: Int?
    
    // Color Setup: Blue for Study, Cyan for Games (Entertainment)
    private let colors = (
        study: Color.blue,
        games: Color(red: 0.0, green: 0.9, blue: 1.0) // Vibrant Cyan
    )
    
    private var history: [[StudyData]] { isShowingDaily ? model.dailyHistory : model.weeklyHistory }
    private var currentIdx: Int { scrolledID ?? max(0, history.count - 1) }
    
    // Logic to detect if user has scrolled away from the most recent data
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
            
            // 2. Header with Dynamic "Show Today" / "Show This Week" Button
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
                        // Dynamically changes text based on the isShowingDaily state
                        Text(isShowingDaily ? "Show Today" : "Show This Week")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 2)
            
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
                legendItem(label: "Study", color: colors.study)
                Spacer()
                legendItem(label: "Games", color: colors.games)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 0)
            .padding(.bottom, 8)
        }
        .onAppear { scrolledID = max(0, history.count - 1) }
        .onChange(of: isShowingDaily) {
            scrolledID = history.count - 1
        }
    }
    
    @ViewBuilder
    private func chartPage(for index: Int) -> some View {
        Chart(history[index]) { item in
            BarMark(x: .value("Day", item.label), y: .value("Games", item.gamesMinutes))
                .foregroundStyle(colors.games)
            
            BarMark(x: .value("Day", item.label), y: .value("Study", item.studyMinutes))
                .foregroundStyle(colors.study)
        }
        .chartYScale(domain: 0...480)
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0, 240, 480]) { value in
                AxisGridLine().foregroundStyle(.white.opacity(0.15))
                AxisValueLabel { if let mins = value.as(Int.self) { Text("\(mins / 60)h").font(.system(size: 9)) } }
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
