//
// This source file is part of the CompassSpeziApp based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import class FirebaseFirestore.FirestoreSettings
import class FirebaseFirestore.MemoryCacheSettings
import Spezi
import SpeziAccount
import SpeziFirebaseAccount
import SpeziFirebaseAccountStorage
import SpeziFirebaseStorage
import SpeziFirestore
import SpeziHealthKit
import SpeziNotifications
import SpeziOnboarding
import SpeziScheduler
import SwiftUI


class CompassSpeziAppDelegate: SpeziAppDelegate {
    override var configuration: Configuration {
        Configuration(standard: CompassSpeziAppStandard()) {
            if !FeatureFlags.disableFirebase {
                AccountConfiguration(
                    service: FirebaseAccountService(providers: [.emailAndPassword], emulatorSettings: accountEmulator),
                    storageProvider: FirestoreAccountStorage(storeIn: FirebaseConfiguration.userCollection),
                    configuration: [
                        .requires(\.userId),
                        .requires(\.name),
                        
                        //                        .requires(\.accountId),
                        
                        // additional values stored using the `FirestoreAccountStorage` within our Standard implementation
                        .collects(\.genderIdentity),
                        .collects(\.dateOfBirth),
//                        .collects(\.compassID) 
                    ]
                )

                firestore
                if FeatureFlags.useFirebaseEmulator {
                    FirebaseStorageConfiguration(emulatorSettings: (host: "10.0.0.175", port: 9199)) /* TODO: fix the hardcoded IP */
                } else {
                    FirebaseStorageConfiguration()
                }
            }

            healthKit
            CompassSpeziAppScheduler()
            Scheduler()
            OnboardingDataSource()

            Notifications()
        }
    }

    private var accountEmulator: (host: String, port: Int)? {
        if FeatureFlags.useFirebaseEmulator {
            (host: "10.0.0.175", port: 9099) /* TODO: fix the hardcoded IP */
        } else {
            nil
        }
    }

    
    private var firestore: Firestore {
        let settings = FirestoreSettings()
        if FeatureFlags.useFirebaseEmulator {
            settings.host = "10.0.0.175:8080" /* TODO: fix the hardcoded IP */
            settings.cacheSettings = MemoryCacheSettings()
            settings.isSSLEnabled = false
        }
        
        return Firestore(
            settings: settings
        )
    }
    
    private var healthKit: HealthKit {
        HealthKit {
            let exercise = configureExerciseMetrics()
            let wheelChair = configureWheelChairMetrics()
            let activity = configureActivityMetrics()
            let vitals = configureVitalSigns()
            let sleep = configureSleepMetrics()
            let mobility = configureMobilityMetrics()
            let readAccess = configureReadAccess()
            
            return exercise + wheelChair + activity + vitals + sleep + mobility + [readAccess]
        }
    }

    
    private func configureExerciseMetrics() -> [any HealthKitConfigurationComponent] {
        // Exercise Metrics
        return [
            CollectSample(.stepCount, continueInBackground: true),
            CollectSample(.distanceWalkingRunning, continueInBackground: true),
            CollectSample(.runningSpeed, continueInBackground: true),
            CollectSample(.runningStrideLength, continueInBackground: true),
            CollectSample(.runningPower, continueInBackground: true),
            CollectSample(.runningGroundContactTime, continueInBackground: true),
            CollectSample(.runningVerticalOscillation, continueInBackground: true),
            CollectSample(.distanceCycling, continueInBackground: true)
        ]
    }
    
    private func configureWheelChairMetrics() -> [any HealthKitConfigurationComponent] {
        // Wheelchair
        return [
            CollectSample(.pushCount, continueInBackground: true),
            CollectSample(.distanceWheelchair, continueInBackground: true),
            
        ]
    }
    
    private func configureActivityMetrics() -> [any HealthKitConfigurationComponent] {
        // Activity & Energy
        return [
            CollectSample(.swimmingStrokeCount, continueInBackground: true),
            CollectSample(.distanceSwimming, continueInBackground: true),
            CollectSample(.distanceDownhillSnowSports, continueInBackground: true),
            CollectSample(.basalEnergyBurned, continueInBackground: true),
            CollectSample(.activeEnergyBurned, continueInBackground: true),
            CollectSample(.flightsClimbed, continueInBackground: true),
            CollectSample(.appleExerciseTime, continueInBackground: true),
            CollectSample(.appleMoveTime, continueInBackground: true),
            CollectSample(.appleStandHour, continueInBackground: true),
            CollectSample(.appleStandTime, continueInBackground: true),
            CollectSample(.vo2Max, continueInBackground: true),
            CollectSample(.lowCardioFitnessEvent, continueInBackground: true)
        ]
    }
    
