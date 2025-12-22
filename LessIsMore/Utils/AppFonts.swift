//
//  AppFonts.swift
//  LessIsMore
//
//  Created by Angel Geoffroy on 03/09/2025.
//

import SwiftUI

// MARK: - Configuration des polices de l'app
struct AppFonts {
    // Noms des polices (doivent correspondre au nom PostScript de la police)
    static let boldName = "SpaceGrotesk-Bold"
    static let regularName = "SpaceGrotesk-Regular"

    // MARK: - Titres (Bold)
    static func title(_ size: CGFloat = 34) -> Font {
        .custom(boldName, size: size)
    }

    static func title2(_ size: CGFloat = 28) -> Font {
        .custom(boldName, size: size)
    }

    static func title3(_ size: CGFloat = 22) -> Font {
        .custom(boldName, size: size)
    }

    static func headline(_ size: CGFloat = 17) -> Font {
        .custom(boldName, size: size)
    }

    // MARK: - Textes (Regular)
    static func body(_ size: CGFloat = 17) -> Font {
        .custom(regularName, size: size)
    }

    static func subheadline(_ size: CGFloat = 15) -> Font {
        .custom(regularName, size: size)
    }

    static func footnote(_ size: CGFloat = 13) -> Font {
        .custom(regularName, size: size)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .custom(regularName, size: size)
    }

    static func caption2(_ size: CGFloat = 11) -> Font {
        .custom(regularName, size: size)
    }
}

// MARK: - Extension View pour simplifier l'utilisation
extension View {
    func appFont(_ font: Font) -> some View {
        self.font(font)
    }

    // Raccourcis pour les titres
    func appTitle() -> some View {
        self.font(AppFonts.title())
    }

    func appTitle2() -> some View {
        self.font(AppFonts.title2())
    }

    func appTitle3() -> some View {
        self.font(AppFonts.title3())
    }

    func appHeadline() -> some View {
        self.font(AppFonts.headline())
    }

    // Raccourcis pour les textes
    func appBody() -> some View {
        self.font(AppFonts.body())
    }

    func appSubheadline() -> some View {
        self.font(AppFonts.subheadline())
    }

    func appFootnote() -> some View {
        self.font(AppFonts.footnote())
    }

    func appCaption() -> some View {
        self.font(AppFonts.caption())
    }

    func appCaption2() -> some View {
        self.font(AppFonts.caption2())
    }
}
