//
//  ContainerErrorView.swift
//  Libris
//

import SwiftUI
import AppKit

struct ContainerErrorView: View {
    let error: Error

    var body: some View {
        ContentUnavailableView {
            Label("Can't Open Your Library", systemImage: "exclamationmark.triangle")
        } description: {
            Text("Libris couldn't open its data store, so it can't start. Your books are still saved on disk — nothing has been deleted. Quit and try again; if this keeps happening, the store may be damaged or from an incompatible version.\n\n\(error.localizedDescription)")
        } actions: {
            Button("Quit Libris") {
                NSApplication.shared.terminate(nil)
            }
        }
        .frame(minWidth: 640, minHeight: 480)
        .padding()
    }
}
