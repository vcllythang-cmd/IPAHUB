
import SwiftUI
import WebKit
import UIKit

private let websiteURL = URL(string: "https://iosgodsmod.xyz")!

struct ContentView: View {
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var progress: Double = 0
    @State private var webView: WKWebView?

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            if let webView {
                WebViewContainer(
                    webView: webView,
                    isLoading: $isLoading,
                    loadFailed: $loadFailed,
                    progress: $progress
                )
                .ignoresSafeArea(edges: .bottom)
            } else {
                ProgressView("Đang khởi tạo IPA HUB…")
                    .tint(Color.blue)
            }

            if isLoading && !loadFailed {
                VStack(spacing: 10) {
                    ProgressView(value: progress)
                        .tint(Color.blue)
                        .frame(width: 150)

                    Text("Đang tải IPA HUB…")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(cornerRadius: 16)
                )
            }

            if loadFailed {
                VStack(spacing: 14) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 34))
                        .foregroundStyle(Color.blue)

                    Text("Không thể kết nối")
                        .font(.system(size: 20, weight: .bold))

                    Text("Kiểm tra kết nối mạng rồi thử tải lại IPA HUB.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        loadFailed = false
                        isLoading = true

                        webView?.load(
                            URLRequest(
                                url: websiteURL,
                                cachePolicy: .reloadIgnoringLocalCacheData,
                                timeoutInterval: 30
                            )
                        )
                    } label: {
                        Text("Thử lại")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 12)
                            .background(Color.blue, in: Capsule())
                    }
                }
                .padding(28)
                .frame(maxWidth: 320)
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(cornerRadius: 22)
                )
            }
        }
        .onAppear {
            if webView == nil {
                webView = WebViewFactory.make()
            }
        }
        .statusBarHidden(false)
    }
}

private struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView

    @Binding var isLoading: Bool
    @Binding var loadFailed: Bool
    @Binding var progress: Double

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        context.coordinator.observe(webView)

        if webView.url == nil {
            webView.load(
                URLRequest(
                    url: websiteURL,
                    cachePolicy: .useProtocolCachePolicy,
                    timeoutInterval: 30
                )
            )
        }

        return webView
    }

    func updateUIView(
        _ uiView: WKWebView,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(
            isLoading: $isLoading,
            loadFailed: $loadFailed,
            progress: $progress
        )
    }

    final class Coordinator: NSObject,
        WKNavigationDelegate,
        WKUIDelegate {

        @Binding var isLoading: Bool
        @Binding var loadFailed: Bool
        @Binding var progress: Double

        private var observation: NSKeyValueObservation?

        init(
            isLoading: Binding<Bool>,
            loadFailed: Binding<Bool>,
            progress: Binding<Double>
        ) {
            _isLoading = isLoading
            _loadFailed = loadFailed
            _progress = progress
        }

        func observe(_ webView: WKWebView) {
            observation = webView.observe(
                \.estimatedProgress,
                options: [.new]
            ) { [weak self] view, _ in
                DispatchQueue.main.async {
                    self?.progress = view.estimatedProgress
                }
            }
        }

        func webView(
            _ webView: WKWebView,
            didStartProvisionalNavigation navigation: WKNavigation!
        ) {
            isLoading = true
            loadFailed = false
        }

        func webView(
            _ webView: WKWebView,
            didFinish navigation: WKNavigation!
        ) {
            isLoading = false
            loadFailed = false
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            handle(error)
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            handle(error)
        }

        private func handle(_ error: Error) {
            let nsError = error as NSError

            if nsError.code == NSURLErrorCancelled {
                return
            }

            isLoading = false
            loadFailed = true
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            if url.scheme == "http" || url.scheme == "https" {
                if url.host == "iosgodsmod.xyz" ||
                   url.host == "www.iosgodsmod.xyz" {

                    decisionHandler(.allow)

                } else {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                }

            } else if ["mailto", "tel"].contains(url.scheme ?? "") {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)

            } else {
                decisionHandler(.allow)
            }
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {

            if navigationAction.targetFrame == nil,
               let url = navigationAction.request.url {

                if url.host == "iosgodsmod.xyz" ||
                   url.host == "www.iosgodsmod.xyz" {

                    webView.load(URLRequest(url: url))

                } else {
                    UIApplication.shared.open(url)
                }
            }

            return nil
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            completionHandler()
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            completionHandler(true)
        }
    }
}

private enum WebViewFactory {
    static func make() -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true

        let configuration = WKWebViewConfiguration()

        configuration.defaultWebpagePreferences = preferences
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let view = WKWebView(
            frame: .zero,
            configuration: configuration
        )

        view.isOpaque = false
        view.backgroundColor = .white
        view.scrollView.backgroundColor = .white

        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.bounces = true

        return view
    }
}
