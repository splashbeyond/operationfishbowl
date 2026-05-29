import SwiftUI

struct FocusTankView: View {
    let pollutionLevel: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let speed = max(0.25, 1.0 - pollutionLevel * 0.72)
            let bob    = sin(time * speed * 1.2) * 10.0
            let sway   = cos(time * speed * 0.7) * 22.0
            let facingRight = sway >= 0

            GeometryReader { geo in
                let size     = min(geo.size.width, geo.size.height)
                let finnSize = size * 0.36

                ZStack {
                    // Empty glass bowl — tinted by pollution level
                    Image("FinnBowlOnly")
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .colorMultiply(bowlTint)

                    // Finn — swims left/right, bobs up/down, slows as tank pollutes
                    Image("FinnMascot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: finnSize)
                        .scaleEffect(x: facingRight ? 1 : -1, y: 1)
                        .offset(x: sway, y: size * 0.04 + bob)
                        .opacity(1.0 - pollutionLevel * 0.28)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(10)
    }

    // Multiplied over the bowl image — white = no change, warm browns = polluted
    private var bowlTint: Color {
        switch pollutionLevel {
        case 0..<0.25:
            return Color(red: 1.0, green: 1.0, blue: 1.0)   // crystal clear
        case 0.25..<0.5:
            return Color(red: 1.0, green: 0.97, blue: 0.82)  // faint yellow murk
        case 0.5..<0.75:
            return Color(red: 1.0, green: 0.88, blue: 0.62)  // amber
        default:
            return Color(red: 0.88, green: 0.72, blue: 0.48) // muddy brown
        }
    }
}
