import Foundation
import SwiftData

@Model
final class NFCChip {
    @Attribute(.unique) var id: UUID
    var tagIdentifier: String
    var name: String
    var dateRegistered: Date

    init(tagIdentifier: String, name: String = "My Brick") {
        self.id = UUID()
        self.tagIdentifier = tagIdentifier
        self.name = name
        self.dateRegistered = Date()
    }
}
