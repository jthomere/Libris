//
//  LibrisApp.swift
//  Libris
//

import SwiftUI
import SwiftData

@main
struct LibrisApp: App {
    private let containerResult: Result<ModelContainer, Error>

    init() {
        containerResult = Result {
            let schema = Schema([Book.self])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none // .private("iCloud.org.thomere.Libris") :
            )
            return try ModelContainer(for: schema, configurations: [configuration])
        }
    }

    var body: some Scene {
        WindowGroup {
            switch containerResult {
            case .success(let container):
                ContentView()
                    .modelContainer(container)
            case .failure(let error):
                ContainerErrorView(error: error)
            }
        }
    }
}
