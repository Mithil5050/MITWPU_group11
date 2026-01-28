import SwiftUI
import Charts

struct BarChartView: View {
    @ObservedObject var model: StudyChartModel
    // Use @State so the Picker can manage the view's data selection directly
    @State private var isShowingDaily: Bool = true
    @State private var scrolledID: Int?

    private var history: [[StudyData]] {
        isShowingDaily ? model.dailyHistory : model.weeklyHistory
    }

    private var currentIdx: Int {
        scrolledID ?? max(0, history.count - 1)
    }

    private var isViewingPast: Bool {
        guard history.count > 0 else { return false }
        return currentIdx < (history.count - 1)
    }

    private func getTotalHours(for index: Int) -> String {
        guard index >= 0 && index < history.count else { return "0h 0m" }
        let totalMinutes = history[index].reduce(0) { $0 + $1.focusMinutes + $1.extraMinutes }
        let h = Int(totalMinutes) / 60
        let m = Int(totalMinutes) % 60
        return "\(h)h \(m)m"
    }

    private func getDateLabel(for index: Int) -> String {
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
            return "\(distance) Weeks Ago"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. Integrated Segmented Picker
            Picker("Time Frame", selection: $isShowingDaily) {
                Text("Day").tag(true)
                Text("Week").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // 2. Header Section
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(getDateLabel(for: currentIdx))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(getTotalHours(for: currentIdx))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if isViewingPast {
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            scrolledID = history.count - 1
                        }
                    }) {
                        HStack(spacing: 0) {
                            Text(isShowingDaily ? "Today" : "This Week")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            // 3. Chart Section
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<history.count, id: \.self) { index in
                        chartPage(for: index)
                            .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrolledID)
            .scrollTargetBehavior(.paging)
            .frame(height: 160)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrolledID = max(0, history.count - 1)
            }
        }
        .onChange(of: isShowingDaily) { oldValue, newValue in
            scrolledID = max(0, history.count - 1)
        }
    }

    @ViewBuilder
    private func chartPage(for index: Int) -> some View {
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
        .chartYScale(domain: 0...480)
        .chartYAxis {
            AxisMarks(position: .trailing, values: [0, 240, 480]) { value in
                AxisGridLine().foregroundStyle(.white.opacity(0.15))
                AxisValueLabel {
                    if let mins = value.as(Int.self) {
                        Text("\(mins / 60)h").font(.system(size: 9))
                    }
                }
            }
        }
        .chartXAxis {
            let axisValues = isShowingDaily ? ["00", "06", "12", "18"] : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            AxisMarks(values: axisValues) { value in
                AxisGridLine().foregroundStyle(.white.opacity(0.1))
                AxisValueLabel {
                    if let label = value.as(String.self) {
                        Text(label).font(.system(size: 9))
                    }
                }
            }
        }
        .frame(height: 125)
        .padding(.horizontal)
    }
}
