//
// This source file is part of the CompassSpeziApp based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

enum RuntimeVerify {
    static func run() {
        let opts = FirebaseApp.app()?.options
        print("[Verify] bundleID=\(Bundle.main.bundleIdentifier ?? "nil")")
        print("[Verify] projectID=\(opts?.projectID ?? "nil")")
        print("[Verify] apiKey=\(opts?.apiKey ?? "nil")")
        print("[Verify] useFirebaseEmulator=\(FeatureFlags.useFirebaseEmulator)")
        print("[Verify] disableFirebase=\(FeatureFlags.disableFirebase)")

        // 1) Is a user present?
        let currentUID = Auth.auth().currentUser?.uid ?? "nil"
        print("[Verify] currentUser=\(currentUID)")

        // 2) (Optional) Try a quick sign-in path you actually support:
        Auth.auth().signIn(withEmail: "test@example.com", password: "password") { result, error in
            if let error {
                print("[Verify] signIn(email) ERROR: \(error.localizedDescription)")
            } else {
                print("[Verify] signIn(email) ✅ uid=\(result?.user.uid ?? "nil")")
            }

            // ✅ WRITE UNDER THE USER'S SUBTREE (matches your rules)
            let db = Firestore.firestore()
            let uid = result?.user.uid ?? Auth.auth().currentUser?.uid
            guard let uid else {
                print("[Verify] no uid available to write under /users/{uid}")
                return
            }

            db.collection("users").document(uid)
              .collection("debug_writes")
              .document(UUID().uuidString)
              .setData([
                  "t": Timestamp(date: Date()),
                  "who": "runtime-verify"
              ]) { err in
                  print("[Verify] write:", err?.localizedDescription ?? "✅ success")
              }
        }
    }
}
