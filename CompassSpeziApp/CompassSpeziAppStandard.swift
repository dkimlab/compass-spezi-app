//
// This source file is part of the CompassSpeziApp based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseStorage
import FirebaseAuth
import HealthKitOnFHIR
import OSLog
@preconcurrency import PDFKit.PDFDocument
import Spezi
import SpeziAccount
import SpeziFirebaseAccount
import SpeziFirestore
import SpeziHealthKit
import SpeziOnboarding
import SpeziQuestionnaire
import SwiftUI

struct SampleInfo {
    let unit: HKUnit
        let fieldName: String
        let collectionName: String
}

actor CompassSpeziAppStandard: Standard,
                                   EnvironmentAccessible,
                                   HealthKitConstraint,
                                   ConsentConstraint,
                               AccountNotifyConstraint {
    // Helper function to return the sampleInfo dictionary
    func sampleInfoDictionary() -> [String: SampleInfo] {
        return exerciseMetricsInfo()
//                .merging(exerciseMetricsInfo(), uniquingKeysWith: { $1 })
                .merging(wheelChairMetricsInfo(), uniquingKeysWith: { $1 })
                .merging(activityMetricsInfo(), uniquingKeysWith: { $1 })
                .merging(vitalSignsInfo(), uniquingKeysWith: { $1 })
//                .merging(sleepMetricsInfo(), uniquingKeysWith: { $1 })
//                .merging(mobilityMetricsInfo(), uniquingKeysWith: { $1 })
    }
    
    func handleNewSamples<Sample>(_ addedSamples: some Collection,
                                  ofType sampleType: SpeziHealthKit.SampleType<Sample>) async where Sample : SpeziHealthKit._HKSampleWithSampleType {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        let firestoneDatabase = Firestore.firestore()
        let sampleInfo = sampleInfoDictionary()

        for sample in addedSamples {
            if let quantitySample = sample as? HKQuantitySample,
                let sampleData = sampleInfo[quantitySample.quantityType.identifier] {
                    // TODO: remove test
                    guard quantitySample.quantity.is(compatibleWith: sampleData.unit) else {
                        os_log("Incompatible unit: %{public}@ vs %{public}@",
                               sampleData.unit, quantitySample.quantityType)
                        continue
                    }
                            let value = quantitySample.quantity.doubleValue(for: sampleData.unit)
                            let data: [String: Any] = [
                                "type": sampleData.fieldName,
                                "value": sampleType.id == HKQuantityTypeIdentifier.oxygenSaturation.rawValue ? value : value,
                                // TODO: also account for mobility percentages
                                "timestamp": quantitySample.endDate
                            ]
                
                do {
                    try await firestoneDatabase.collection("users")
                        .document(userId)
                        .collection(sampleData.collectionName)
                        .addDocument(data: data)
                } catch {
                    print("Failed to upload \(sampleData.collectionName) data: \(error)")
                }
            }
        }
    }
    
    
    
    func exerciseMetricsInfo() -> [String: SampleInfo] {
        return [
            HKQuantityTypeIdentifier.stepCount.rawValue: SampleInfo(unit: .count(), fieldName: "steps", collectionName: "stepCountSamples"),
            HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue: SampleInfo(
                unit: .mile(), fieldName: "miles", collectionName: "distanceWalkingRunningSamples"),
            HKQuantityTypeIdentifier.runningSpeed.rawValue: SampleInfo(
                unit: .mile().unitDivided(by: .hour()), fieldName: "runningSpeed", collectionName: "runningSpeedSamples"),
            HKQuantityTypeIdentifier.runningStrideLength.rawValue: SampleInfo(
                unit: .meter(), fieldName: "strideLength", collectionName: "runningStrideLengthSamples"),
            HKQuantityTypeIdentifier.runningPower.rawValue: SampleInfo(unit: .watt(), fieldName: "power", collectionName: "runningPowerSamples"),
            HKQuantityTypeIdentifier.runningGroundContactTime.rawValue: SampleInfo(
                unit: HKUnit.secondUnit(with: .milli), fieldName: "contactTime", collectionName: "runningGroundContactTimeSamples"),
            HKQuantityTypeIdentifier.runningVerticalOscillation.rawValue: SampleInfo(
                unit: HKUnit(from: "cm"), fieldName: "verticalOscillation",
                collectionName: "runningVerticalOscillationSamples"),// TODO: confirm correct units
            HKQuantityTypeIdentifier.distanceCycling.rawValue: SampleInfo(
                unit: .mile(), fieldName: "cyclingDistance", collectionName: "distanceCyclingSamples")
        ]
    }
    
    func wheelChairMetricsInfo() -> [String: SampleInfo] {
        return [
            HKQuantityTypeIdentifier.pushCount.rawValue: SampleInfo(
                unit: .count(), fieldName: "pushCount", collectionName: "pushCountSamples"),
            HKQuantityTypeIdentifier.distanceWheelchair.rawValue: SampleInfo(
                unit: .mile(), fieldName: "wheelchairDistance", collectionName: "distanceWheelchairSamples")
        ]
    }
    
    func activityMetricsInfo() -> [String: SampleInfo] {
        return [
            HKQuantityTypeIdentifier.swimmingStrokeCount.rawValue: SampleInfo(
                unit: .count(), fieldName: "swimmingStrokes", collectionName: "swimmingStrokeCountSamples"),
            HKQuantityTypeIdentifier.distanceSwimming.rawValue: SampleInfo(
                unit: .mile(), fieldName: "swimmingDistance", collectionName: "distanceSwimmingSamples"),
            HKQuantityTypeIdentifier.distanceDownhillSnowSports.rawValue: SampleInfo(
                unit: .mile(), fieldName: "snowSportsDistance", collectionName: "distanceDownhillSnowSportsSamples"),
            HKQuantityTypeIdentifier.basalEnergyBurned.rawValue: SampleInfo(
                unit: .kilocalorie(), fieldName: "basalEnergy", collectionName: "basalEnergyBurnedSamples"),
            HKQuantityTypeIdentifier.activeEnergyBurned.rawValue: SampleInfo(
                unit: .kilocalorie(), fieldName: "activeEnergy", collectionName: "activeEnergyBurnedSamples"),
            HKQuantityTypeIdentifier.flightsClimbed.rawValue: SampleInfo(
                unit: .count(), fieldName: "flights", collectionName: "flightsClimbedSamples"),
            HKQuantityTypeIdentifier.appleExerciseTime.rawValue: SampleInfo(
                unit: .second(), fieldName: "exerciseTime", collectionName: "appleExerciseTimeSamples"),
            HKQuantityTypeIdentifier.appleMoveTime.rawValue: SampleInfo(
                unit: .second(), fieldName: "moveTime", collectionName: "appleMoveTimeSamples"),
            //                   HKQuantityTypeIdentifier.appleStandHour.rawValue: (.count(), "standHours", "appleStandHourSamples"),//TODO: handle as category type
            HKQuantityTypeIdentifier.appleStandTime.rawValue: SampleInfo(
                unit: .second(),fieldName: "appleStandTime",
                collectionName: "appleStandTimeSamples"),
            HKQuantityTypeIdentifier.vo2Max.rawValue: SampleInfo(
                unit: HKUnit.literUnit(with: .milli)
                    .unitDivided(by: HKUnit.gramUnit(with: .kilo))
                    .unitDivided(by: .minute()), fieldName: "vo2Max", collectionName: "vo2MaxSamples"),//TODO: confirm correct units
            //                   HKQuantityTypeIdentifier.lowCardioFitnessEvent.rawValue: (.count(), "lowCardioFitness", "lowCardioFitnessEventSamples"), //TODO: handle as category type
        ]
    }
    
    func vitalSignsInfo() -> [String: SampleInfo] {
        return [
            HKQuantityTypeIdentifier.heartRate.rawValue: SampleInfo(
                unit: HKUnit.count().unitDivided(by: .minute()), fieldName: "bpm", collectionName: "heartRateSamples"),
            // TODO: add lowHeartRateEvent category type
            // TODO: add highHeartRateEvent category type
            // TODO: add irregularHeartRateEvent category type
            HKQuantityTypeIdentifier.restingHeartRate.rawValue: SampleInfo(
                unit: HKUnit.count().unitDivided(by: .minute()), fieldName: "restingBpm", collectionName: "restingHeartRateSamples"),
//            HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue: SampleInfo(
//                unit: .second().unitDivided(by: HKUnit(from: "milli")),
//                fieldName: "HRV_SDNN", collectionName: "heartRateVariabilitySDNNSamples"), //TODO: confirm correct units
            HKQuantityTypeIdentifier.heartRateRecoveryOneMinute.rawValue: SampleInfo(
                unit: HKUnit.count().unitDivided(by: .minute()),
                fieldName: "heartRateRecoveryOneMinute",
                collectionName: "heartRateRecoveryOneMinuteSamples"),
            // TODO: add atrialFibrillationBurden category type
            HKQuantityTypeIdentifier.walkingHeartRateAverage.rawValue: SampleInfo(
                unit: HKUnit.count().unitDivided(by: .minute()), fieldName: "walkingHeartRate", collectionName: "walkingHeartRateSamples"),
            HKQuantityTypeIdentifier.oxygenSaturation.rawValue: SampleInfo(
                unit: .percent(), fieldName: "oxygen", collectionName: "bloodOxygenSamples"),
            HKQuantityTypeIdentifier.bodyTemperature.rawValue: SampleInfo(
                unit: .degreeCelsius(), fieldName: "bodyTemp", collectionName: "bodyTemperatureSamples"),
            HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue: SampleInfo(
                unit: .millimeterOfMercury(), fieldName: "systolicBloodPressure", collectionName: "bloodPressureSystolicSamples"),
            HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue: SampleInfo(
                unit: .millimeterOfMercury(), fieldName: "diastolicBloodPressure", collectionName: "bloodPressureDiastolicSamples"),
            HKQuantityTypeIdentifier.respiratoryRate.rawValue: SampleInfo(
                unit: HKUnit.count().unitDivided(by: HKUnit.minute()),
                fieldName: "respiratoryRate", collectionName: "respiratoryRateSamples") //TODO: confirm correct units
        ]
    }
    
    func sleepMetricsInfo() -> [String: SampleInfo] {
        return [
            //TODO: add sleepAnalysis category type
            HKQuantityTypeIdentifier.appleSleepingWristTemperature.rawValue: SampleInfo(
                unit: .degreeCelsius(),
                fieldName: "appleSleepingWristTemperature",
                collectionName: "appleSleepingWristTemperatureSamples"),
            HKQuantityTypeIdentifier.appleSleepingBreathingDisturbances.rawValue: SampleInfo(
                unit: .count(),
                fieldName: "appleSleepingBreathingDisturbances",
                collectionName: "appleSleepingBreathingDisturbancesSamples")
        ]
    }
    
    func mobilityMetricsInfo() -> [String: SampleInfo] {
        return [
            HKQuantityTypeIdentifier.appleWalkingSteadiness.rawValue: SampleInfo(
                unit: .percent(),
                fieldName: "appleWalkingSteadiness",
                collectionName: "appleWalkingSteadinessSamples"),
            
            //TODO: add appleWalkingSteadinessEvent category type
            HKQuantityTypeIdentifier.sixMinuteWalkTestDistance.rawValue: SampleInfo(
                unit: .meter(),
                fieldName: "sixMinuteWalkTestDistance",
                collectionName: "sixMinuteWalkTestDistanceSamples"),
            HKQuantityTypeIdentifier.walkingSpeed.rawValue: SampleInfo(
                unit: .meter().unitDivided(by: .second()),
                fieldName: "walkingSpeed",
                collectionName: "walkingSpeedSamples"),
            HKQuantityTypeIdentifier.walkingStepLength.rawValue: SampleInfo(
                unit: .meter(),
                fieldName: "walkingStepLength",
                collectionName: "walkingStepLengthSamples"),
            HKQuantityTypeIdentifier.walkingAsymmetryPercentage.rawValue: SampleInfo(
                unit: .percent(),
                fieldName: "walkingAsymmetryPercentage",
                collectionName: "walkingAsymmetryPercentageSamples"),
            HKQuantityTypeIdentifier.walkingDoubleSupportPercentage.rawValue: SampleInfo(
                unit: .percent(),
                fieldName: "walkingDoubleSupportPercentage",
                collectionName: "walkingDoubleSupportPercentageSamples"),
            HKQuantityTypeIdentifier.stairAscentSpeed.rawValue: SampleInfo(
                unit: .meter().unitDivided(by: .second()),
                fieldName: "stairAscentSpeed", collectionName: "stairAscentSpeedSamples"),
            HKQuantityTypeIdentifier.stairDescentSpeed.rawValue: SampleInfo( unit: .meter().unitDivided(by: .second()),
                                                                             fieldName: "stairDescentSpeed",
                                                                             collectionName: "stairDescentSpeedSamples")
        ]
    }
    
    func handleDeletedObjects<Sample>(_ deletedObjects: some
                                      Collection<HKDeletedObject>, ofType sampleType: SpeziHealthKit.SampleType<Sample>)
                                      async where Sample : SpeziHealthKit._HKSampleWithSampleType {
       
    }
    
    @Application(\.logger) private var logger

    @Dependency(FirebaseConfiguration.self) private var configuration

    init() {}


    func add(sample: HKSample) async {
        if FeatureFlags.disableFirebase {
            logger.debug("Received new HealthKit sample: \(sample)")
            return
        }
        
        do {
            try await healthKitDocument(id: sample.id)
                .setData(from: sample.resource)
        } catch {
            logger.error("Could not store HealthKit sample: \(error)")
        }
    }
    
    func remove(sample: HKDeletedObject) async {
        if FeatureFlags.disableFirebase {
            logger.debug("Received new removed healthkit sample with id \(sample.uuid)")
            return
        }
        
        do {
            try await healthKitDocument(id: sample.uuid).delete()
        } catch {
            logger.error("Could not remove HealthKit sample: \(error)")
        }
    }

    // periphery:ignore:parameters isolation
    func add(response: ModelsR4.QuestionnaireResponse, isolation: isolated (any Actor)? = #isolation) async {
        let id = response.identifier?.value?.value?.string ?? UUID().uuidString
        
        if FeatureFlags.disableFirebase {
            let jsonRepresentation = (try? String(data: JSONEncoder().encode(response), encoding: .utf8)) ?? ""
            await logger.debug("Received questionnaire response: \(jsonRepresentation)")
            return
        }
        
        do {
            try await configuration.userDocumentReference
                .collection("QuestionnaireResponse") // Add all HealthKit sources in a /QuestionnaireResponse collection.
                .document(id) // Set the document identifier to the id of the response.
                .setData(from: response)
        } catch {
            await logger.error("Could not store questionnaire response: \(error)")
        }
    }
    
    
    private func healthKitDocument(id uuid: UUID) async throws -> DocumentReference {
        try await configuration.userDocumentReference
            .collection("HealthKit") // Add all HealthKit sources in a /HealthKit collection.
            .document(uuid.uuidString) // Set the document identifier to the UUID of the document.
    }

    func respondToEvent(_ event: AccountNotifications.Event) async {
        if case let .deletingAccount(accountId) = event {
            do {
                try await configuration.userDocumentReference(for: accountId).delete()
            } catch {
                logger.error("Could not delete user document: \(error)")
            }
        }
    }
    
    /// Stores the given consent form in the user's document directory with a unique timestamped filename.
    ///
    /// - Parameter consent: The consent form's data to be stored as a `PDFDocument`.
    @MainActor
    func store(consent: ConsentDocumentExport) async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = formatter.string(from: Date())

        guard !FeatureFlags.disableFirebase else {
            guard let basePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                await logger.error("Could not create path for writing consent form to user document directory.")
                return
            }
            
            let filePath = basePath.appending(path: "consentForm_\(dateString).pdf")
            await consent.pdf.write(to: filePath)
            
            return
        }
        
        do {
            guard let consentData = await consent.pdf.dataRepresentation() else {
                await logger.error("Could not store consent form.")
                return
            }

            let metadata = StorageMetadata()
            metadata.contentType = "application/pdf"
            _ = try await configuration.userBucketReference
                .child("consent/\(dateString).pdf")
                .putDataAsync(consentData, metadata: metadata) { @Sendable _ in }
        } catch {
            await logger.error("Could not store consent form: \(error)")
        }
    }
}
