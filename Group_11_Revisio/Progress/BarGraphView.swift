import SwiftUI
import Charts

struct BarChartView: View {

    let data: [StudyData]

    var body: some View {
        Chart {
            ForEach(data) { item in

                BarMark(
                    x: .value("Time", item.label),
                    y: .value("Focus", item.focusMinutes)
                )
                .foregroundStyle(Color.blue)
                .cornerRadius(4)

               
                BarMark(
                    x: .value("Time", item.label),
                    y: .value("Extra", item.extraMinutes)
                )
//                .foregroundStyle(Color.cyan)
//                .cornerRadius(4)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing)
        }
        .chartXAxis {
            AxisMarks()
        }
        .padding()
        .background(Color.clear)
    }
}

