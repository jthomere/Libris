//
//  LibrisApp.swift
//  Libris
//

import SwiftUI
import SwiftData

@main
struct LibrisApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([Book.self])
        let enableCloudKitSync = false
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: enableCloudKitSync ? .private("iCloud.org.thomere.Libris") : .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
