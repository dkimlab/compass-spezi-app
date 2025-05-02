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
                    service: FirebaseAccountService(providers: [.emailAndPassword, .signInWithApple], emulatorSettings: accountEmulator),
                    storageProvider: FirestoreAccountStorage(storeIn: FirebaseConfiguration.userCollection),
                    configuration: [
                        .requires(\.userId),
                        .requires(\.name),

                        // additional values stored using the `FirestoreAccountStorage` within our Standard implementation
                        .collects(\.genderIdentity),
                        .collects(\.dateOfBirth)
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
            CollectSample(.stepCount, continueInBackground: true)
            CollectSample(.heartRate, continueInBackground: true)
            CollectSample(.bloodOxygen, continueInBackground: true)
            
            // TODO: exercise, sleep metrics, anything to do with activity and vital signs, sleep, activity, O2, heart rate, resp rate (activity, vital signs, mobility, mindfulness & sleep)
//            CollectSample(HKObjectType.workoutType(), continueInBackground: true)
            RequestReadAccess(quantity: [.stepCount, .heartRate, .bloodOxygen])
        }
    }
}
