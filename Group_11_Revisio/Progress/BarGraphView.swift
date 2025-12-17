import SwiftUI
import Charts

struct BarChartView: View {

    let data: [StudyData]

    var body: some View {
        Chart(data) {
            BarMark(
                x: .value("Label", $0.label),
                y: .value("Hours", $0.hours)
            )
            .foregroundStyle(.blue)
            .cornerRadius(6)
        }
        .padding()
    }
}
