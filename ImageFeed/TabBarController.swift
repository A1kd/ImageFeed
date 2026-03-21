import UIKit

final class TabBarController: UITabBarController {

    override func awakeFromNib() {
        super.awakeFromNib()

        let storyboard = UIStoryboard(name: "Main", bundle: .main)

        let imagesListVC = storyboard.instantiateViewController(
            withIdentifier: "ImagesListViewController"
        )
        imagesListVC.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_editorial_active"),
            selectedImage: nil
        )

        let profileVC = ProfileViewController()
        profileVC.tabBarItem = UITabBarItem(
            title: "",
            image: UIImage(named: "tab_profile_active"),
            selectedImage: nil
        )

        viewControllers = [imagesListVC, profileVC]
    }
}
