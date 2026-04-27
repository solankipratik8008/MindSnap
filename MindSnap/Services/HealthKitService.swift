//
//  HealthKitService.swift
//  MindSnap
//

import Foundation
import HealthKit

struct HealthMetric {
    let value: Double
    let unitLabel: String
}

final class HealthKitService {

    private let store = HKHealthStore()

    static let healthSupportedActivityTypes: Set<GoalActivityType> = [
        .walking,
        .running,
        .cycling,
        .swimming,
        .gym,
        .yoga,
        .meditation,
        .water
    ]

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        do {
            try await store.requestAuthorization(
                toShare: [],
                read: supportedTypes
            )
            return true
        } catch {
            print("HealthKit authorization failed: \(error)")
            return false
        }
    }

    func metricForToday(
        activityType: GoalActivityType,
        preferredUnit: String
    ) async -> HealthMetric? {
        guard isAvailable,
              let mapping = mapping(
                for: activityType,
                preferredUnit: preferredUnit
              ) else {
            return nil
        }

        do {
            let value = try await quantitySumToday(
                identifier: mapping.identifier,
                unit: mapping.healthUnit
            )
            return HealthMetric(
                value: value,
                unitLabel: mapping.displayUnit
            )
        } catch {
            print("HealthKit read failed: \(error)")
            return nil
        }
    }

    private var supportedTypes: Set<HKObjectType> {
        let identifiers: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .distanceWalkingRunning,
            .distanceCycling,
            .distanceSwimming,
            .appleExerciseTime,
            .dietaryWater
        ]

        return Set(
            identifiers.compactMap {
                HKObjectType.quantityType(forIdentifier: $0)
            }
        )
    }

    private func quantitySumToday(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit
    ) async throws -> Double {
        guard let quantityType = HKObjectType.quantityType(
            forIdentifier: identifier
        ) else {
            return 0
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: Date(),
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let value = statistics?
                    .sumQuantity()?
                    .doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func mapping(
        for activityType: GoalActivityType,
        preferredUnit: String
    ) -> (
        identifier: HKQuantityTypeIdentifier,
        healthUnit: HKUnit,
        displayUnit: String
    )? {
        let normalizedUnit = preferredUnit.lowercased()

        switch activityType {
        case .walking:
            if normalizedUnit == "steps" {
                return (.stepCount, .count(), "steps")
            }
            return distanceMapping(
                identifier: .distanceWalkingRunning,
                preferredUnit: normalizedUnit
            )

        case .running:
            if normalizedUnit == "minutes" {
                return (.appleExerciseTime, .minute(), "minutes")
            }
            return distanceMapping(
                identifier: .distanceWalkingRunning,
                preferredUnit: normalizedUnit
            )

        case .cycling:
            if normalizedUnit == "minutes" {
                return (.appleExerciseTime, .minute(), "minutes")
            }
            return distanceMapping(
                identifier: .distanceCycling,
                preferredUnit: normalizedUnit
            )

        case .swimming:
            if normalizedUnit == "minutes" {
                return (.appleExerciseTime, .minute(), "minutes")
            }
            return distanceMapping(
                identifier: .distanceSwimming,
                preferredUnit: normalizedUnit
            )

        case .gym, .yoga, .meditation:
            return (.appleExerciseTime, .minute(), "minutes")

        case .water:
            switch normalizedUnit {
            case "ml":
                return (.dietaryWater, .literUnit(with: .milli), "ml")
            case "l":
                return (.dietaryWater, .liter(), "L")
            case "oz":
                return (.dietaryWater, .fluidOunceUS(), "oz")
            default:
                return nil
            }

        default:
            return nil
        }
    }

    private func distanceMapping(
        identifier: HKQuantityTypeIdentifier,
        preferredUnit: String
    ) -> (
        identifier: HKQuantityTypeIdentifier,
        healthUnit: HKUnit,
        displayUnit: String
    ) {
        if preferredUnit == "miles" {
            return (identifier, .mile(), "miles")
        }
        return (identifier, .meterUnit(with: .kilo), "km")
    }
}