    private func configureVitalSigns() -> [any HealthKitConfigurationComponent] {
        // Vital Signs
        return [
            CollectSample(.heartRate, continueInBackground: true),
            CollectSample(.lowHeartRateEvent, continueInBackground: true),
            CollectSample(.highHeartRateEvent, continueInBackground: true),
            CollectSample(.irregularHeartRhythmEvent, continueInBackground: true),
            CollectSample(.restingHeartRate, continueInBackground: true),
            CollectSample(.heartRateVariabilitySDNN, continueInBackground: true),
            CollectSample(.heartRateRecoveryOneMinute, continueInBackground: true),
            CollectSample(.atrialFibrillationBurden, continueInBackground: true),
            CollectSample(.walkingHeartRateAverage, continueInBackground: true),
            CollectSample(.bloodOxygen, continueInBackground: true),
            CollectSample(.bodyTemperature, continueInBackground: true),
            CollectSample(.bloodPressureSystolic, continueInBackground: true),
            CollectSample(.bloodPressureDiastolic, continueInBackground: true),
            CollectSample(.respiratoryRate, continueInBackground: true)
        ]
    }
    
    private func configureSleepMetrics() -> [any HealthKitConfigurationComponent] {
        // Sleep
        return [
            CollectSample(.sleepAnalysis, continueInBackground: true),
            CollectSample(.appleSleepingWristTemperature, continueInBackground: true),
            CollectSample(.appleSleepingBreathingDisturbances, continueInBackground: true)
        ]
    }
    
    private func configureMobilityMetrics() -> [any HealthKitConfigurationComponent] {
        // Mobility
        return [
            CollectSample(.appleWalkingSteadiness, continueInBackground: true),
            CollectSample(.appleWalkingSteadinessEvent, continueInBackground: true),
            CollectSample(.sixMinuteWalkTestDistance, continueInBackground: true),
            CollectSample(.walkingSpeed, continueInBackground: true),
            CollectSample(.walkingStepLength, continueInBackground: true),
            CollectSample(.walkingAsymmetryPercentage, continueInBackground: true),
            CollectSample(.walkingDoubleSupportPercentage, continueInBackground: true),
            CollectSample(.stairAscentSpeed, continueInBackground: true),
            CollectSample(.stairDescentSpeed, continueInBackground: true)
        ]
    }
    
    private func configureReadAccess() -> any HealthKitConfigurationComponent {
        // Read Access
        let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
                .stepCount, .distanceWalkingRunning, .runningSpeed, .runningStrideLength,
                .runningPower, .runningGroundContactTime, .runningVerticalOscillation, .distanceCycling,
                .pushCount, .distanceWheelchair, .swimmingStrokeCount, .distanceSwimming,
                .distanceDownhillSnowSports, .basalEnergyBurned, .activeEnergyBurned, .flightsClimbed,
                .appleExerciseTime, .appleMoveTime, .appleStandTime, .vo2Max, .heartRate,
                .restingHeartRate, .heartRateVariabilitySDNN, .heartRateRecoveryOneMinute,
                .atrialFibrillationBurden, .walkingHeartRateAverage, .oxygenSaturation, .bodyTemperature,
                .bloodPressureSystolic, .bloodPressureDiastolic, .respiratoryRate,
                .appleSleepingWristTemperature, .appleSleepingBreathingDisturbances,
                .appleWalkingSteadiness, .sixMinuteWalkTestDistance, .walkingSpeed,
                .walkingStepLength, .walkingAsymmetryPercentage, .walkingDoubleSupportPercentage,
                .stairAscentSpeed, .stairDescentSpeed
        ]
        
        let categoryIdentifiers: [HKCategoryTypeIdentifier] = [
                .appleStandHour, .lowCardioFitnessEvent, .lowHeartRateEvent, .highHeartRateEvent,
                .irregularHeartRhythmEvent, .sleepAnalysis, .appleWalkingSteadinessEvent

        ]
        let quantityTypes: Set<SampleType<HKQuantitySample>> = Set(
                quantityIdentifiers.compactMap { SampleType<HKQuantitySample>($0) }
            )
            
            let categoryTypes: Set<SampleType<HKCategorySample>> = Set(
                categoryIdentifiers.compactMap { SampleType<HKCategorySample>($0) }
            )
        
        // Optionally enable background delivery here
        let healthStore = HKHealthStore()
        for sample in quantityTypes {
            healthStore.enableBackgroundDelivery(for: sample.hkSampleType, frequency: .immediate) { success, error in
                print("[HealthKit] \(sample.hkSampleType.identifier): \(success ? "✅ enabled" : "❌ failed") \(error?.localizedDescription ?? "")")
            }
        }

        for sample in categoryTypes {
            healthStore.enableBackgroundDelivery(for: sample.hkSampleType, frequency: .immediate) { success, error in
                print("[HealthKit] \(sample.hkSampleType.identifier): \(success ? "✅ enabled" : "❌ failed") \(error?.localizedDescription ?? "")")
            }
        }

            
            return RequestReadAccess(quantity: quantityTypes, category: categoryTypes)
    }
}
