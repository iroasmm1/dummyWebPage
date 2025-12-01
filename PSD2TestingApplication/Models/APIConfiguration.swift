//
//  APIConfiguration.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import Foundation
import Combine

// API Step/Section types
enum APIStep: String, Codable, CaseIterable {
    case consentCreation = "Consent Creation"
    case checkConsentDetails = "Check Consent Details"
    case scaLinkGeneration = "Generating SCA Link"
    case consentAuthorization = "Consent Authorization"
    case validateConsent = "Validate Consent Active"
    case generateAccessToken = "Generate Active Access Token"
}

struct APIConfiguration {
    let userId: UUID
    let profileId: UUID
    let bankId: UUID
    let environment: String // e.g., "SB Test", "RD Production"
    let step: APIStep // Which API step this config is for
    var method: String
    var url: String
    var headers: [String: String]
    var queryParameters: [String: String]
    var body: String
    var response: String // Cached response
    
    var key: String {
        "\(userId)-\(profileId)-\(bankId)-\(environment)-\(step.rawValue)"
    }
}

class APIConfigurationManager: NSObject, ObservableObject {
    @Published var configurations: [String: APIConfiguration] = [:]
    
    private static let cacheDirectory: URL = {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("APIConfigurations")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true, attributes: nil)
        return cacheDir
    }()
    
    private var userId: UUID?
    private var profileId: UUID?
    
    override init() {
        super.init()
    }
    
    func setContext(userId: UUID, profileId: UUID) {
        self.userId = userId
        self.profileId = profileId
        loadConfigurations()
    }
    
    func getConfiguration(for bankId: UUID, environment: String, step: APIStep) -> APIConfiguration {
        guard let userId = userId, let profileId = profileId else {
            return defaultConfiguration(bankId: bankId, environment: environment, step: step)
        }
        
        let key = "\(userId)-\(profileId)-\(bankId)-\(environment)-\(step.rawValue)"
        if let existing = configurations[key] {
            return existing
        }
        
        return defaultConfiguration(bankId: bankId, environment: environment, step: step)
    }
    
    private func defaultConfiguration(bankId: UUID, environment: String, step: APIStep) -> APIConfiguration {
        // Use temporary IDs if user/profile context isn't set yet
        let tempUserId = userId ?? UUID()
        let tempProfileId = profileId ?? UUID()
        
        // Customize defaults based on environment and step
        let (method, url, headers, body) = getDefaultsForStep(step, environment: environment)
        
        return APIConfiguration(
            userId: tempUserId,
            profileId: tempProfileId,
            bankId: bankId,
            environment: environment,
            step: step,
            method: method,
            url: url,
            headers: headers,
            queryParameters: [:],
            body: body,
            response: ""
        )
    }
    
    private func getDefaultsForStep(_ step: APIStep, environment: String) -> (method: String, url: String, headers: [String: String], body: String) {
        // Determine if this is Real Data Prelive environment
        let isRealDataPrelive = environment.contains("RD") && environment.contains("Prelive")
        
        switch step {
        case .consentCreation:
            if isRealDataPrelive {
                // Real Data Prelive
                let url = "https://api-auth-uat.raiffeisenonline.ro/rbro/uat01/psd2-bgs-consent-api-1.3.2-rbro/v1/consents"
                let headers: [String: String] = [
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                    "PSU-ID": "obp_automation01",
                    "X-Request-ID": "ae177c68-b6b3-477a-897d-5a91be23db73",
                    "client_id": "ErXShWNpSq5UIuuOrt6JBDqK3xmaFv1y",
                    "psu-user-agent": "Myappa/1.2 Dalvik/2.1.0 (Linux; U; Android 6.0.1; vivo 1610 Build/MMB29M)"
                ]
                let body = """
{
  "access": {
    "accounts": [
      {
        "iban": "RO03RZBR0000060012254737",
        "currency": "RON"
      }
    ],
    "balances": [
      {
        "iban": "RO03RZBR0000060012254737",
        "currency": "RON"
      }
    ],
    "transactions": [
      {
        "iban": "RO03RZBR0000060012254737",
        "currency": "RON"
      }
    ]
  },
  "recurringIndicator": true,
  "validUntil": "2026-11-07",
  "frequencyPerDay": 2,
  "combinedServiceIndicator": true
}
"""
                return ("POST", url, headers, body)
            } else {
                // Sandbox Test (default)
                let url = "https://api-auth-test.raiffeisenonline.ro/rbro/prod02/psd2-bgs-consent-api-1.3.2-rbro/v1/consents"
                let headers: [String: String] = [
                    "Accept": "application/json",
                    "Client-Id": "MBzrLUaY6YsoYNrpy9Z2YQmUSmDU8Knu",
                    "Content-Type": "application/json",
                    "PSU-ID": "9999999996",
                    "X-Request-ID": "ae177c68-b6b3-477a-897d-5a91be23db73",
                    "psu-user-agent": "Myappa/1.2 Dalvik/2.1.0 (Linux; U; Android 6.0.1; vivo 1610 Build/MMB29M)"
                ]
                let body = """
{
  "access": {
    "accounts": [
      {
        "iban": "RO78RZBR0000069999999910",
        "currency": "RON"
      }
    ],
    "balances": [
      {
        "iban": "RO78RZBR0000069999999910",
        "currency": "RON"
      }
    ],
    "transactions": [
      {
        "iban": "RO78RZBR0000069999999910",
        "currency": "RON"
      }
    ]
  },
  "recurringIndicator": true,
  "validUntil": "2025-12-29",
  "frequencyPerDay": 4,
  "combinedServiceIndicator": true
}
"""
                return ("POST", url, headers, body)
            }
            
        case .checkConsentDetails:
            if isRealDataPrelive {
                // Real Data Prelive
                let url = "https://api-auth-uat.raiffeisenonline.ro/rbro/uat01/psd2-bgs-consent-api-1.3.2-rbro/v1/consents/{consentId}"
                let headers: [String: String] = [
                    "Accept": "application/json",
                    "Cache-Control": "no-cache",
                    "Client-Id": "ErXShWNpSq5UIuuOrt6JBDqK3xmaFv1y",
                    "Content-Type": "application/json",
                    "X-Request-ID": "944dd01a-bf16-4efe-bfeb-746de9eb9730"
                ]
                let body = ""
                return ("GET", url, headers, body)
            } else {
                // Sandbox Production (default)
                let url = "https://api-auth-test.raiffeisenonline.ro/rbro/prod02/psd2-bgs-consent-api-1.3.2-rbro/v1/consents/{consentId}"
                let headers: [String: String] = [
                    "Accept": "application/json",
                    "Cache-Control": "no-cache",
                    "Client-Id": "MBzrLUaY6YsoYNrpy9Z2YQmUSmDU8Knu",
                    "Content-Type": "application/json",
                    "X-Request-ID": "944dd01a-bf16-4efe-bfeb-746de9eb9730"
                ]
                let body = ""
                return ("GET", url, headers, body)
            }
            
        case .scaLinkGeneration:
            if isRealDataPrelive {
                // Real Data Prelive
                let url = "https://api-auth2-uat.raiffeisenonline.ro/rbro/uat01/psd2-auth-bridge-api/bridge/authorize?client_id=ErXShWNpSq5UIuuOrt6JBDqK3xmaFv1y&response_type=code&scope=AISP&scaMethod=APP_TO_APP_IOS"
                let headers: [String: String] = [
                    "Accept": "application/json",
                    "Content-Type": "application/json"
                ]
                let body = ""
                return ("GET", url, headers, body)
            } else {
                // Sandbox Test (default)
                let url = "https://api-auth2-test.raiffeisenonline.ro/rbro/prod02/psd2-auth-bridge-api/bridge/authorize?client_id=MBzrLUaY6YsoYNrpy9Z2YQmUSmDU8Knu&response_type=code&scope=AISP&scaMethod=APP_TO_APP_IOS"
                let headers: [String: String] = [
                    "Accept": "application/json",
                    "Content-Type": "application/json"
                ]
                let body = ""
                return ("GET", url, headers, body)
            }
            
        case .consentAuthorization:
            if isRealDataPrelive {
                // Real Data Prelive
                let url = "https://api-auth-uat.raiffeisenonline.ro/rbro/uat01/psd2-auth-bridge-api/bridge/authorize"
                let headers: [String: String] = [
                    "Accept": "application/json",
                    "Content-Type": "application/json"
                ]
                let body = ""
                return ("POST", url, headers, body)
            } else {
                // Sandbox Test (default)
                let url = "https://api-auth-test.raiffeisenonline.ro/rbro/prod02/psd2-auth-bridge-api/bridge/authorize"
                let headers: [String: String] = [
                    "Accept": "application/json",
                    "Content-Type": "application/json"
                ]
                let body = ""
                return ("POST", url, headers, body)
            }
            
        case .validateConsent:
            if isRealDataPrelive {
                // Real Data Prelive
                let url = "https://api-auth-uat.raiffeisenonline.ro/rbro/uat01/psd2-bgs-consent-api-1.3.2-rbro/v1/consents/{consentId}/status"
                let headers: [String: String] = [
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                    "client_id": "ErXShWNpSq5UIuuOrt6JBDqK3xmaFv1y",
                    "X-Request-ID": "ae177c68-b6b3-477a-897d-5a91be23db73"
                ]
                let body = ""
                return ("GET", url, headers, body)
            } else {
                // Sandbox Test (default)
                let url = "https://api-auth-test.raiffeisenonline.ro/rbro/prod02/psd2-bgs-consent-api-1.3.2-rbro/v1/consents/{consentId}/status"
                let headers: [String: String] = [
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                    "Client-Id": "MBzrLUaY6YsoYNrpy9Z2YQmUSmDU8Knu",
                    "X-Request-ID": "ae177c68-b6b3-477a-897d-5a91be23db73"
                ]
                let body = ""
                return ("GET", url, headers, body)
            }
            
        case .generateAccessToken:
            if isRealDataPrelive {
                // Real Data Prelive
                let url = "https://api-auth2-uat.raiffeisenonline.ro/rbro/uat01/aisp/oauth2/token"
                let headers: [String: String] = [
                    "Content-Type": "application/x-www-form-urlencoded",
                    "accept": "application/json"
                ]
                let body = "grant_type=authorization_code&client_id=ErXShWNpSq5UIuuOrt6JBDqK3xmaFv1y&client_secret=vt3HX8yUr5CiXI4rNIty9nyHIECHjnJf&code={authorizationCode}&scope=AISP"
                return ("POST", url, headers, body)
            } else {
                // Sandbox Production (default)
                let url = "https://api-auth2-test.raiffeisenonline.ro/rbro/prod02/aisp/oauth2/token"
                let headers: [String: String] = [
                    "Content-Type": "application/x-www-form-urlencoded",
                    "accept": "application/json"
                ]
                let body = "grant_type=authorization_code&client_id=MBzrLUaY6YsoYNrpy9Z2YQmUSmDU8Knu&client_secret=piRfYvg7Tmx3sXFgREI7YW9hqDV0Z9B0&code={authorizationCode}&scope=AISP"
                return ("POST", url, headers, body)
            }
        }
    }
    
    func saveConfiguration(_ config: APIConfiguration) {
        configurations[config.key] = config
        persistConfigurations()
    }
    
    private func persistConfigurations() {
        guard let userId = userId, let profileId = profileId else { return }
        
        let fileName = "config_\(userId)_\(profileId).json"
        let fileURL = Self.cacheDirectory.appendingPathComponent(fileName)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(Array(configurations.values))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to persist API configurations: \(error)")
        }
    }
    
    private func loadConfigurations() {
        guard let userId = userId, let profileId = profileId else { return }
        
        let fileName = "config_\(userId)_\(profileId).json"
        let fileURL = Self.cacheDirectory.appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("📁 No existing configurations found for user \(userId)")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let configs = try decoder.decode([APIConfiguration].self, from: data)
            configurations = Dictionary(uniqueKeysWithValues: configs.map { ($0.key, $0) })
            print("✅ Loaded \(configs.count) configurations for user \(userId)")
        } catch {
            print("❌ Failed to load API configurations: \(error)")
        }
    }
    
    // Clear configurations for the current user (useful for logout)
    func clearConfigurations() {
        guard let userId = userId, let profileId = profileId else { return }
        configurations.removeAll()
        
        let fileName = "config_\(userId)_\(profileId).json"
        let fileURL = Self.cacheDirectory.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("✅ Cleared configurations for user \(userId)")
        } catch {
            print("⚠️ Failed to clear configurations: \(error)")
        }
    }
}

extension APIConfiguration: Codable {
    enum CodingKeys: String, CodingKey {
        case userId, profileId, bankId, environment, step, method, url, headers, queryParameters, body, response
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        userId = try container.decode(UUID.self, forKey: .userId)
        profileId = try container.decode(UUID.self, forKey: .profileId)
        bankId = try container.decode(UUID.self, forKey: .bankId)
        environment = try container.decode(String.self, forKey: .environment)
        
        // Handle legacy configurations without 'step' field
        if let stepValue = try? container.decode(APIStep.self, forKey: .step) {
            step = stepValue
        } else {
            // Default to consentCreation for legacy data
            step = .consentCreation
        }
        
        method = try container.decode(String.self, forKey: .method)
        url = try container.decode(String.self, forKey: .url)
        headers = try container.decode([String: String].self, forKey: .headers)
        
        // Handle legacy configurations without 'queryParameters' field
        if let queryParams = try? container.decode([String: String].self, forKey: .queryParameters) {
            queryParameters = queryParams
        } else {
            queryParameters = [:]
        }
        
        body = try container.decode(String.self, forKey: .body)
        response = try container.decode(String.self, forKey: .response)
    }
}
