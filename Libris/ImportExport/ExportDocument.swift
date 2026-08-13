//
//  ExportDocument.swift
//  Libris
//

import SwiftUI
import UniformTypeIdentifiers

/// A thin `FileDocument` that hands already-encoded JSON bytes to
/// `.fileExporter`.
struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
