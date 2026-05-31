import DeviceActivity
import SwiftUI

struct StatsView: View {
    @Environment(TimeTankModel.self) private var model
    @State private var showingMonthLog = false
    @State private var reportRefreshID = UUID()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    weekLog

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TODAY")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textMuted)

                            HStack(alignment: .firstTextBaseline) {
                                Text("\(Int(model.pollutionLevel * 100))")
                                    .font(.timeTankMetric(56))
                                    .foregroundStyle(Color.textDark)
                                Text("% murky")
                                    .font(.timeTankHeading(18))
                                    .foregroundStyle(Color.textMuted)
                            }

                            BudgetProgressBar(progress: model.pollutionLevel)
                        }
                    }

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DISTRACTION APPS")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textMuted)

                            if model.isRunningInSimulator {
                                Text("Real app usage, pickups, notifications, and first pickup only render on a signed iPhone with Screen Time authorization.")
                                    .font(.timeTankBody())
                                    .foregroundStyle(Color.textDark)
                            } else if model.hasSelection {
                                DeviceActivityReport(reportContext, filter: reportFilter)
                                    .frame(minHeight: CGFloat(model.selectedItemCount) * 56 + 80)
                                    .id(reportRefreshID)
                            } else {
                                Text("Pick distractions first. The report uses those selected app, category, and web tokens.")
                                    .font(.timeTankBody())
                                    .foregroundStyle(Color.textDark)
                            }
                        }
                    }

                    TimeTankCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("YOUR SCREEN TIME")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.textMuted)

                            if model.isRunningInSimulator {
                                Text("Total iPhone usage across all apps renders on a signed device with Screen Time authorization.")
                                    .font(.timeTankBody())
                                    .foregroundStyle(Color.textDark)
                            } else {
                                DeviceActivityReport(allAppsReportContext, filter: allAppsReportFilter)
                                    .frame(minHeight: 80)
                                    .id(reportRefreshID)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.warmWhite)
            .navigationTitle("Stats")
            .onAppear { reportRefreshID = UUID() }
            .sheet(isPresented: $showingMonthLog) {
                MonthFinnLogView(model: model)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var weekLog: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("WEEK")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.textMuted)
                Spacer()
                Button {
                    showingMonthLog = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.tideOrange)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open month log")
            }

            GeometryReader { proxy in
                let spacing: CGFloat = 2
                let cellWidth = max(32, (proxy.size.width - (spacing * 6)) / 7)
                let finnWidth = min(44, cellWidth)

                HStack(spacing: spacing) {
                    ForEach(weekDates, id: \.self) { date in
                        FinnDayCircle(
                            date: date,
                            pollutionLevel: pollutionLevel(for: date),
                            isToday: Calendar.current.isDateInToday(date),
                            size: finnWidth,
                            showsCircle: false,
                            plainHeight: finnWidth * 1.5
                        )
                        .frame(width: cellWidth)
                    }
                }
            }
            .frame(height: 82)
        }
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showingMonthLog = true
        }
    }

    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let sunday = calendar.date(byAdding: .day, value: 1 - weekday, to: today) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: sunday) }
    }

    private func pollutionLevel(for date: Date) -> Double? {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return model.pollutionLevel
        }

        let key = TimeTankStore.dayKey(for: date, calendar: calendar)
        return model.dailySnapshots.first { $0.dayKey == key }?.pollutionLevel
    }

    private var reportFilter: DeviceActivityFilter {
        let interval = Calendar.current.dateInterval(of: .day, for: Date()) ?? DateInterval(start: Date(), duration: 24 * 60 * 60)
        return DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone, .iPad]),
            applications: model.selection.applicationTokens,
            categories: model.selection.categoryTokens,
            webDomains: model.selection.webDomainTokens
        )
    }

    private var allAppsReportFilter: DeviceActivityFilter {
        let interval = Calendar.current.dateInterval(of: .day, for: Date()) ?? DateInterval(start: Date(), duration: 24 * 60 * 60)
        return DeviceActivityFilter(
            segment: .daily(during: interval),
            users: .all,
            devices: .init([.iPhone, .iPad])
        )
    }

    private var reportContext: DeviceActivityReport.Context {
        DeviceActivityReport.Context(TimeTankConstants.reportContextIdentifier)
    }

    private var allAppsReportContext: DeviceActivityReport.Context {
        DeviceActivityReport.Context(TimeTankConstants.allAppsReportContextIdentifier)
    }
}

