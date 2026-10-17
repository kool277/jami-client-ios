/*
 *  Copyright (C) 2026 Savoir-faire Linux Inc.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.
 */

import SwiftUI
import UIKit

let chatBackgroundKey = "CHAT_BACKGROUND_KEY"

/// What is painted behind the messages: one color, or a gradient from the top
/// leading to the bottom trailing corner. Colors are 0xRRGGBB.
enum ChatBackgroundFill: Equatable {
    case color(Int)
    case gradient(Int, Int)
}

/// The chat background presets, in the order they are offered. Each has a
/// light and a dark variant, so that the dates and events drawn on the chat
/// background stay readable in both appearances. The other Jami clients offer
/// the same presets.
enum ChatBackgroundPreset: String, CaseIterable {
    case sky, mint, sand, rose, lavender, slate, sunrise, ocean, meadow, dusk

    private var variants: (light: ChatBackgroundFill, dark: ChatBackgroundFill) {
        switch self {
        case .sky: return (.color(0xDCEEFB), .color(0x0F2A3D))
        case .mint: return (.color(0xDCF2E3), .color(0x0F2E22))
        case .sand: return (.color(0xF5EAD7), .color(0x2E2614))
        case .rose: return (.color(0xF8DEE5), .color(0x33161F))
        case .lavender: return (.color(0xE7E1F7), .color(0x221A3A))
        case .slate: return (.color(0xDDE2E8), .color(0x1C232B))
        case .sunrise: return (.gradient(0xFDE2C8, 0xF8C8DC), .gradient(0x3A2418, 0x3A1A2A))
        case .ocean: return (.gradient(0xCDE8F6, 0xD9D4F5), .gradient(0x0E2A3A, 0x211C3E))
        case .meadow: return (.gradient(0xDFF2D8, 0xCFEAF0), .gradient(0x13301A, 0x0F2C33))
        case .dusk: return (.gradient(0xE3D9F2, 0xF6D9E4), .gradient(0x2B2445, 0x3B2236))
        }
    }

    /// The variant for the appearance in use.
    func fill(for colorScheme: ColorScheme) -> ChatBackgroundFill {
        return colorScheme == .dark ? variants.dark : variants.light
    }

    var name: String {
        switch self {
        case .sky: return L10n.ChatBackground.sky
        case .mint: return L10n.ChatBackground.mint
        case .sand: return L10n.ChatBackground.sand
        case .rose: return L10n.ChatBackground.rose
        case .lavender: return L10n.ChatBackground.lavender
        case .slate: return L10n.ChatBackground.slate
        case .sunrise: return L10n.ChatBackground.sunrise
        case .ocean: return L10n.ChatBackground.ocean
        case .meadow: return L10n.ChatBackground.meadow
        case .dusk: return L10n.ChatBackground.dusk
        }
    }
}

/// The background drawn behind the messages of every conversation, chosen in
/// the app settings and kept on this device.
enum ChatBackground: Equatable {
    /// The theme's background, as without the setting.
    case `default`
    case preset(ChatBackgroundPreset)
    /// A color picked by the user (0xRRGGBB), used as is in both appearances.
    case custom(Int)

    /// Reads back a stored choice; anything that cannot be used is the default.
    init(storedValue: String?) {
        guard let value = storedValue else {
            self = .default
            return
        }
        if let preset = ChatBackgroundPreset(rawValue: value) {
            self = .preset(preset)
        } else if value.count == 7, value.hasPrefix("#"),
                  value.dropFirst().allSatisfy({ $0.isASCII && $0.isHexDigit }),
                  let color = Int(value.dropFirst(), radix: 16) {
            self = .custom(color)
        } else {
            self = .default
        }
    }

    /// The custom background for a color picked by the user, made opaque.
    init(customColor: UIColor) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        customColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        // Colors outside of sRGB (Display P3) have components beyond 0...1.
        let byte = { (component: CGFloat) in Int((min(max(component, 0), 1) * 255).rounded()) }
        self = .custom(byte(red) << 16 | byte(green) << 8 | byte(blue))
    }

    /// How the choice is stored: "default", the name of a preset or "#rrggbb".
    var storedValue: String {
        switch self {
        case .default:
            return "default"
        case .preset(let preset):
            return preset.rawValue
        case .custom(let color):
            return String(format: "#%06lx", color)
        }
    }

    /// What to paint in the appearance in use, or nil to keep the theme's
    /// background.
    func fill(for colorScheme: ColorScheme) -> ChatBackgroundFill? {
        switch self {
        case .default:
            return nil
        case .preset(let preset):
            return preset.fill(for: colorScheme)
        case .custom(let color):
            return .color(color)
        }
    }

    /// The chat background chosen on this device.
    static func stored(in defaults: UserDefaults = .standard) -> ChatBackground {
        return ChatBackground(storedValue: defaults.string(forKey: chatBackgroundKey))
    }

    /// Keeps this choice on this device.
    func store(in defaults: UserDefaults = .standard) {
        defaults.set(storedValue, forKey: chatBackgroundKey)
    }
}

/// Paints a chat background: behind the messages, or as a swatch in the
/// settings.
struct ChatBackgroundView: View {
    let fill: ChatBackgroundFill

    var body: some View {
        switch fill {
        case .color(let color):
            Color(UIColor(hex: color, alpha: 1))
        case .gradient(let start, let end):
            LinearGradient(gradient: Gradient(colors: [Color(UIColor(hex: start, alpha: 1)),
                                                       Color(UIColor(hex: end, alpha: 1))]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        }
    }
}
