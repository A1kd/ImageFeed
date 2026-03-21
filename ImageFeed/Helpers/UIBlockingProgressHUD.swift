import UIKit

final class UIBlockingProgressHUD {

    private static var window: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    static func show() {
        guard let window else { return }
        let overlay = UIView(frame: window.bounds)
        overlay.tag = 998
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.center = CGPoint(x: overlay.bounds.midX, y: overlay.bounds.midY)
        indicator.startAnimating()
        overlay.addSubview(indicator)

        window.addSubview(overlay)
        window.isUserInteractionEnabled = false
    }

    static func dismiss() {
        guard let window else { return }
        window.viewWithTag(998)?.removeFromSuperview()
        window.isUserInteractionEnabled = true
    }
}
