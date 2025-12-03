//
// This source file is part of the CompassSpeziApp based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziNotifications
import SpeziOnboarding
import SwiftUI
import UserNotifications


private func scheduleOpenAppNotifications() {
    let center = UNUserNotificationCenter.current()

    // Remove old versions of these notifications if they exist
    let identifiers = ["open-app-10am", "open-app-8pm"]
    center.removePendingNotificationRequests(withIdentifiers: identifiers)

    func makeRequest(
        id: String,
        title: String,
        body: String,
        hour: Int,
        minute: Int
    ) -> UNNotificationRequest {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        return UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
    }

    let morning = makeRequest(
        id: "open-app-10am",
        title: "Morning check in",
        body: "Time to open the app!",
        hour: 8,
        minute: 0
    )

    let evening = makeRequest(
        id: "open-app-8pm",
        title: "Evening check-in",
        body: "Time to open the app!",
        hour: 18,
        minute: 0
    )

    center.add(morning)
    center.add(evening)
}

struct NotificationPermissions: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath

    @Environment(\.requestNotificationAuthorization) private var requestNotificationAuthorization

    @State private var notificationProcessing = false
    
    
    var body: some View {
        OnboardingView(
            contentView: {
                VStack {
                    OnboardingTitleView(
                        title: "Notifications",
                        subtitle: "Spezi Scheduler Notifications."
                    )
                    Spacer()
                    Image(systemName: "bell.square.fill")
                        .font(.system(size: 150))
                        .foregroundColor(.accentColor)
                        .accessibilityHidden(true)
                    Text("NOTIFICATION_PERMISSIONS_DESCRIPTION")
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 16)
                    Spacer()
                }
            }, actionView: {
                OnboardingActionsView(
                    "Allow Notifications",
                    action: {
                        do {
                            notificationProcessing = true
                            // Notification Authorization is not available in the preview simulator.
                            if ProcessInfo.processInfo.isPreviewSimulator {
                                try await _Concurrency.Task.sleep(for: .seconds(5))
                            } else {
                                try await requestNotificationAuthorization(options: [.alert, .sound, .badge])
                                // twice daily notification to open app
                                scheduleOpenAppNotifications()

                            }
                        } catch {
                            print("Could not request notification permissions.")
                        }
                        notificationProcessing = false
                        
                        onboardingNavigationPath.nextStep()
                    }
                )
            }
        )
            .navigationBarBackButtonHidden(notificationProcessing)
            // Small fix as otherwise "Login" or "Sign up" is still shown in the nav bar
            .navigationTitle(Text(verbatim: ""))
    }
}


#if DEBUG
#Preview {
    OnboardingStack {
        NotificationPermissions()
    }
        .previewWith {
            CompassSpeziAppScheduler()
        }
}
#endif
