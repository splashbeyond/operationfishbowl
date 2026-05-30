import SwiftUI

struct FocusTankView: View {
    let pollutionLevel: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let time        = timeline.date.timeIntervalSinceReferenceDate
            let speed       = max(0.25, 1.0 - pollutionLevel * 0.72)
            let bob         = sin(time * speed * 1.2) * 10.0
            let sway        = cos(time * speed * 0.7) * 22.0
            let facingRight = sway >= 0

            GeometryReader { geo in
                let size     = min(geo.size.width, geo.size.height)
                let finnSize = size * 0.36

                ZStack {
                    // 1. Glass bowl (back)
                    Image("FinnBowlOnly")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)

                    // 2. Water fill + bubbles clipped to bowl interior
                    Canvas { ctx, canvasSize in
                        let interior = CGRect(
                            x: canvasSize.width  * 0.225,
                            y: canvasSize.height * 0.30,
                            width:  canvasSize.width  * 0.562,
                            height: canvasSize.height * 0.47
                        )
                        // Bowl-shaped clip: straight sides at the top so the water
                        // surface spans full width, large semicircle at the bottom
                        // to match the bowl's rounded base.
                        let rTop = interior.width * 0.06
                        let rBot = interior.width * 0.53
                        var clipPath = Path()
                        clipPath.move(to: CGPoint(x: interior.minX + rTop, y: interior.minY))
                        clipPath.addLine(to: CGPoint(x: interior.maxX - rTop, y: interior.minY))
                        clipPath.addQuadCurve(to: CGPoint(x: interior.maxX, y: interior.minY + rTop),
                                              control: CGPoint(x: interior.maxX, y: interior.minY))
                        clipPath.addLine(to: CGPoint(x: interior.maxX, y: interior.maxY - rBot))
                        clipPath.addQuadCurve(to: CGPoint(x: interior.midX, y: interior.maxY),
                                              control: CGPoint(x: interior.maxX, y: interior.maxY))
                        clipPath.addQuadCurve(to: CGPoint(x: interior.minX, y: interior.maxY - rBot),
                                              control: CGPoint(x: interior.minX, y: interior.maxY))
                        clipPath.addLine(to: CGPoint(x: interior.minX, y: interior.minY + rTop))
                        clipPath.addQuadCurve(to: CGPoint(x: interior.minX + rTop, y: interior.minY),
                                              control: CGPoint(x: interior.minX, y: interior.minY))
                        clipPath.closeSubpath()
                        ctx.clip(to: clipPath)

                        // Water fill — gradient fade at surface so it blends into glass
                        let water = waterPath(in: interior, time: time)
                        let surfaceY = interior.maxY - interior.height * (0.84 + pollutionLevel * 0.12)
                        ctx.fill(water, with: .linearGradient(
                            Gradient(stops: [
                                .init(color: waterColor.opacity(0.0),  location: 0.0),
                                .init(color: waterColor.opacity(0.38), location: 0.18),
                                .init(color: waterColor.opacity(0.52), location: 1.0)
                            ]),
                            startPoint: CGPoint(x: interior.midX, y: surfaceY),
                            endPoint:   CGPoint(x: interior.midX, y: interior.maxY)
                        ))

                        drawBubbles(in: &ctx, rect: interior, time: time)
                    }
                    .frame(width: size, height: size)

                    // 3. Finn on top — swims left/right, bobs, faces direction of travel
                    Image("FinnMascot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: finnSize)
                        .scaleEffect(x: facingRight ? 1 : -1, y: 1)
                        .offset(x: sway, y: size * 0.05 + bob)
                        .opacity(1.0 - pollutionLevel * 0.28)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(3)
    }

    // Water color shifts from teal → amber → muddy as pollution rises
    private var waterColor: Color {
        switch pollutionLevel {
        case 0..<0.25:
            return Color(red: 0.0,  green: 0.75, blue: 0.65) // Tank Teal
        case 0.25..<0.5:
            return Color(red: 0.3,  green: 0.78, blue: 0.68) // muted teal
        case 0.5..<0.75:
            return Color(red: 1.0,  green: 0.67, blue: 0.25) // amber
        default:
            return Color(red: 0.71, green: 0.40, blue: 0.11) // muddy brown
        }
    }

    private func waterPath(in rect: CGRect, time: TimeInterval) -> Path {
        let fill      = 0.84 + pollutionLevel * 0.12
        let baseline  = rect.maxY - rect.height * fill
        let amplitude = max(2.0, 7.0 - pollutionLevel * 4.0)
        let freq      = Double.pi * 2.0 / Double(rect.width)
        let shift     = time * (1.3 - pollutionLevel * 0.75)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: baseline))
        stride(from: rect.minX, through: rect.maxX, by: 2).forEach { x in
            let y = baseline + sin((Double(x) - Double(rect.minX)) * freq * 2.4 + shift) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    private func drawBubbles(in ctx: inout GraphicsContext, rect: CGRect, time: TimeInterval) {
        for i in 0..<6 {
            let spread  = Double(i % 3) * 0.28 + 0.15
            let phase   = Double(i) * 0.43
            let cycle   = (time * 0.055 + phase).truncatingRemainder(dividingBy: 1.0)
            let x       = rect.minX + rect.width  * spread
            let y       = rect.maxY - rect.height * CGFloat(cycle) * 0.9
            let r       = CGFloat(2.0 + Double(i % 3) * 1.2)
            let bubble  = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            let opacity = min(cycle * 7.0, 1.0) * 0.60
            ctx.stroke(bubble, with: .color(.white.opacity(opacity)), lineWidth: 1.2)
        }
    }
}
