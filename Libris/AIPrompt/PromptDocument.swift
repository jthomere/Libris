//
//  PromptDocument.swift
//  Libris
//

import SwiftUI
import UniformTypeIdentifiers

/// A minimal plain-text document used to save the AI import prompt through
/// `.fileExporter`.
struct PromptDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        text = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
