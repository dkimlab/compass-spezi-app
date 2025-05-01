//
// This source file is part of the CompassSpeziApp based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziQuestionnaire
import SpeziScheduler
import SwiftUI


struct EventView: View {
    private let event: Event

    @Environment(CompassSpeziAppStandard.self) private var standard
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let questionnaire = event.task.questionnaire {
            QuestionnaireView(questionnaire: questionnaire) { result in
                dismiss()

                guard case let .completed(response) = result else {
                    return // user cancelled the task
                }

//                Task {
                            do {
                                try await event.complete()
                                await standard.add(response: response)
                            } catch {
                                // Handle the error, e.g., log it or show an alert
                                print("Failed to complete event: \(error)")
                            }
//                }
            }
        } else {
            NavigationStack {
                ContentUnavailableView(
                    "Unsupported Event",
                    systemImage: "list.bullet.clipboard",
                    description: Text("This type of event is currently unsupported. Please contact the developer of this app.")
                )
                    .toolbar {
                        Button("Close") {
                            dismiss()
                        }
                    }
            }
        }
    }

    init(_ event: Event) {
        self.event = event
    }
}
