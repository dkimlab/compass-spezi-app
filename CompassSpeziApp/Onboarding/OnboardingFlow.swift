//
// This source file is part of the CompassSpeziApp based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

@_spi(TestingSupport)
import SpeziAccount
import SpeziFirebaseAccount
import SpeziHealthKit
import SpeziNotifications
import SpeziOnboarding
import SwiftUI


/// Displays an multi-step onboarding flow for the CompassSpeziApp.
struct OnboardingFlow: View {
    @Environment(Account.self) private var account
    @Environment(CompassSpeziAppStandard.self) private var standard
    @Environment(HealthKit.self) private var healthKit

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.notificationSettings) private var notificationSettings

    @AppStorage(StorageKeys.onboardingFlowComplete) private var completedOnboardingFlow = false
    

    @State private var localNotificationAuthorization = false
    
    
    @MainActor private var healthKitAuthorization: Bool {
        // As HealthKit not available in preview simulator
        if ProcessInfo.processInfo.isPreviewSimulator {
            return false
        }
        return healthKit.isFullyAuthorized
    }
    
    
    var body: some View {
        OnboardingStack(onboardingFlowComplete: $completedOnboardingFlow) {
            Welcome()
            
            if !FeatureFlags.disableFirebase {
                AccountOnboarding()
            }
            
//            #if !(targetEnvironment(simulator) && (arch(i386) || arch(x86_64)))
//                Consent()
//            #endif
            
            if HKHealthStore.isHealthDataAvailable() && !healthKitAuthorization {
                HealthKitPermissions()
            }
            
//            if !localNotificationAuthorization {
//                NotificationPermissions()
//            }
        }
            .interactiveDismissDisabled(!completedOnboardingFlow)
        //TODO: backfill for 30 days code in progress
//            .task(id: completedOnboardingFlow) {            // runs whenever the Bool flips
//                // Run only once, the first time onboarding finishes
//                guard completedOnboardingFlow, // onboarding finished
//                      healthKitAuthorization,  // user tapped “Allow” in HK sheet
//                      let uid = account.user?.uid,  // Spezi’s user
//                      UserDefaults.standard.object(forKey: "historicalSyncDone") == nil
//                else { return }
//
//                // Kick off the 30‑day back‑fill without blocking the UI
//                await backfillLast30Days(for: uid)
//            }
            .onChange(of: scenePhase, initial: true) {
                guard case .active = scenePhase else {
                    return
                }

                Task {
                    localNotificationAuthorization = await notificationSettings().authorizationStatus == .authorized
                }
            }
    }
}


#if DEBUG
#Preview {
    OnboardingFlow()
        .previewWith(standard: CompassSpeziAppStandard()) {
            OnboardingDataSource()
            HealthKit()
            AccountConfiguration(service: InMemoryAccountService())
            CompassSpeziAppScheduler()
        }
}
#endif
