import Foundation

struct AppGroup: Identifiable {
    let id = UUID()
    var name: String
    var members: [AppContact]
    var photoData: Data?
}
