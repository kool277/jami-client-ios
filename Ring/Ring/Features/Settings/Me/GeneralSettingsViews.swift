/*
 *  Copyright (C) 2024 Savoir-faire Linux Inc.
 *
 *  Author: Kateryna Kostiuk <kateryna.kostiuk@savoirfairelinux.com>
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

struct TextFieldWithDoneButton: UIViewRepresentable {
    @Binding var text: String
    var onEditingChanged: (Bool) -> Void
    var onDone: () -> Void
    var onCancel: () -> Void
    var keyboardType: UIKeyboardType = .default
    var textColor: UIColor = .label

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        textField.textAlignment = .right
        textField.textColor = textColor

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let doneButton = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)
        doneButton.tintColor = UIColor.jami

        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        cancelButton.tintColor = UIColor.jami

        doneButton.primaryAction = UIAction { [weak coordinator = context.coordinator] _ in
            coordinator?.donePressed()
        }
        cancelButton.primaryAction = UIAction { [weak coordinator = context.coordinator] _ in
            coordinator?.cancelPressed()
        }

        toolbar.items = [cancelButton, flexSpace, doneButton]
        textField.inputAccessoryView = toolbar

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.textColor = textColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: TextFieldWithDoneButton
        private var originalValue: String = ""
        private var shouldMoveCursorToEnd = false

        init(_ parent: TextFieldWithDoneButton) {
            self.parent = parent
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""

            if shouldMoveCursorToEnd, let text = textField.text, !text.isEmpty {
                shouldMoveCursorToEnd = false
                let endPosition = textField.endOfDocument
                textField.selectedTextRange = textField.textRange(from: endPosition, to: endPosition)
            }
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            originalValue = textField.text ?? ""
            shouldMoveCursorToEnd = true
            parent.onEditingChanged(true)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onEditingChanged(false)
        }

        @objc func donePressed() {
            parent.onDone()
        }

        @objc func cancelPressed() {
            let savedOriginalValue = originalValue
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.parent.text = savedOriginalValue
                self.parent.onCancel()
            }
        }
    }
}

struct FileTransferSettingsView: View {
    @StateObject var model: GeneralSettings

    init(injectionBag: InjectionBag) {
        _model = StateObject(wrappedValue: GeneralSettings(injectionBag: injectionBag))
    }

    var body: some View {
        List {
            Section {
                ToggleCell(
                    toggleText: L10n.GeneralSettings.automaticAcceptIncomingFiles,
                    getAction: { model.automaticlyDownloadIncomingFiles },
                    setAction: { newValue in model.enableAutomaticlyDownload(enable: newValue) }
                )
                if model.automaticlyDownloadIncomingFiles {
                    HStack {
                        Text(L10n.GeneralSettings.acceptTransferLimit) + Text(L10n.GeneralSettings.acceptTransferLimitDescription)
                            .font(.footnote)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                        Spacer()
                        TextFieldWithDoneButton(
                            text: $model.downloadLimit,
                            onEditingChanged: { _ in },
                            onDone: {
                                model.saveDownloadLimit()
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            },
                            onCancel: {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            },
                            keyboardType: .numberPad,
                            textColor: model.automaticlyDownloadIncomingFiles ? UIColor(Color.jami) : UIColor.secondaryLabel
                        )
                    }
                    .accessibilityElement(children: /*@START_MENU_TOKEN@*/.ignore/*@END_MENU_TOKEN@*/)
                    .accessibilityLabel(L10n.GeneralSettings.acceptTransferLimit)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(L10n.GeneralSettings.fileTransfer)
    }
}

struct LocationSharingSettingsView: View {
    @SwiftUI.State private var showingDurationPicker = false
    @StateObject var model: GeneralSettings

    init(injectionBag: InjectionBag) {
        _model = StateObject(wrappedValue: GeneralSettings(injectionBag: injectionBag))
    }

    var body: some View {
        ZStack {
            List {
                Section {
                    ToggleCell(
                        toggleText: L10n.GeneralSettings.limitLocationSharingDuration,
                        getAction: { model.limitLocationSharing },
                        setAction: { newValue in model.enableLocationSharingLimit(enable: newValue) }
                    )
                    if model.limitLocationSharing {
                        HStack {
                            Text(L10n.GeneralSettings.limitLocationSharingDuration)
                            Spacer()
                            Text(model.locationSharingDurationString)
                            Image(systemName: "chevron.down")
                        }
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.9, blendDuration: 0.4)) {
                                showingDurationPicker = true
                            }
                        }
                        .accessibilityElement(children: /*@START_MENU_TOKEN@*/.ignore/*@END_MENU_TOKEN@*/)
                        .accessibilityLabel(L10n.GeneralSettings.limitLocationSharingDuration)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(L10n.GeneralSettings.locationSharing)
            }
            if showingDurationPicker {
                Group {
                    Color.black.opacity(showingDurationPicker ? 0.4 : 0)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation {
                                showingDurationPicker = false
                            }
                        }
                    DurationPickerView(duration: $model.locationSharingDuration, isPresented: $showingDurationPicker)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .transition(.move(edge: .bottom))
                }
            }
        }
    }
}

