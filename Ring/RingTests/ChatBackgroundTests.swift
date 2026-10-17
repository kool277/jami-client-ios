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
import XCTest
@testable import Ring

final class ChatBackgroundTests: XCTestCase {

    private let suiteName = "ChatBackgroundTests"
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        try super.setUpWithError()
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        try super.tearDownWithError()
    }

    // MARK: - What is painted

    func testDefaultKeepsTheThemeBackground() {
        XCTAssertNil(ChatBackground.default.fill(for: .light))
        XCTAssertNil(ChatBackground.default.fill(for: .dark))
    }

    func testPresetIsPaintedInTheVariantOfTheAppearance() {
        XCTAssertEqual(ChatBackground.preset(.sky).fill(for: .light), .color(0xDCEEFB))
        XCTAssertEqual(ChatBackground.preset(.sky).fill(for: .dark), .color(0x0F2A3D))
    }

    func testGradientPresetRunsBetweenTwoColors() {
        XCTAssertEqual(ChatBackground.preset(.ocean).fill(for: .light), .gradient(0xCDE8F6, 0xD9D4F5))
        XCTAssertEqual(ChatBackground.preset(.ocean).fill(for: .dark), .gradient(0x0E2A3A, 0x211C3E))
    }

    func testPresetsAreSixColorsThenFourGradients() {
        let presets = ChatBackgroundPreset.allCases
        XCTAssertEqual(presets.map(\.rawValue),
                       ["sky", "mint", "sand", "rose", "lavender", "slate", "sunrise", "ocean", "meadow", "dusk"])
        for (index, preset) in presets.enumerated() {
            for colorScheme in [ColorScheme.light, ColorScheme.dark] {
                switch preset.fill(for: colorScheme) {
                case .color:
                    XCTAssertLessThan(index, 6, preset.rawValue)
                case .gradient:
                    XCTAssertGreaterThanOrEqual(index, 6, preset.rawValue)
                }
            }
            XCTAssertNotEqual(preset.fill(for: .light), preset.fill(for: .dark), preset.rawValue)
            XCTAssertFalse(preset.name.isEmpty, preset.rawValue)
        }
    }

    func testCustomColorIsPaintedAsIsInBothAppearances() {
        XCTAssertEqual(ChatBackground.custom(0x336699).fill(for: .light), .color(0x336699))
        XCTAssertEqual(ChatBackground.custom(0x336699).fill(for: .dark), .color(0x336699))
    }

    // MARK: - Choosing a color

    func testPickedColorBecomesAnOpaqueCustomColor() {
        let picked = UIColor(red: 0x33 / 255.0, green: 0x66 / 255.0, blue: 0x99 / 255.0, alpha: 0.5)
        XCTAssertEqual(ChatBackground(customColor: picked), .custom(0x336699))
    }

    func testPickedColorBeyondSRGBIsClamped() {
        let picked = UIColor(displayP3Red: 1, green: 0, blue: 0, alpha: 1)
        XCTAssertEqual(ChatBackground(customColor: picked), .custom(0xFF0000))
    }

    // MARK: - Storage

    func testStoredChoiceReadsBack() {
        for background in [ChatBackground.default, .preset(.mint), .custom(0xA1B2C3), .custom(0x00000F)] {
            XCTAssertEqual(ChatBackground(storedValue: background.storedValue), background)
        }
        XCTAssertEqual(ChatBackground.preset(.mint).storedValue, "mint")
        XCTAssertEqual(ChatBackground.custom(0x00000F).storedValue, "#00000f")
        XCTAssertEqual(ChatBackground(storedValue: "#A1B2C3"), .custom(0xA1B2C3))
    }

    func testUnusableStoredValueIsTheDefault() {
        let unusable: [String?] = [nil, "", "gone", "Sky", "#12345", "#1234567", "#12345g", "#-12345", "red;x"]
        for stored in unusable {
            XCTAssertEqual(ChatBackground(storedValue: stored), .default, String(describing: stored))
        }
    }

    func testChoiceIsKeptOnTheDevice() {
        XCTAssertEqual(ChatBackground.stored(in: defaults), .default)

        ChatBackground.preset(.ocean).store(in: defaults)
        XCTAssertEqual(defaults.string(forKey: chatBackgroundKey), "ocean")
        XCTAssertEqual(ChatBackground.stored(in: defaults), .preset(.ocean))

        ChatBackground.custom(0x123456).store(in: defaults)
        XCTAssertEqual(ChatBackground.stored(in: defaults), .custom(0x123456))

        ChatBackground.default.store(in: defaults)
        XCTAssertEqual(ChatBackground.stored(in: defaults), .default)
    }

    func testInvalidStoredChoiceIsTheDefault() {
        defaults.set("gone", forKey: chatBackgroundKey)
        XCTAssertEqual(ChatBackground.stored(in: defaults), .default)

        defaults.set(42, forKey: chatBackgroundKey)
        XCTAssertEqual(ChatBackground.stored(in: defaults), .default)
    }
}
