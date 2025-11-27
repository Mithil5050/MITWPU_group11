import UIKit

class BarGraphView: UIView {
   
    var values: [CGFloat] = [4, 7, 6, 10, 5, 9] {
        didSet { setNeedsLayout() }
    }

    private var barLayers: [CAShapeLayer] = []
    private var gridLayers: [CAShapeLayer] = []

    // Adjustable thickness (0.3 = 30% of section width)
    private let barWidthFactor: CGFloat = 0.35

    override func layoutSubviews() {
        super.layoutSubviews()

        // Clean old layers
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        barLayers.removeAll()
        gridLayers.removeAll()

        guard !values.isEmpty else { return }

        let count = values.count
        let maxVal = values.max() ?? 1

        let sectionWidth = bounds.width / CGFloat(count)
        let barWidth = sectionWidth * barWidthFactor

        drawGridLines()

        for (index, value) in values.enumerated() {

            let normalized = value / maxVal
            let barHeight = normalized * bounds.height

            let x = sectionWidth * CGFloat(index) + (sectionWidth - barWidth) / 2
            let y = bounds.height - barHeight

            let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
            let path = UIBezierPath(roundedRect: barRect, cornerRadius: 6)

            let barLayer = CAShapeLayer()
            barLayer.path = path.cgPath
            barLayer.fillColor = UIColor.systemBlue.cgColor

            layer.addSublayer(barLayer)
            barLayers.append(barLayer)
        }
    }

    private func drawGridLines() {
        let lineCount = 3
        let spacing = bounds.height / CGFloat(lineCount + 1)

        for i in 1...lineCount {
            let y = spacing * CGFloat(i)

            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: bounds.width, y: y))

            let gridLayer = CAShapeLayer()
            gridLayer.path = path.cgPath
            gridLayer.strokeColor = UIColor.systemGray5.cgColor
            gridLayer.lineWidth = 1

            layer.addSublayer(gridLayer)
            gridLayers.append(gridLayer)
        }
    }
}

