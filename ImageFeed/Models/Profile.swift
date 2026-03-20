import Foundation

struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
}

struct ProfileResult: Decodable {
    let username: String
    let firstName: String
    let lastName: String?
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName  = "last_name"
        case bio
    }
}

extension Profile {
    init(result: ProfileResult) {
        username  = result.username
        name      = [result.firstName, result.lastName].compactMap { $0 }.joined(separator: " ")
        loginName = "@\(result.username)"
        bio       = result.bio
    }
}
