import Foundation
import WebKit
import SwiftUI



extension Bundle {
    func readFileAsBase64(_ filename: String) -> String? {
        print("Attempting to read file: \(filename)")
        
        if let filePath = self.path(forResource: filename, ofType: nil) {
            print("File found at path: \(filePath)")
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                return data.base64EncodedString()
            } catch {
                print("Error reading file: \(error.localizedDescription)")
            }
        } else {
            print("File not found in main bundle: \(filename)")
        }
        
        return nil
    }

    func listContents() {
        guard let resourcePath = self.resourcePath else {
            print("Unable to access resource path")
            return
        }
        
        do {
            let fileManager = FileManager.default
            let items = try fileManager.contentsOfDirectory(atPath: resourcePath)
            
            print("Contents of app bundle:")
            for item in items {
                print("- \(item)")
            }
        } catch {
            print("Error listing bundle contents: \(error.localizedDescription)")
        }
    }
}

struct P5WebView: UIViewRepresentable {
    let htmlString: String
    let onWebViewLoaded: (WKWebView) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.tag = 100
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: P5WebView

        init(_ parent: P5WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.onWebViewLoaded(webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView navigation failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView provisional navigation failed: \(error.localizedDescription)")
        }
    }
}
