//
//  StatusToggleStyle.swift
//  Libris
//

import SwiftUI

/// A rectangular, button-like toggle. When on it fills with `tint` and turns
/// its label white; when off it stays a muted grey with dimmed text — so
/// selected and unselected read clearly apart.
struct StatusToggleStyle: ToggleStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            configuration.label
                .font(.callout)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .foregroundStyle(configuration.isOn ? Color.white : Color.secondary)
                .background(configuration.isOn ? tint : Color.gray.opacity(0.15),
                            in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(configuration.isOn ? .isSelected : [])
    }
}
