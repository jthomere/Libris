//
//  ToastMessage.swift
//  Libris
//
//  A brief, self-dismissing message shown as a floating capsule at the bottom
//  of a view. Assigning a new value re-triggers the dismiss timer.
//

import SwiftUI

struct ToastMessage: Identifiable {
    let id = UUID()
    let text: String

    init(_ text: String) {
        self.text = text
    }
}

extension View {
    /// Overlays a transient toast that clears `message` after `duration`.
    func toast(_ message: Binding<ToastMessage?>, duration: Duration = .seconds(2)) -> some View {
        modifier(ToastModifier(message: message, duration: duration))
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: ToastMessage?
    let duration: Duration

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    Text(message.text)
                        .font(.title3)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(.regularMaterial, in: Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                        .padding(.bottom, 28)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom),
                            removal: .opacity
                        ))
                }
            }
            // Keyed to the message identity so it animates both the slide-in
            // and the fade-out, without the caller wrapping in withAnimation.
            .animation(.easeInOut, value: message?.id)
            // The id changes with each new message, restarting the timer.
            .task(id: message?.id) {
                guard message != nil else { return }
                try? await Task.sleep(for: duration)
                message = nil
            }
    }
}
