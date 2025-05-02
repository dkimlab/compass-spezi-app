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

                Text("Check back later for upcoming tasks.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                if account != nil {
                    AccountButton(isPresented: $presentingAccount)
                }
            }
        }
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
