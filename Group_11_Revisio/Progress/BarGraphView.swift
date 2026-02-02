import SwiftUI
import Charts

struct BarChartView: View {
    @ObservedObject var model: StudyChartModel
    @State private var isShowingDaily: Bool = true
    @State private var scrolledID: Int?

    // Color Configuration: Light Green and Blue
    private let colors = (
        study: Color.blue,
        games: Color(red: 0.56, green: 0.93, blue: 0.56).opacity(0.9) // Light Green
    )

    private var history: [[StudyData]] { isShowingDaily ? model.dailyHistory : model.weeklyHistory }
    private var currentIdx: Int { scrolledID ?? max(0, history.count - 1) }

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
            Picker("Time Frame", selection: $isShowingDaily) {
                Text("Day").tag(true)
                Text("Week").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 0) {
                Text(getDateLabel(for: currentIdx)).font(.system(size: 13, weight: .medium)).foregroundColor(.secondary)
                Text(getTotalHours(for: currentIdx)).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.bottom, 2)

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

            HStack(spacing: 0) {
                Spacer()
                legendItem(label: "Study", color: .blue)
                Spacer()
                legendItem(label: "Games", color: Color(red: 0.56, green: 0.93, blue: 0.56))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 0)
            .padding(.bottom, 8)
        }
        .onAppear { scrolledID = max(0, history.count - 1) }
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
