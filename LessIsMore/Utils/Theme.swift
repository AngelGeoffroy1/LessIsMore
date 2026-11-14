//
//  Theme.swift
//  LessIsMore
//
//  Monochrome design system: black & white, adapts to light/dark mode.
//  Every screen takes its colors from here instead of hard-coded values.
//

import SwiftUI

enum Theme {
    /// Main ink: black in light mode, white in dark mode.
    static let ink = Color(uiColor: .label)
    /// Opposite of ink, used for text/icons drawn on top of an ink fill.
    static let inkInverse = Color(uiColor: .systemBackground)
    static let secondaryText = Color.secondary
    static let tertiaryText = Color.secondary.opacity(0.6)

    /// Grouped-list card background (like iOS Settings).
    static let card = Color.primary.opacity(0.06)
    static let cardSelected = Color.primary.opacity(0.12)
    static let hairline = Color.primary.opacity(0.08)
    static let track = Color.primary.opacity(0.04)

    static let cornerRadius: CGFloat = 16

    /// Grey ramp used where several series must be told apart (charts, legends).
    static func shade(_ index: Int, of count: Int) -> Color {
        guard count > 1 else { return ink }
        let step = 0.75 / Double(count - 1)
        return ink.opacity(1.0 - Double(index) * step)
    }
}

// MARK: - Pro badge

struct ProBadge: View {
    var body: some View {
        Text("Pro")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Theme.inkInverse)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Theme.ink))
    }
}

// MARK: - Buttons

/// Full-width black pill (white in dark mode), the app's primary call to action.
struct InkButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Theme.inkInverse)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Capsule().fill(Theme.ink.opacity(isEnabled ? 1 : 0.3)))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Secondary outlined pill.
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Theme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Capsule().stroke(Theme.ink.opacity(0.2), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

// MARK: - Card container

extension View {
    /// Grouped card look used by every settings / filter list.
    func themeCard() -> some View {
        self
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }

    /// Small uppercase section label, iOS Settings style.
    func themeSectionLabel() -> some View {
        self
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Theme.secondaryText)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}
