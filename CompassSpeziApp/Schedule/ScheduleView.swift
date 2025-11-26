//
// This source file is part of the CompassSpeziApp based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

@_spi(TestingSupport) import SpeziAccount
import SpeziScheduler
import SpeziSchedulerUI
import SpeziViews
import SwiftUI


struct ScheduleView: View {
    @Environment(Account.self) private var account: Account?
    @Environment(CompassSpeziAppScheduler.self) private var scheduler: CompassSpeziAppScheduler

    @State private var presentedEvent: Event?
    @Binding private var presentingAccount: Bool

    @AppStorage("lastUploadTime") private var lastUpload: Date = .distantPast

    
    var body: some View {
//        @Bindable var scheduler = scheduler

//        NavigationStack {
//            VStack (spacing: 12){
//                Text ("You're all set!")
//                    .font(.largeTitle)
//                Text ("Please contact the COMPASS team with any questions")
//                    .font(.subheadline)
//            }
////            TodayList { event in
////                InstructionsTile(event) {
////                    EventActionButton(event: event, "Start Questionnaire") {
////                        presentedEvent = event
////                    }
////                }
////            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .navigationTitle("You're all set!")
////                .viewStateAlert(state: $scheduler.viewState)
////                .sheet(item: $presentedEvent) { event in
////                    EventView(event)
////                }
//                .toolbar {
//                    if account != nil {
//                        AccountButton(isPresented: $presentingAccount)
//                    }
////                }
//        }
        NavigationStack {
            VStack(spacing: 12) {
                Text("You're all set!")
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)

                Text("Please contact the COMPASS team \n with any questions.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                if lastUpload == .distantPast {
                    Text("Last uploaded: —")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Last uploaded: \(formatted(date: lastUpload))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                if account != nil {
                    AccountButton(isPresented: $presentingAccount)
                }
            }
        }
        
    }
    
    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    
    init(presentingAccount: Binding<Bool>) {
        self._presentingAccount = presentingAccount
    }
}


#if DEBUG
#Preview {
    @Previewable @State var presentingAccount = false

    ScheduleView(presentingAccount: $presentingAccount)
        .previewWith(standard: CompassSpeziAppStandard()) {
            CompassSpeziAppScheduler()
            AccountConfiguration(service: InMemoryAccountService())
        }
}
#endif
