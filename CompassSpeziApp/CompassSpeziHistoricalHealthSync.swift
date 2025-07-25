//
// This source file is part of the CompassSpeziApp based on the Stanford Spezi Template Application project
//
// SPDX-FileCopyrightText: 2025 Stanford University
//
// SPDX-License-Identifier: MIT
//

import Foundation
import HealthKit
import FirebaseFirestore
import SpeziHealthKit

// MARK: - Retrospective sync
extension CompassSpeziAppStandard {
    /// Uploads the last 30 days of every HKQuantityType in `sampleInfoDictionary()`.
    /// Runs once per account / device.
    nonisolated
    func backfillLast30Days(for userId: String) async {
        // prevent accidental re‑entry
        guard UserDefaults.standard.object(forKey: "historicalSyncDone") == nil else { return }

        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        await withTaskGroup(of: Void.self) { group in
            for (id, info) in sampleInfoDictionary() {
                guard let qType = HKObjectType.quantityType(forIdentifier: .init(rawValue: id)) else { continue }
                group.addTask { [weak self] in
                    await self?.fetchAndUpload(type: qType, info: info, userId: userId, start: start, end: Date())
                }
            }
        }
        UserDefaults.standard.set(Date(), forKey: "historicalSyncDone")
    }
    
    // MARK: – helpers
    private func fetchAndUpload(
        type: HKQuantityType,
        info: SampleInfo,
        userId: String,
        start: Date,
        end: Date
    ) async {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let query = HKSampleQuery(sampleType: type,
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: nil) { _, samples, error in
            guard error == nil, let qSamples = samples as? [HKQuantitySample] else { return }
            Task { await self.uploadBatch(qSamples, with: info, userId: userId) }
        }
        healthStore.execute(query)     // `healthStore` property of the actor
    }

    private func uploadBatch(
        _ samples: [HKQuantitySample],
        with info: SampleInfo,
        userId: String
    ) async {
        let db = Firestore.firestore()
        var batch = db.batch(); var writes = 0

        for s in samples where s.quantity.is(compatibleWith: info.unit) {
            let val = s.quantity.doubleValue(for: info.unit)   // scale if needed
            let docRef = db.collection("users")
                           .document(userId)
                           .collection(info.collectionName)
                           .document()
            batch.setData([
                "type": info.fieldName,
                "value": val,
                "timestamp": s.endDate
            ], forDocument: docRef)
            writes += 1
            if writes == 500 { try? await batch.commit(); batch = db.batch(); writes = 0 }
        }
        if writes > 0 { try? await batch.commit() }
    }

}
