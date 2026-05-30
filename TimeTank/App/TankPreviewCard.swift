#if DEBUG
import SwiftUI

struct TankPreviewCard: View {
    @State private var previewPollution: Double = 0

    private var faceName: String {
        switch previewPollution {
        case 0..<0.2:  return "Blissful"
        case 0.2..<0.4: return "Alert"
        case 0.4..<0.6: return "Worried"
        case 0.6..<1.0: return "Distressed"
        default:        return "Suffering"
        }
    }

    private var faceColor: Color {
        switch previewPollution {
        case 0..<0.2:  return .tankTeal
        case 0.2..<0.4: return .tankTeal
        case 0.4..<0.6: return .amber
        case 0.6..<1.0: return .amber
        default:        return .muddyBrown
        }
    }

    var body: some View {
        TimeTankCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("TANK PREVIEW")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textMuted)
                    Spacer()
                    Text(faceName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(faceColor)
                    Text("·")
                        .foregroundStyle(Color.textMuted)
                    Text("\(Int(previewPollution * 100))%")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.textMuted)
                }

                FocusTankView(pollutionLevel: previewPollution)
                    .frame(height: 220)

                VStack(spacing: 8) {
                    Slider(value: $previewPollution, in: 0...1, step: 0.01)
                        .tint(.tideOrange)

                    // Threshold tick labels
                    HStack(spacing: 0) {
                        ForEach(["0", "20", "40", "60", "80", "100"], id: \.self) { label in
                            Text(label)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.textMuted)
                            if label != "100" { Spacer() }
                        }
                    }
                }

                // Threshold quick-jump buttons
                HStack(spacing: 8) {
                    ForEach([0.0, 0.2, 0.4, 0.6, 0.8, 1.0], id: \.self) { level in
                        Button {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                previewPollution = level
                            }
                        } label: {
                            Text("\(Int(level * 100))%")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(previewPollution == level ? Color.white : Color.tideOrange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(previewPollution == level ? Color.tideOrange : Color.tideOrange.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.2), value: previewPollution)
                    }
                }
            }
        }
    }
}
#endif
