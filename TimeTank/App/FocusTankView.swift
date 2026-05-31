import SwiftUI

struct FocusTankView: View {
    let pollutionLevel: Double
    var onFinnTap: (() -> Void)? = nil

    @State private var finnTapped = false
    @State private var finnScale: CGFloat = 1.0

    var body: some View {
        TimelineView(.animation) { timeline in
            let time        = timeline.date.timeIntervalSinceReferenceDate
            // Movement fades from full at 40% pollution to zero at 100%
            let movementFactor = pollutionLevel <= 0.4
                ? 1.0
                : max(0.0, 1.0 - (pollutionLevel - 0.4) / 0.6)
            let bob         = sin(time * 1.2) * 10.0 * movementFactor
            let sway        = cos(time * 0.7) * 22.0 * movementFactor
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
                        // Wider top corners narrow the clip to match the bowl's rim
                        let rTop = interior.width * 0.18
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
                        let surfaceY      = interior.maxY - interior.height * (min(0.84, 0.80 + pollutionLevel * 0.06))
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

                    // 3. Finn — face swaps with crossfade at each pollution threshold
                    Image(finnTapped ? "FinnMascotAlert" : finnFaceName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: finnSize)
                        .scaleEffect(x: facingRight ? 1 : -1, y: 1)
                        .scaleEffect(finnScale)
                        .offset(x: sway, y: size * 0.05 + bob)
                        .opacity(1.0 - pollutionLevel * 0.28)
                        .animation(.easeInOut(duration: 0.6), value: finnFaceName)
                        .animation(.spring(response: 0.25, dampingFraction: 0.4), value: finnScale)
                        .onTapGesture { handleFinnTap() }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(3)
    }

    private func handleFinnTap() {
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()

        withAnimation { finnScale = 1.18 }
        finnTapped = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation { finnScale = 1.0 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            finnTapped = false
            onFinnTap?()
        }
    }

    // Face asset name keyed to pollution threshold
    private var finnFaceName: String {
        switch pollutionLevel {
        case 0..<0.2:   return "FinnMascot"            // Blissful — clean tank
        case 0.2..<0.4: return "FinnMascotAlert"      // Alert
        case 0.4..<0.8: return "FinnMascotWorried"    // Worried — 40–80%
        case 0.8..<1.0: return "FinnMascotSuffering"  // Suffering — 80–100%
        default:        return "FinnMascotDistressed"  // Distressed — 100%
        }
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
        let fill     = min(0.84, 0.80 + pollutionLevel * 0.06)  // max 86% — never reaches the bowl rim
        let baseline = rect.maxY - rect.height * fill
        let freq     = Double.pi * 2.0 / Double(rect.width)
        let shift    = time * 1.3

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: baseline))
        stride(from: rect.minX, through: rect.maxX, by: 2).forEach { x in
            let xd = Double(x) - Double(rect.minX)
            let y  = baseline + sin(xd * freq * 2.4 + shift) * 3.5
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
