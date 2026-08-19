//
//  AIPromptView.swift
//  Libris
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AIPromptView: View {
    let genres: [String]
    let tags: [String]

    @Environment(\.dismiss) private var dismiss
    @State private var didCopy = false
    @State private var showingSave = false
    @State private var saveError: String?

    private var promptText: String { AIPrompt.text(genres: genres, tags: tags) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Import Prompt")
                .font(.title2.bold())

            Text("Give an AI assistant a photo of books along with this prompt. It will reply with a JSON file you can then import with “Import Books”.")
                .foregroundStyle(.secondary)

            ScrollView {
                Text(promptText)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
            }
            .frame(minHeight: 320)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))

            HStack {
                Button {
                    copyPrompt()
                } label: {
                    Label(didCopy ? "Copied" : "Copy", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                }

                Button {
                    showingSave = true
                } label: {
                    Label("Save…", systemImage: "square.and.arrow.down")
                }

                Spacer()

                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 600)
        .fileExporter(
            isPresented: $showingSave,
            document: PromptDocument(text: promptText),
            contentType: .plainText,
            defaultFilename: "AI-JSON-export-prompt"
        ) { result in
            if case .failure(let error) = result {
                if (error as? CocoaError)?.code == .userCancelled { return }
                saveError = error.localizedDescription
            }
        }
        .alert("Save Failed", isPresented: $saveError.isPresent(), presenting: saveError) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
    }

    private func copyPrompt() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(promptText, forType: .string)
        didCopy = true
    }
}

#Preview {
    AIPromptView(genres: ["Fantasy", "Science Fiction", "History"], tags: ["Bestseller", "Staff Pick"])
}
