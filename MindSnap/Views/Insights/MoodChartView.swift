//
//  MoodChartView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// MoodChartView.swift
// MindSnap — Premium Monochrome Mood Chart
//
// SAFE UI UPDATE:
// 1. Keeps same chart data logic
// 2. Keeps safe proxy.plotFrame optional binding
// 3. Keeps touch/drag tooltip behavior
// 4. Keeps mood colors as useful accents
// 5. Updates card, tooltip, grid, legend to black/white theme
// ============================================================

import SwiftUI
import Charts

struct MoodChartView: View {

    let data: [MoodDataPoint]
    let selectedPeriod: TimePeriod

    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedDataPoint: MoodDataPoint? = nil

    // --------------------------------------------------------
    // MARK: - Premium Theme
    // --------------------------------------------------------
    private var cardBackground: Color {
        colorScheme == .dark
        ? Color(red: 0.09, green: 0.09, blue: 0.10)
        : Color.white
    }

    private var softBackground: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.07)
        : Color.black.opacity(0.045)
    }

    private var primaryText: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryText: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.62)
        : Color.black.opacity(0.52)
    }

    private var tertiaryText: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.38)
        : Color.black.opacity(0.34)
    }

    private var borderColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.08)
        : Color.black.opacity(0.07)
    }

    private var shadowColor: Color {
        colorScheme == .dark
        ? Color.clear
        : Color.black.opacity(0.06)
    }

    private var gridLineColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.08)
        : Color.black.opacity(0.07)
    }

    private var noEntryColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.14)
        : Color.black.opacity(0.10)
    }

    private func premiumCard(cornerRadius: CGFloat = 20) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(
                color: shadowColor,
                radius: 12,
                x: 0,
                y: 6
            )
    }

    // --------------------------------------------------------
    // MARK: - Body
    // --------------------------------------------------------
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // ---- Chart Title ----
            HStack(alignment: .center) {
                HStack(spacing: 9) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(colorScheme == .dark ? Color.white : Color.black)
                            .frame(width: 32, height: 32)

                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mood Trend")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(primaryText)

                        Text("Bar height shows mood intensity")
                            .font(.caption)
                            .foregroundStyle(secondaryText)
                    }
                }

                Spacer()

                Text(selectedPeriod.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(primaryText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(softBackground)
                            .overlay(
                                Capsule()
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
            }

            // ---- The Chart ----
            Chart {
                ForEach(data) { point in
                    BarMark(
                        x: .value("Day", point.shortLabel),
                        y: .value(
                            "Mood Score",
                            point.entryCount == 0
                                ? 0.05
                                : max(0.1, abs(point.averageScore))
                        )
                    )
                    .foregroundStyle(
                        point.entryCount == 0
                            ? noEntryColor
                            : point.mood.color.opacity(colorScheme == .dark ? 0.90 : 0.78)
                    )
                    .cornerRadius(7)
                    .annotation(position: .top) {
                        if point.entryCount > 0 {
                            Text(point.mood.emoji)
                                .font(
                                    .system(
                                        size: selectedPeriod == .week ? 14 : 10
                                    )
                                )
                        }
                    }
                }

                if let selected = selectedDataPoint {
                    RuleMark(
                        x: .value("Selected", selected.shortLabel)
                    )
                    .foregroundStyle(primaryText.opacity(0.22))
                    .lineStyle(
                        StrokeStyle(
                            lineWidth: 2,
                            dash: [4, 2]
                        )
                    )
                    .annotation(
                        position: .top,
                        alignment: .center
                    ) {
                        tooltipView(for: selected)
                    }
                }
            }
            .chartYScale(domain: 0...1.05)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(gridLineColor)

                    AxisValueLabel {
                        if let doubleVal = value.as(Double.self) {
                            Text(yAxisLabel(for: doubleVal))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(secondaryText)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine()
                        .foregroundStyle(gridLineColor.opacity(0.75))

                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(secondaryText)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleChartTouch(
                                        at: value.location,
                                        proxy: proxy,
                                        geometry: geometry
                                    )
                                }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(
                                        deadline: .now() + 2.0
                                    ) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedDataPoint = nil
                                        }
                                    }
                                }
                        )
                }
            }
            .frame(height: 220)

            // ---- Legend ----
            moodLegend
        }
        .padding(16)
        .background(premiumCard(cornerRadius: 20))
    }

    // --------------------------------------------------------
    // MARK: - Tooltip
    // --------------------------------------------------------
    @ViewBuilder
    private func tooltipView(for point: MoodDataPoint) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(point.mood.emoji)

                Text(point.mood.displayName)
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .foregroundStyle(primaryText)

            Text(String(format: "Score: %+.2f", point.averageScore))
                .font(.caption2)
                .foregroundStyle(secondaryText)

            Text("\(point.entryCount) \(point.entryCount == 1 ? "entry" : "entries")")
                .font(.caption2)
                .foregroundStyle(secondaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            point.mood.color.opacity(
                                colorScheme == .dark ? 0.30 : 0.20
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: colorScheme == .dark
                    ? Color.clear
                    : Color.black.opacity(0.12),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Legend
    // --------------------------------------------------------
    private var moodLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(MoodType.allCases, id: \.self) { mood in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(mood.color.opacity(colorScheme == .dark ? 0.90 : 0.75))
                            .frame(width: 8, height: 8)

                        Text(mood.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(secondaryText)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(softBackground)
                            .overlay(
                                Capsule()
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
                }

                HStack(spacing: 5) {
                    Circle()
                        .fill(noEntryColor)
                        .frame(width: 8, height: 8)

                    Text("No entry")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(secondaryText)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(softBackground)
                        .overlay(
                            Capsule()
                                .stroke(borderColor, lineWidth: 1)
                        )
                )
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Private Helpers
    // --------------------------------------------------------
    private func handleChartTouch(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        // Safe optional binding. Do not force unwrap plotFrame.
        guard let plotFrame = proxy.plotFrame else { return }

        let xPosition = location.x - geometry[plotFrame].origin.x

        guard let label: String = proxy.value(atX: xPosition) else {
            return
        }

        if let match = data.first(where: { $0.shortLabel == label }) {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDataPoint = match
            }
        }
    }

    private func yAxisLabel(for value: Double) -> String {
        switch value {
        case 0:
            return "0"
        case 0.5:
            return "Mid"
        case 1.0:
            return "High"
        default:
            return ""
        }
    }
}

// ============================================================
// Preview
// ============================================================
#Preview("Light Mode") {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    let sampleMoods: [(MoodType, Double)] = [
        (.sad, -0.65),
        (.anxious, -0.32),
        (.neutral, 0.05),
        (.calm, 0.28),
        (.happy, 0.75),
        (.calm, 0.41),
        (.happy, 0.88)
    ]

    let sampleData = sampleMoods.enumerated().map { index, moodScore in
        let date = calendar.date(
            byAdding: .day,
            value: -(6 - index),
            to: today
        ) ?? today

        return MoodDataPoint(
            date: date,
            mood: moodScore.0,
            averageScore: moodScore.1,
            entryCount: index == 2 ? 0 : 1
        )
    }

    ScrollView {
        MoodChartView(
            data: sampleData,
            selectedPeriod: .week
        )
        .padding(16)
    }
    .background(Color(red: 0.96, green: 0.96, blue: 0.97))
}

#Preview("Dark Mode") {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    let sampleMoods: [(MoodType, Double)] = [
        (.sad, -0.65),
        (.anxious, -0.32),
        (.neutral, 0.05),
        (.calm, 0.28),
        (.happy, 0.75),
        (.calm, 0.41),
        (.happy, 0.88)
    ]

    let sampleData = sampleMoods.enumerated().map { index, moodScore in
        let date = calendar.date(
            byAdding: .day,
            value: -(6 - index),
            to: today
        ) ?? today

        return MoodDataPoint(
            date: date,
            mood: moodScore.0,
            averageScore: moodScore.1,
            entryCount: index == 2 ? 0 : 1
        )
    }

    ScrollView {
        MoodChartView(
            data: sampleData,
            selectedPeriod: .week
        )
        .padding(16)
    }
    .background(Color(red: 0.03, green: 0.03, blue: 0.035))
    .preferredColorScheme(.dark)
}
