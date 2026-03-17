//
//  WebViewViewController.swift
//  ImageFeed
//
//  Created by I on 08.01.2026.
//

import UIKit
import WebKit

protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

final class WebViewViewController: UIViewController {

    weak var delegate: WebViewViewControllerDelegate?

    private var estimatedProgressObservation: NSKeyValueObservation?
    private var didHandleCode = false

    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = .black
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKVO()
        loadAuthPage()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(webView)
        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: self,
            action: #selector(didTapBack)
        )
        navigationItem.leftBarButtonItem?.tintColor = .black
    }

    private func setupKVO() {
        estimatedProgressObservation = webView.observe(
            \.estimatedProgress,
            options: []
        ) { [weak self] _, _ in
            self?.updateProgress()
        }
    }

    private func loadAuthPage() {
        // Build URL via string interpolation to preserve literal '+' in scope
        // (URLQueryItem encodes '+' as '%2B' which Unsplash rejects)
        let urlString = "https://unsplash.com/oauth/authorize"
            + "?client_id=\(Constants.accessKey)"
            + "&redirect_uri=\(Constants.redirectURI)"
            + "&response_type=code"
            + "&scope=\(Constants.accessScope)"

        guard let url = URL(string: urlString) else {
            print("WebViewViewController: Failed to build auth URL")
            return
        }

        webView.load(URLRequest(url: url))
    }

    // MARK: - Progress

    private func updateProgress() {
        progressView.progress = Float(webView.estimatedProgress)
        progressView.isHidden = abs(webView.estimatedProgress - 1.0) <= 0.0001
    }

    // MARK: - Actions

    @objc private func didTapBack() {
        delegate?.webViewViewControllerDidCancel(self)
    }
}

// MARK: - WKNavigationDelegate

extension WebViewViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let code = code(from: navigationAction.request.url) {
            handleCode(code)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let code = code(from: webView.url) {
            handleCode(code)
        }
    }

    private func handleCode(_ code: String) {
        guard !didHandleCode else { return }
        didHandleCode = true
        delegate?.webViewViewController(self, didAuthenticateWithCode: code)
    }

    private func code(from url: URL?) -> String? {
        guard
            let url,
            let components = URLComponents(string: url.absoluteString),
            let items = components.queryItems,
            let codeItem = items.first(where: { $0.name == "code" })
        else { return nil }

        return codeItem.value
    }
}