struct VideoSettingsView: View {
    @StateObject var model: GeneralSettings

    init(injectionBag: InjectionBag) {
        _model = StateObject(wrappedValue: GeneralSettings(injectionBag: injectionBag))
    }

    var body: some View {
        List {
            Section {
                ToggleCell(
                    toggleText: L10n.GeneralSettings.videoAcceleration,
                    getAction: { model.videoAccelerationEnabled },
                    setAction: { newValue in model.enableVideoAcceleration(enable: newValue) }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(L10n.Global.video)
        }
    }
}

struct ChatBackgroundSettingsView: View {
    @StateObject var model: GeneralSettings
    @SwiftUI.State private var showingColorPicker = false
    @Environment(\.colorScheme) private var colorScheme

    private enum Layout {
        static let swatchSize: CGFloat = 44
        static let selectionWidth: CGFloat = 3
        static let selectionGap: CGFloat = 2
        static let crossOutWidth: CGFloat = 3
        static let spacing: CGFloat = 12
        static var swatchFrameSize: CGFloat { swatchSize + 2 * (selectionGap + selectionWidth) }
    }

    init(injectionBag: InjectionBag) {
        _model = StateObject(wrappedValue: GeneralSettings(injectionBag: injectionBag))
    }

    private var customColor: Int? {
        if case .custom(let color) = model.chatBackground {
            return color
        }
        return nil
    }

    var body: some View {
        List {
            Section {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: Layout.swatchFrameSize), spacing: Layout.spacing)],
                          spacing: Layout.spacing) {
                    swatch(name: L10n.GeneralSettings.chatBackgroundDefault,
                           isSelected: model.chatBackground == .default,
                           action: { model.setChatBackground(.default) },
                           content: { defaultSwatch })
                    ForEach(ChatBackgroundPreset.allCases, id: \.self) { preset in
                        swatch(name: preset.name,
                               isSelected: model.chatBackground == .preset(preset),
                               action: { model.setChatBackground(.preset(preset)) },
                               content: { ChatBackgroundView(fill: preset.fill(for: colorScheme)) })
                    }
                    swatch(name: L10n.GeneralSettings.chatBackgroundCustom,
                           isSelected: customColor != nil,
                           action: { showingColorPicker = true },
                           content: { customSwatch })
                }
                .padding(.vertical, Layout.spacing / 2)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(L10n.GeneralSettings.chatBackground)
        .sheet(isPresented: $showingColorPicker) {
            SystemColorPicker(title: L10n.GeneralSettings.chatBackgroundCustom,
                              color: customColor.map { UIColor(hex: $0, alpha: 1) } ?? .systemGray,
                              onChange: { color in model.setChatBackground(ChatBackground(customColor: color)) },
                              onDone: { showingColorPicker = false })
        }
    }

    private func swatch<Content: View>(name: String,
                                       isSelected: Bool,
                                       action: @escaping () -> Void,
                                       @ViewBuilder content: () -> Content) -> some View {
        Button(action: action) {
            content()
                .frame(width: Layout.swatchSize, height: Layout.swatchSize)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(Color(UIColor.separator), lineWidth: 1))
                .padding(Layout.selectionGap + Layout.selectionWidth)
                .overlay(
                    Circle()
                        .strokeBorder(Color.jami, lineWidth: Layout.selectionWidth)
                        .opacity(isSelected ? 1 : 0)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The theme's background crossed out, the usual mark for "none".
    private var defaultSwatch: some View {
        ZStack {
            Color(UIColor.systemBackground)
            Rectangle()
                .fill(Color(UIColor.systemGray3))
                .frame(width: Layout.crossOutWidth)
                .rotationEffect(.degrees(45))
        }
    }

    /// A rainbow until a color is picked, then that color.
    @ViewBuilder private var customSwatch: some View {
        if let color = customColor {
            ChatBackgroundView(fill: .color(color))
        } else {
            AngularGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]),
                            center: .center)
        }
    }
}

/// The system color picker, to show in a sheet.
struct SystemColorPicker: UIViewControllerRepresentable {
    let title: String
    let color: UIColor
    let onChange: (UIColor) -> Void
    let onDone: () -> Void

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.title = title
        picker.supportsAlpha = false
        picker.selectedColor = color
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIColorPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        let parent: SystemColorPicker

        init(_ parent: SystemColorPicker) {
            self.parent = parent
        }

        func colorPickerViewController(_ viewController: UIColorPickerViewController,
                                       didSelect color: UIColor,
                                       continuously: Bool) {
            parent.onChange(color)
        }

        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            parent.onDone()
        }
    }
}
