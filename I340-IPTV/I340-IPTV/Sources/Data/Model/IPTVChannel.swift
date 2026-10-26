import Foundation

struct IPTVChannel: Codable, Hashable {
    var id: String
    var title: String
    var duration: Int
    var url: String
    var imageURL: String
    var groupTitle: String
    
    init(
        id: String = UUID().uuidString,
        title: String = "",
        duration: Int = -1,
        url: String = "",
        imageURL: String = "",
        groupTitle: String = ""
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.url = url
        self.imageURL = imageURL
        self.groupTitle = groupTitle
    }
    
    var imgUrl: String {
        get { imageURL }
        set { imageURL = newValue }
    }
}

extension IPTVChannel: Identifiable {}
