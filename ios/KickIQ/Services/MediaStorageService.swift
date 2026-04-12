import Foundation
import UIKit

@Observable
@MainActor
class MediaStorageService {
    var items: [MediaItem] = []

    private let itemsKey = "kickiq_media_items"
    private let mediaDirectory: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        mediaDirectory = docs.appendingPathComponent("KickIQMedia", isDirectory: true)

        if !FileManager.default.fileExists(atPath: mediaDirectory.path) {
            try? FileManager.default.createDirectory(at: mediaDirectory, withIntermediateDirectories: true)
        }

        loadItems()
    }

    private func loadItems() {
        guard let data = UserDefaults.standard.data(forKey: itemsKey),
              let decoded = try? JSONDecoder().decode([MediaItem].self, from: data) else { return }
        items = decoded
    }

    private func persistItems() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: itemsKey)
        }
    }

    func savePhoto(_ image: UIImage, tag: MediaTag = .training, caption: String = "", playerName: String? = nil, sessionID: String? = nil) -> MediaItem? {
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = mediaDirectory.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        do {
            try data.write(to: fileURL)
        } catch {
            return nil
        }

        let item = MediaItem(
            type: .photo,
            fileName: fileName,
            tag: tag,
            caption: caption,
            playerName: playerName,
            sessionID: sessionID
        )
        items.insert(item, at: 0)
        persistItems()
        return item
    }

    func saveEditedPhoto(_ image: UIImage, originalItem: MediaItem) -> MediaItem? {
        let fileName = "edited_" + UUID().uuidString + ".jpg"
        let fileURL = mediaDirectory.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        do {
            try data.write(to: fileURL)
        } catch {
            return nil
        }

        let item = MediaItem(
            type: .photo,
            fileName: fileName,
            tag: originalItem.tag,
            caption: originalItem.caption,
            playerName: originalItem.playerName,
            sessionID: originalItem.sessionID,
            isEdited: true
        )
        items.insert(item, at: 0)
        persistItems()
        return item
    }

    func loadImage(for item: MediaItem) -> UIImage? {
        let fileURL = mediaDirectory.appendingPathComponent(item.fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    func imageURL(for item: MediaItem) -> URL {
        mediaDirectory.appendingPathComponent(item.fileName)
    }

    func updateItem(_ updated: MediaItem) {
        guard let idx = items.firstIndex(where: { $0.id == updated.id }) else { return }
        items[idx] = updated
        persistItems()
    }

    func deleteItem(_ item: MediaItem) {
        let fileURL = mediaDirectory.appendingPathComponent(item.fileName)
        try? FileManager.default.removeItem(at: fileURL)
        items.removeAll { $0.id == item.id }
        persistItems()
    }

    func deleteItems(_ itemIDs: Set<String>) {
        for id in itemIDs {
            if let item = items.first(where: { $0.id == id }) {
                let fileURL = mediaDirectory.appendingPathComponent(item.fileName)
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        items.removeAll { itemIDs.contains($0.id) }
        persistItems()
    }

    func items(for tag: MediaTag?) -> [MediaItem] {
        guard let tag else { return items }
        return items.filter { $0.tag == tag }
    }

    var photoCount: Int {
        items.filter { $0.type == .photo }.count
    }

    var storageUsedMB: Double {
        let totalBytes = items.compactMap { item -> Int? in
            let url = mediaDirectory.appendingPathComponent(item.fileName)
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            return attrs?[.size] as? Int
        }.reduce(0, +)
        return Double(totalBytes) / (1024 * 1024)
    }
}
