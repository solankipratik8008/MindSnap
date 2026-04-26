//
//  MoodChartView.swift
//  MindSnap
//
//  Created by Pratik Solanki on 2026-04-21.
//

// ============================================================
// MoodChartView.swift
// MindSnap — FIXED VERSION
//
// WHAT CHANGED:
// Fixed deprecated plotAreaFrame → plotFrame
// Used safe optional binding instead of force unwrap (!)
// to prevent potential crashes
// ============================================================

import SwiftUI
import Charts

struct MoodChartView: View {

    let data: [MoodDataPoint]
    let selectedPeriod: TimePeriod

    @State private var selectedDataPoint: MoodDataPoint? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // ---- Chart Title ----
            HStack {
                Text("Mood Trend")
                    .font(.headline)
                Spacer()
                Text("Bar height = positivity")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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
                            ? Color.gray.opacity(0.2)
                            : point.mood.color.opacity(0.85)
                    )
                    .cornerRadius(6)
                    .annotation(position: .top) {
                        if point.entryCount > 0 {
                            Text(point.mood.emoji)
                                .font(.system(size:
                                    selectedPeriod == .week ? 14 : 10
                                ))
                        }
                    }
                }

                if let selected = selectedDataPoint {
                    RuleMark(
                        x: .value("Selected", selected.shortLabel)
                    )
                    .foregroundStyle(Color.purple.opacity(0.3))
                    .lineStyle(StrokeStyle(
                        lineWidth: 2,
                        dash: [4, 2]
                    ))
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
                        .foregroundStyle(Color.gray.opacity(0.2))
                    AxisValueLabel {
                        if let doubleVal = value.as(Double.self) {
                            Text(yAxisLabel(for: doubleVal))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                        .foregroundStyle(Color.gray.opacity(0.15))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
                                        withAnimation {
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: .black.opacity(0.06),
                    radius: 8, x: 0, y: 3
                )
        )
    }

    // --------------------------------------------------------
    // MARK: - Subviews
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

            Text(String(format: "Score: %+.2f", point.averageScore))
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("\(point.entryCount) \(point.entryCount == 1 ? "entry" : "entries")")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(point.mood.color.opacity(0.3), lineWidth: 1)
        )
    }

    private var moodLegend: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MoodType.allCases, id: \.self) { mood in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(mood.color)
                            .frame(width: 8, height: 8)
                        Text(mood.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Text("No entry")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // --------------------------------------------------------
    // MARK: - Private Helpers
    // --------------------------------------------------------

    // --------------------------------------------------------
    // handleChartTouch(at:proxy:geometry:)
    //
    // FIXED: Replaced force unwrap proxy.plotFrame!
    // with safe optional binding using guard let.
    //
    // OLD (dangerous):
    //   geometry[proxy.plotFrame!].origin.x
    //   → crashes if plotFrame is nil 💥
    //
    // NEW (safe):
    //   guard let plotFrame = proxy.plotFrame else { return }
    //   geometry[plotFrame].origin.x
    //   → never crashes, just skips if nil ✅
    // --------------------------------------------------------
    private func handleChartTouch(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        // ---- SAFE: guard let instead of force unwrap ----
        // If plotFrame is nil for any reason → just return
        // instead of crashing the entire app
        guard let plotFrame = proxy.plotFrame else { return }

        // Now safe to access — plotFrame is guaranteed non-nil
        let xPosition = location.x - geometry[plotFrame].origin.x

        // Ask the chart proxy what X value is at this pixel
        guard let label: String = proxy.value(atX: xPosition) else {
            return
        }

        // Find matching data point
        if let match = data.first(where: { $0.shortLabel == label }) {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedDataPoint = match
            }
        }
    }

    private func yAxisLabel(for value: Double) -> String {
        switch value {
        case 0:   return "0"
        case 0.5: return "Mid"
        case 1.0: return "High"
        default:  return ""
        }
    }
}

// ============================================================
// Preview
// ============================================================
#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    let sampleMoods: [(MoodType, Double)] = [
        (.sad,     -0.65),
        (.anxious, -0.32),
        (.neutral,  0.05),
        (.calm,     0.28),
        (.happy,    0.75),
        (.calm,     0.41),
        (.happy,    0.88)
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
    .background(Color(.systemGroupedBackground))
}
