import SwiftUI

struct FocusTankView: View {
    let pollutionLevel: Double
    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let rect = CGRect(origin: .zero, size: size).insetBy(dx: 18, dy: 18)
                let bowl = Path(ellipseIn: rect)
                let waterRect = rect.insetBy(dx: 12, dy: 12)
                let waterPath = waterPath(in: waterRect, time: time)

                context.clip(to: bowl)

                context.fill(
                    bowl,
                    with: .linearGradient(
                        Gradient(colors: [
                            Color.white.opacity(0.95),
                            Color.peachFoam.opacity(0.35)
                        ]),
                        startPoint: CGPoint(x: rect.midX, y: rect.minY),
                        endPoint: CGPoint(x: rect.midX, y: rect.maxY)
                    )
                )

                context.fill(waterPath, with: .color(waterColor))
                drawBubbles(in: &context, rect: waterRect, time: time)
                drawPlants(in: &context, rect: waterRect)

                let fishPoint = fishPosition(in: waterRect, time: time)
                drawFinn(in: &context, center: fishPoint, size: 48, time: time)

                context.stroke(bowl, with: .color(Color.tideOrange.opacity(0.3)), lineWidth: 3)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(10)
    }

    private var waterColor: Color {
        switch pollutionLevel {
        case 0..<0.25:
            return .tankTeal.opacity(0.7)
        case 0.25..<0.5:
            return Color(red: 0.3, green: 0.816, blue: 0.721).opacity(0.76)
        case 0.5..<0.75:
            return .amber.opacity(0.72)
        case 0.75..<1:
            return Color(red: 0.831, green: 0.537, blue: 0.369).opacity(0.78)
        default:
            return .muddyBrown.opacity(0.82)
        }
    }

    private func waterPath(in rect: CGRect, time: TimeInterval) -> Path {
        let fillAmount = 0.68 + pollutionLevel * 0.18
        let baseline = rect.maxY - rect.height * fillAmount
        let amplitude = max(3, 8 - pollutionLevel * 4)
        let frequency = Double.pi * 2 / max(1, rect.width)
        let speed = time * (1.4 - pollutionLevel * 0.8)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: baseline))

        stride(from: rect.minX, through: rect.maxX, by: 3).forEach { x in
            let wave = sin((x - rect.minX) * frequency * 2.2 + speed) * amplitude
            path.addLine(to: CGPoint(x: x, y: baseline + wave))
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    private func fishPosition(in rect: CGRect, time: TimeInterval) -> CGPoint {
        let speed = max(0.25, 1.0 - pollutionLevel * 0.72)
        let t = time * speed
        let x = rect.midX + cos(t * 0.7) * rect.width * 0.24 + sin(t * 1.15) * rect.width * 0.08
        let y = rect.midY + sin(t * 0.9) * rect.height * 0.16
        return CGPoint(x: x, y: y)
    }

    private func drawFinn(in context: inout GraphicsContext, center: CGPoint, size: CGFloat, time: TimeInterval) {
        let dulling = pollutionLevel * 0.32
        let bodyColor = Color.tideOrange.opacity(1 - dulling)
        let finColor = Color.coral.opacity(1 - dulling * 0.8)
        let direction: CGFloat = cos(time * 0.7) >= 0 ? 1 : -1

        context.translateBy(x: center.x, y: center.y)
        context.scaleBy(x: direction, y: 1)

        let body = Path(ellipseIn: CGRect(x: -size * 0.36, y: -size * 0.2, width: size * 0.62, height: size * 0.4))
        let tail = Path { path in
            path.move(to: CGPoint(x: -size * 0.34, y: 0))
            path.addLine(to: CGPoint(x: -size * 0.58, y: -size * 0.22))
            path.addLine(to: CGPoint(x: -size * 0.58, y: size * 0.22))
            path.closeSubpath()
        }
        let topFin = Path { path in
            path.move(to: CGPoint(x: -size * 0.08, y: -size * 0.19))
            path.addLine(to: CGPoint(x: size * 0.06, y: -size * 0.36 + CGFloat(pollutionLevel) * size * 0.08))
            path.addLine(to: CGPoint(x: size * 0.16, y: -size * 0.16))
            path.closeSubpath()
        }
        let eye = Path(ellipseIn: CGRect(x: size * 0.08, y: -size * 0.1, width: size * 0.11, height: size * 0.11))
        let pupilHeight = max(2, size * (0.055 - CGFloat(pollutionLevel) * 0.025))
        let pupil = Path(ellipseIn: CGRect(x: size * 0.125, y: -size * 0.07, width: size * 0.035, height: pupilHeight))

        context.fill(tail, with: .color(finColor))
        context.fill(topFin, with: .color(finColor))
        context.fill(body, with: .color(bodyColor))
        context.fill(eye, with: .color(.white))
        context.fill(pupil, with: .color(.textDark))

        context.scaleBy(x: direction, y: 1)
        context.translateBy(x: -center.x, y: -center.y)
    }

    private func drawBubbles(in context: inout GraphicsContext, rect: CGRect, time: TimeInterval) {
        for index in 0..<6 {
            let offset = Double(index) * 0.41
            let x = rect.minX + rect.width * (0.18 + Double(index % 3) * 0.24)
            let cycle = (time * 0.08 + offset).truncatingRemainder(dividingBy: 1)
            let y = rect.maxY - rect.height * cycle
            let radius = CGFloat(3 + index % 3)
            let bubble = Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2))
            context.stroke(bubble, with: .color(Color.white.opacity(0.48)), lineWidth: 1.5)
        }
    }

    private func drawPlants(in context: inout GraphicsContext, rect: CGRect) {
        for index in 0..<4 {
            let baseX = rect.minX + CGFloat(index + 1) * rect.width / 5
            var plant = Path()
            plant.move(to: CGPoint(x: baseX, y: rect.maxY - 10))
            plant.addQuadCurve(
                to: CGPoint(x: baseX + CGFloat(index.isMultiple(of: 2) ? 18 : -18), y: rect.maxY - 74),
                control: CGPoint(x: baseX + CGFloat(index.isMultiple(of: 2) ? -16 : 16), y: rect.maxY - 38)
            )
            context.stroke(plant, with: .color(Color.tankTeal.opacity(0.55)), lineWidth: 4)
        }
    }
}
