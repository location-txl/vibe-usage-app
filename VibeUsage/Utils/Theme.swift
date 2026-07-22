import SwiftUI

/// Centralized semantic color tokens that adapt to the active `ColorScheme`.
///
/// All views should resolve colors through `Theme` rather than hardcoding
/// `Color(white:)` grayscale values, so the dashboard renders correctly in
/// both light and dark mode. Each token returns the dark value that matches
/// the pre-existing dark-only palette (see AGENTS.md Styling Conventions) when
/// `scheme == .dark`, and a calibrated light counterpart otherwise.
///
/// Usage:
/// ```swift
/// @Environment(\.colorScheme) private var colorScheme
/// ...
/// .background(Theme.cardBackground(colorScheme))
/// .foregroundStyle(Theme.primaryText(colorScheme))
/// ```
enum Theme {
    // MARK: - Surfaces

    /// Outermost popover background.
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.04) : Color(white: 0.96)
    }

    /// Card / panel fill (sits on top of `background`).
    static func cardBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.09) : Color.white
    }

    /// Slightly elevated surface used for nested containers (verification card,
    /// filter tag strip, dropdown menus).
    static func surfaceElevated(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.06) : Color(white: 0.98)
    }

    /// Hover / inactive fill (slightly lifted from card background).
    static func hoverFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.10) : Color(white: 0.94)
    }

    // MARK: - Borders / Dividers

    static func cardBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.16) : Color(white: 0.86)
    }

    static func divider(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.16) : Color(white: 0.86)
    }

    static func buttonBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.18) : Color(white: 0.82)
    }

    // MARK: - Text

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : Color(white: 0.08)
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.63) : Color(white: 0.45)
    }

    static func tertiaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.38) : Color(white: 0.62)
    }

    /// Footer / muted labels (formerly `Color(white: 0.5)`).
    static func subtleText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.5) : Color(white: 0.55)
    }

    // MARK: - Controls

    static func buttonBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.12) : Color(white: 0.92)
    }

    /// Selected / active control fill (time-range pills, mode toggles, checked rows).
    static func selectedFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.20) : Color(white: 0.80)
    }

    /// Selected control text — reverses against `selectedFill`.
    static func selectedText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : .white
    }

    /// Progress bar track behind the filled portion.
    static func progressTrack(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.18) : Color(white: 0.90)
    }

    // MARK: - Tooltip (always dark overlay for contrast)

    static func tooltipBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black : Color(white: 0.10)
    }

    static func tooltipText(_ scheme: ColorScheme) -> Color {
        .white
    }

    /// Shadow color for popover / dropdown elevation. Darker and stronger in
    /// dark mode, lighter in light mode so it reads as a soft drop shadow.
    static func shadowColor(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.18)
    }

    // MARK: - Chart

    /// Default bar / line stroke in token mode. In dark mode this was
    /// `Color.white.opacity(0.9)`; in light mode it must invert to stay visible
    /// on a white card.
    static func chartPrimaryFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.9) : Color(white: 0.18)
    }

    /// Dimmed gridline / axis color.
    static func chartGridline(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }

    /// Empty-state / placeholder glyph color (formerly `Color(white: 0.3)`).
    static func emptyGlyph(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(white: 0.3) : Color(white: 0.68)
    }
}
