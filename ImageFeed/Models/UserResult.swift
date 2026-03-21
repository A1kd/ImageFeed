import Foundation

struct UserResult: Decodable {
    let profileImage: ProfileImageURLs

    struct ProfileImageURLs: Decodable {
        let small: String
        let medium: String
        let large: String
    }

    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}
