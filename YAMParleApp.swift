//
//  YAMParleApp.swift
//  YAMParle
//
//  Created by adel mehenni on 10/09/2026.
//

import SwiftUI
import SwiftData

@main
struct YAMParleApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AACCategory.self,
            AACItem.self,
            FavoritePhrase.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("ModelContainer creation issue encountered: \(error). Attempting recovery...")

            // If an incompatible persistent store exists from a previous build schema, remove it to allow clean recreation
            if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let extensions = ["store", "store-shm", "store-wal"]
                for ext in extensions {
                    let fileURL = appSupportURL.appendingPathComponent("default.\(ext)")
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }

            // Retry creating the container
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                print("Fallback to in-memory store: \(error)")
                let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [inMemoryConfig])
                } catch {
                    fatalError("Critical: Could not initialize ModelContainer: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
