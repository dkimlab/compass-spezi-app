//
// This source file is part of the CompassSpeziApp based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

@_spi(TestingSupport) import SpeziAccount
import SwiftUI


struct HomeView: View {
    enum Tabs: String {
        case schedule
        case contact
    }


    @AppStorage(StorageKeys.homeTabSelection) private var selectedTab = Tabs.schedule
    @AppStorage(StorageKeys.tabViewCustomization) private var tabViewCustomization = TabViewCustomization()


    @State private var presentingAccount = false
    
    // variables to show number of buffered samples
    @State private var bufferedSampleCount: Int = 0
    @Environment(CompassSpeziAppStandard.self) private var standard

    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "list.clipboard", value: .schedule) {
                VStack(alignment: .leading, spacing: 8) {
                    ScheduleView(presentingAccount: $presentingAccount)
                    Text("Buffered samples: \(bufferedSampleCount)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .padding(.horizontal)
            }
                .customizationID("home.schedule")
//            Tab("Contacts", systemImage: "person.fill", value: .contact) {
//                Contacts(presentingAccount: $presentingAccount)
//            }
//                .customizationID("home.contacts")
        }
            .tabViewStyle(.sidebarAdaptable)
            .tabViewCustomization($tabViewCustomization)
            .sheet(isPresented: $presentingAccount) {
                AccountSheet(dismissAfterSignIn: false) // presentation was user initiated, do not automatically dismiss
            }
            .accountRequired(!FeatureFlags.disableFirebase && !FeatureFlags.skipOnboarding) {
                AccountSheet()
            }
            .task {
                while true {
                    bufferedSampleCount = await standard.pendingCount()
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                }
            }
    }

}


#if DEBUG
#Preview {
    var details = AccountDetails()
    details.userId = "lelandstanford@stanford.edu"
    details.name = PersonNameComponents(givenName: "Leland", familyName: "Stanford")
    
    return HomeView()
        .previewWith(standard: CompassSpeziAppStandard()) {
            CompassSpeziAppScheduler()
            AccountConfiguration(service: InMemoryAccountService(), activeDetails: details)
        }
}
#endif
