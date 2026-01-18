import SwiftUI
import Charts

struct BarChartView: View {
    @ObservedObject var model: StudyChartModel
    let isShowingDaily: Bool
    
    @State private var scrolledID: Int?

    // MARK: - Computed Properties
    private var history: [[StudyData]] {
        isShowingDaily ? model.dailyHistory : model.weeklyHistory
    }

    private var currentIdx: Int {
        // Fallback to the latest data if scrollID is nil
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
            // FIX: Guaranteed "This Week" label for the current index
            if distance == 0 { return "This Week" }
            if distance == 1 { return "Last Week" }
            return "\(distance) Weeks Ago"
        }
    }
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // HEADER
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(getDateLabel(for: currentIdx))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(getTotalHours(for: currentIdx))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    
                    if isViewingPast {
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                scrolledID = history.count - 1
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(isShowingDaily ? "Show Today" : "Show This Week")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 14)

                // CHART AREA
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
            }
            // This is the key fix: It monitors the history array.
            // As soon as data loads, it snaps to the last item (Today).
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrolledID = max(0, history.count - 1)
                }
            }
            .onChange(of: isShowingDaily) { oldValue, newValue in
                scrolledID = max(0, history.count - 1)
            }
            // Extra safety: If history changes (data finishes loading), reset ID
            .onChange(of: history.count) { oldValue, newValue in
                scrolledID = max(0, newValue - 1)
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
            AxisMarks(position: .trailing, values: [0, 120, 240, 360, 480]) { value in
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
                        Text(label).font(.system(size: 10))
                    }
                }
            }
        }
        .frame(height: 140)
        .padding(.horizontal)
    }
}
