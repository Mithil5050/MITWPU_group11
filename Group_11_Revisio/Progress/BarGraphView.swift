// BarGraphView.swift

import SwiftUI
import Charts

struct BarChartView: View {
    let history: [[StudyData]] // Accept the 2D array (History of Pages)
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(0..<history.count, id: \.self) { index in
                    Chart {
                        ForEach(history[index]) { item in
                            // Stacked Bar
                            BarMark(
                                x: .value("Time", item.label),
                                y: .value("Focus", item.focusMinutes)
                            )
                            .foregroundStyle(Color.blue)
                            
                            BarMark(
                                x: .value("Time", item.label),
                                y: .value("Extra", item.extraMinutes)
                            )
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing, values: [0, 10, 20, 30])
                    }
                    .padding()
                    // 🚨 IMPORTANT: This makes one page = one day/week
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        // This makes it snap like Apple Screen Time
        .scrollTargetBehavior(.paging)
        // Starts the scroll at the far right (Today)
        .defaultScrollAnchor(.trailing)
    }
}

//import SwiftUI
//import Charts
//
//struct BarChartView: View {
//
//    let data: [StudyData]
//
//    var body: some View {
//        Chart {
//            ForEach(data) { item in
//
//                BarMark(
//                    x: .value("Time", item.label),
//                    y: .value("Focus", item.focusMinutes)
//                )
//                .foregroundStyle(Color.blue)
//                .cornerRadius(4)
//
//               
//                BarMark(
//                    x: .value("Time", item.label),
//                    y: .value("Extra", item.extraMinutes)
//                )
////                .foregroundStyle(Color.cyan)
////                .cornerRadius(4)
//            }
//        }
//        .chartYAxis {
//            AxisMarks(position: .trailing)
//        }
//        .chartXAxis {
//            AxisMarks()
//        }
//        .padding()
//        .background(Color.clear)
//    }
//}
//