private struct FinnDayCircle: View {
    let date: Date
    let pollutionLevel: Double?
    let isToday: Bool
    let size: CGFloat
    var showsCircle = true
    var plainHeight: CGFloat?

    var body: some View {
        VStack(spacing: 4) {
            finnImage
                .frame(width: size, height: imageHeight)

            Text(dayLabel)
                .font(.system(size: size < 38 ? 9 : 10, weight: .bold, design: .rounded))
                .foregroundStyle(isToday ? Color.tideOrange : Color.textMuted)
        }
    }

    @ViewBuilder
    private var finnImage: some View {
        if showsCircle {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                Circle()
                    .stroke(isToday ? Color.tideOrange : ringColor, lineWidth: isToday ? 2 : 1)

                stateImage
                    .padding(size * 0.06)
            }
        } else {
            stateImage
        }
    }

    private var imageHeight: CGFloat {
        showsCircle ? size : plainHeight ?? size
    }

    @ViewBuilder
    private var stateImage: some View {
        if let pollutionLevel {
            Image(faceName(for: pollutionLevel))
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "minus")
                .font(.system(size: size * 0.26, weight: .semibold))
                .foregroundStyle(Color.textMuted.opacity(0.55))
        }
    }

    private var dayLabel: String {
        date.formatted(.dateTime.weekday(.narrow))
    }

    private var backgroundColor: Color {
        guard let pollutionLevel else { return Color.cardBackground.opacity(0.55) }
        if pollutionLevel >= 0.8 { return Color.muddyBrown.opacity(0.15) }
        if pollutionLevel >= 0.4 { return Color.amber.opacity(0.16) }
        if pollutionLevel > 0 { return Color.tankTeal.opacity(0.14) }
        return Color.cardBackground
    }

    private var ringColor: Color {
        guard let pollutionLevel else { return Color.peachFoam }
        if pollutionLevel >= 0.8 { return Color.muddyBrown.opacity(0.5) }
        if pollutionLevel >= 0.4 { return Color.amber.opacity(0.55) }
        return Color.tankTeal.opacity(0.45)
    }

    private func faceName(for pollutionLevel: Double) -> String {
        switch pollutionLevel {
        case 0..<0.2:   return "FinnMascot"
        case 0.2..<0.4: return "FinnMascotAlert"
        case 0.4..<0.8: return "FinnMascotWorried"
        case 0.8..<1.0: return "FinnMascotSuffering"
        default:        return "FinnMascotDistressed"
        }
    }
}

private struct MonthFinnLogView: View {
    let model: TimeTankModel
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.textMuted)
                    }

                    ForEach(monthCells.indices, id: \.self) { index in
                        if let date = monthCells[index] {
                            FinnDayCircle(
                                date: date,
                                pollutionLevel: pollutionLevel(for: date),
                                isToday: Calendar.current.isDateInToday(date),
                                size: 34
                            )
                        } else {
                            Color.clear.frame(height: 48)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.warmWhite)
            .navigationTitle(monthTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.tideOrange)
                }
            }
        }
    }

    private var monthTitle: String {
        Date().formatted(.dateTime.month(.wide).year())
    }

    private var monthCells: [Date?] {
        let calendar = Calendar.current
        let today = Date()
        guard let month = calendar.dateInterval(of: .month, for: today) else { return [] }

        let firstDay = calendar.startOfDay(for: month.start)
        let weekday = calendar.component(.weekday, from: firstDay)
        let leading = max(0, weekday - 1)
        let dayRange = calendar.range(of: .day, in: .month, for: today) ?? 1..<1
        let dates = dayRange.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }

        return Array(repeating: nil, count: leading) + dates
    }

    private func pollutionLevel(for date: Date) -> Double? {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return model.pollutionLevel
        }

        let key = TimeTankStore.dayKey(for: date, calendar: calendar)
        return model.dailySnapshots.first { $0.dayKey == key }?.pollutionLevel
    }
}
