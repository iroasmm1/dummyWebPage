//
//  PSD2TestingApplicationApp.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import SwiftUI

@main
struct PSD2TestingApplicationApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var authorizationCode: String?
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    print("🔗 App received deep link: \(url.absoluteString)")
                    handleDeepLink(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                    print("🔗 App received universal link activity")
                    if let url = userActivity.webpageURL {
                        print("🌐 Universal link URL: \(url.absoluteString)")
                        handleDeepLink(url)
                    }
                }
        }
    }
    
    @ViewBuilder
    private var RootView: some View {
        if authViewModel.isAuthenticated {
            DashboardView()
        } else {
            LoginView()
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        print("🔗 Deep link handler called: \(url.absoluteString)")
        
        // Log URL components for debugging
        print("   - Scheme: \(url.scheme ?? "nil")")
        print("   - Host: \(url.host ?? "nil")")
        print("   - Path: \(url.path)")
        print("   - Query: \(url.query ?? "nil")")
        
        // Check if this is a GitHub Pages universal link
        if url.host == "iroasmm1.github.io" && url.path.contains("/dummyWebPage/callback") {
            print("✅ GitHub Pages callback universal link detected")
        } else if url.scheme == "psd2banking" {
            print("✅ Custom URL scheme detected")
        } else {
            print("⚠️ Unknown URL format")
        }
        
        // Parse URL and extract query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("❌ Failed to parse URL components")
            return
        }
        
        // Extract the "code" parameter
        if let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
            print("✅ Authorization code extracted: \(code.prefix(20))..." )
            authorizationCode = code
            
            // Save to UserDefaults for access across the app
            UserDefaults.standard.set(code, forKey: "PSD2_AuthorizationCode")
            print("💾 Code saved to UserDefaults")
            
            // Post notification so other views can react
            NotificationCenter.default.post(
                name: NSNotification.Name("AuthorizationCodeReceived"),
                object: nil,
                userInfo: ["code": code]
            )
            print("📢 Notification posted: AuthorizationCodeReceived")
        } else {
            print("⚠️ No 'code' parameter found in URL")
            print("   Available query items: \(components.queryItems?.map { "\($0.name)=\($0.value ?? "nil")" }.joined(separator: ", ") ?? "none")")
        }
    }
}

