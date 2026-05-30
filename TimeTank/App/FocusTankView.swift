import SwiftUI

struct FocusTankView: View {
    let pollutionLevel: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let time        = timeline.date.timeIntervalSinceReferenceDate
            let speed       = max(0.25, 1.0 - pollutionLevel * 0.72)
            let tremble     = pollutionLevel > 0.15
                                ? sin(time * 17.0) * (pollutionLevel - 0.15) * 4.5
                                : 0.0
            let bob         = sin(time * speed * 1.2) * 10.0 + tremble
            let swayRange   = 22.0 * (1.0 - pollutionLevel * 0.55)
            let sway        = cos(time * speed * 0.7) * swayRange
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

                        // Water opacity thickens as pollution rises
                        let water         = waterPath(in: interior, time: time)
                        let surfaceY      = interior.maxY - interior.height * (0.84 + pollutionLevel * 0.12)
                        let topOpacity    = 0.38 + pollutionLevel * 0.30
                        let bottomOpacity = 0.52 + pollutionLevel * 0.28
                        ctx.fill(water, with: .linearGradient(
                            Gradient(stops: [
                                .init(color: waterColor.opacity(0.0),          location: 0.0),
                                .init(color: waterColor.opacity(topOpacity),    location: 0.18),
                                .init(color: waterColor.opacity(bottomOpacity), location: 1.0)
                            ]),
                            startPoint: CGPoint(x: interior.midX, y: surfaceY),
                            endPoint:   CGPoint(x: interior.midX, y: interior.maxY)
                        ))

                        drawParticles(in: &ctx, rect: interior, time: time)
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

    // Smooth interpolation: teal → amber → muddy brown
    private var waterColor: Color {
        if pollutionLevel < 0.5 {
            let t = pollutionLevel / 0.5
            return Color(red: t * 1.0, green: 0.75 - t * 0.08, blue: 0.65 - t * 0.40)
        } else {
            let t = (pollutionLevel - 0.5) / 0.5
            return Color(red: 1.0 - t * 0.29, green: 0.67 - t * 0.27, blue: 0.25 - t * 0.14)
        }
    }

    private func waterPath(in rect: CGRect, time: TimeInterval) -> Path {
        let fill     = 0.84 + pollutionLevel * 0.12
        let baseline = rect.maxY - rect.height * fill
        let freq     = Double.pi * 2.0 / Double(rect.width)

        // Primary wave — gentle when clean, slightly bigger when murky
        let primaryAmp   = 3.0 + pollutionLevel * 2.5
        let primarySpeed = 1.4 - pollutionLevel * 0.45
        let primaryShift = time * primarySpeed

        // Turbulence — kicks in at 20% pollution, full strength at 100%
        let turbStrength = max(0.0, (pollutionLevel - 0.2) / 0.8)
        let turbAmp      = turbStrength * 8.0
        let turbShift    = time * (primarySpeed * 1.85 + turbStrength * 0.6)

        // High-frequency chop — kicks in at 50%, peaks at 100%
        let chopStrength = max(0.0, (pollutionLevel - 0.5) / 0.5)
        let chopAmp      = chopStrength * 4.5
        let chopShift    = time * 3.8

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: baseline))
        stride(from: rect.minX, through: rect.maxX, by: 2).forEach { x in
            let xd = Double(x) - Double(rect.minX)
            let y  = baseline
                + sin(xd * freq * 2.4           + primaryShift) * primaryAmp
                + sin(xd * freq * 4.1           + turbShift)    * turbAmp
                + sin(xd * freq * 8.3           + chopShift)    * chopAmp
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    private func drawParticles(in ctx: inout GraphicsContext, rect: CGRect, time: TimeInterval) {
        // Clean bubbles — fade out completely by 50% pollution
        let bubbleVis = max(0.0, 1.0 - pollutionLevel * 2.0)
        if bubbleVis > 0 {
            for i in 0..<6 {
                let spread  = Double(i % 3) * 0.28 + 0.15
                let phase   = Double(i) * 0.43
                let cycle   = (time * 0.055 + phase).truncatingRemainder(dividingBy: 1.0)
                let x       = rect.minX + rect.width  * CGFloat(spread)
                let y       = rect.maxY - rect.height * CGFloat(cycle) * 0.9
                let r       = CGFloat(2.0 + Double(i % 3) * 1.2)
                let bubble  = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                let opacity = min(cycle * 7.0, 1.0) * 0.60 * bubbleVis
                ctx.stroke(bubble, with: .color(.white.opacity(opacity)), lineWidth: 1.2)
            }
        }

        // Murky debris — appears at 20% pollution, grows heavier through 100%
        guard pollutionLevel > 0.2 else { return }
        let debrisStrength = (pollutionLevel - 0.2) / 0.8
        let debrisCount    = Int(3 + debrisStrength * 8)

        for i in 0..<debrisCount {
            let seed    = Double(i)
            let spread  = (seed * 0.137 + 0.08).truncatingRemainder(dividingBy: 0.82) + 0.08
            let phase   = seed * 0.619
            let speed   = 0.022 + seed.truncatingRemainder(dividingBy: 3.0) * 0.011
            let cycle   = (time * speed + phase).truncatingRemainder(dividingBy: 1.0)
            let wobble  = CGFloat(sin(time * 1.1 + phase) * Double(rect.width) * 0.032)
            let x       = rect.minX + rect.width  * CGFloat(spread) + wobble
            let y       = rect.maxY - rect.height * CGFloat(cycle)   * 0.88
            let r       = CGFloat(1.0 + seed.truncatingRemainder(dividingBy: 4.0) * 0.85) * CGFloat(debrisStrength)
            let opacity = min(cycle * 4.0, 1.0) * 0.50 * debrisStrength
            // Debris shifts from warm-brown at low pollution to dark muddy at full
            let dr = 0.62 + debrisStrength * 0.09
            let dg = 0.38 - debrisStrength * 0.12
            let particle = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            ctx.fill(particle, with: .color(Color(red: dr, green: dg, blue: 0.08).opacity(opacity)))
        }
    }
}
