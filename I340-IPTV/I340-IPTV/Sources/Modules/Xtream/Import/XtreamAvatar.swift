//
//  XtreamAvatar.swift
//  I340_IPTV
//

import PhotosUI
import SwiftUI

/// Avatars picked from the photo library live in Application Support; profiles keep their file name
/// (prefixed `custom_`) in the same field that holds a bundled avatar's asset name.
enum XtreamAvatarStore {
    private static let prefix = "custom_"

    private static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("XtreamAvatars", isDirectory: true)
    }

    static func isCustom(_ name: String) -> Bool { name.hasPrefix(prefix) }

    static func image(for name: String) -> UIImage? {
        guard isCustom(name) else { return nil }
        return UIImage(contentsOfFile: directory.appendingPathComponent(name).path)
    }

    /// Saves a square, downscaled copy of the photo; returns its avatar name.
    static func save(_ image: UIImage) -> String? {
        let side = min(image.size.width, image.size.height)
        let target = min(side, 512)
        let crop = CGRect(
            x: (image.size.width - side) / 2,
            y: (image.size.height - side) / 2,
            width: side,
            height: side
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let square = UIGraphicsImageRenderer(size: CGSize(width: target, height: target), format: format).image { _ in
            image.draw(in: CGRect(
                x: -crop.origin.x * target / side,
                y: -crop.origin.y * target / side,
                width: image.size.width * target / side,
                height: image.size.height * target / side
            ))
        }
        guard let data = square.jpegData(compressionQuality: 0.85) else { return nil }
        let name = "\(prefix)\(UUID().uuidString).jpg"
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: directory.appendingPathComponent(name), options: .atomic)
            return name
        } catch {
            return nil
        }
    }
}

/// Avatar of an Xtream profile, bundled or picked by the user. Fills the frame it is given.
struct XtreamAvatarImage: View {
    let name: String

    var body: some View {
        if let image = XtreamAvatarStore.image(for: name) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            Image(name).resizable().scaledToFill()
        }
    }
}

/// Photo library picker that returns one image (needs no photo permission).
struct AvatarPhotoPicker: UIViewControllerRepresentable {
    let onPick: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (UIImage?) -> Void

        init(onPick: @escaping (UIImage?) -> Void) {
            self.onPick = onPick
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                onPick(nil)
                return
            }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async { self.onPick(object as? UIImage) }
            }
        }
    }
}
