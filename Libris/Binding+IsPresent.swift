//
//  Binding+IsPresent.swift
//  Libris
//

import SwiftUI

extension Binding {
    /// A `Bool` binding that reads `true` while an optional value is non-nil and
    /// clears the value to `nil` when set to `false`. Bridges optional state to
    /// the `isPresented:` a `.alert` or `.sheet` expects, so dismissing the
    /// presentation also discards the pending value.
    func isPresent<Wrapped>() -> Binding<Bool> where Value == Wrapped? {
        Binding<Bool>(
            get: { wrappedValue != nil },
            set: { isPresented in
                if !isPresented { wrappedValue = nil }
            }
        )
    }
}
