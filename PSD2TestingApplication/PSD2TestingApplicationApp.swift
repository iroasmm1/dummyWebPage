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
            if authViewModel.isAuthenticated {
                DashboardView()
                    .environmentObject(authViewModel)
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                        if let url = userActivity.webpageURL {
                            handleDeepLink(url)
                        }
                    }
            } else {
                LoginView()
                    .environmentObject(authViewModel)
                    .onOpenURL { url in
                        print("🔗 LoginView received URL: \(url)")
                        handleDeepLink(url)
                    }
                    .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                        if let url = userActivity.webpageURL {
                            print("🔗 LoginView received universal link: \(url)")
                            handleDeepLink(url)
                        }
                    }
            }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        print("🔗 Deep link received: \(url.absoluteString)")
        
        // Check if this is a GitHub Pages universal link
        if url.host == "iroasmm1.github.io" && url.path.contains("/dummyWebPage/callback") {
            print("✅ GitHub Pages callback universal link detected")
        } else if url.scheme == "psd2banking" {
            print("✅ Custom URL scheme detected")
        }
        
        // Parse URL and extract query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("❌ Failed to parse URL components")
            return
        }
        
        // Extract the "code" parameter
        if let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
            print("✅ Authorization code received: \(code)")
            authorizationCode = code
            
            // Save to UserDefaults for access across the app
            UserDefaults.standard.set(code, forKey: "PSD2_AuthorizationCode")
            
            // Post notification so other views can react
            NotificationCenter.default.post(
                name: NSNotification.Name("AuthorizationCodeReceived"),
                object: nil,
                userInfo: ["code": code]
            )
        } else {
            print("⚠️ No 'code' parameter found in URL")
        }
    }
}

