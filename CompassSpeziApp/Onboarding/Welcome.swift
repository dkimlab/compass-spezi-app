//
// This source file is part of the CompassSpeziApp based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2023 Stanford University
//
// SPDX-License-Identifier: MIT
//

import SpeziOnboarding
import SwiftUI


struct Welcome: View {
    @Environment(OnboardingNavigationPath.self) private var onboardingNavigationPath
    
    
    var body: some View {

        VStack {
            OnboardingView(
                title: "Welcome!",
                subtitle: "This app will help the COMPASS team collect data from your AppleWatch.",
                areas: [],
                actionText: "Get Started",
                action: {
                    onboardingNavigationPath.nextStep()
                }
            )
            
            .padding(.top, 24)
        }
        .multilineTextAlignment(.center)
    }
}


#if DEBUG
#Preview {
    OnboardingStack {
        Welcome()
    }
}
#endif
