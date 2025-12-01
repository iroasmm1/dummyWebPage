//
//  BankDetailView.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import SwiftUI
import Foundation
import Security
import WebKit
import SafariServices

struct BankDetailView: View {
    let bank: Bank
    let environment: PSD2Environment
    var user: User?
    var profile: Profile?
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var configManager = APIConfigurationManager()
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAPIEditor = false
    @State private var currentEditingStep: APIStep = .consentCreation
    
    // Per-step API Configuration and Responses
    @State private var consentConfig: APIConfiguration?
    @State private var checkConsentDetailsConfig: APIConfiguration?
    @State private var scaConfig: APIConfiguration?
    @State private var authConfig: APIConfiguration?
    @State private var validateConsentConfig: APIConfiguration?
    @State private var generateTokenConfig: APIConfiguration?
    
    @State private var isViewReady = false
    
    @State private var consentResponse: String = ""
    @State private var checkConsentDetailsResponse: String = ""
    @State private var scaResponse: String = ""
    @State private var validateConsentResponse: String = ""
    @State private var generateTokenResponse: String = ""
    @State private var scaLink: String = ""
    @State private var authorizationURL: String = ""
    @State private var consentId: String = ""
    @State private var authorizationCode: String = ""
    @State private var showAuthWebView = false
    @State private var shouldAttemptDeepLink = false
    @State private var preventDismiss = false
    
    @State private var isConsentCreated = false
    @State private var isConsentDetailsChecked = false
    @State private var isSCAGenerated = false
    @State private var isSCARedirectLaunched = false
    @State private var isAuthorized = false
    @State private var isConsentValidated = false
    @State private var isConsentStatusValid = false
    @State private var isAccessTokenGenerated = false
    
    @State private var isConsentFailed = false
    @State private var isConsentDetailsCheckFailed = false
    @State private var isSCAFailed = false
    @State private var isConsentValidationFailed = false
    @State private var isAccessTokenFailed = false
    
    // Current editing step's state
    @State private var requestMethod: String = "POST"
    @State private var requestURL: String = "https://api.example.com/v1/consents"
    @State private var headers: [String: String] = [:]
    @State private var queryParameters: [String: String] = [:]
    @State private var requestBody: String = ""
    @State private var certificatePath: String = ""
    @State private var certificatePassword: String = ""
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if isViewReady {
                VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Connect Bank")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        if isConsentCreated || isSCAGenerated || isAuthorized {
                            Button(action: {
                                resetConnection()
                            }) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Bank header
                        VStack(spacing: 12) {
                            Image(bank.logoName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            
                            Text(bank.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(bank.bic)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        
                        // Connection steps
                        VStack(spacing: 15) {
                            // Step 1: Consent Creation
                            ConnectionStepCard(
                                stepNumber: 1,
                                title: "Consent Creation",
                                description: "Create a consent request with the bank",
                                icon: "doc.text.fill",
                                color: .blue,
                                isCompleted: isConsentCreated,
                                isFailed: isConsentFailed,
                                isActive: !isConsentCreated && !isConsentFailed,
                                action: {
                                    createConsent()
                                },
                                onEditAPI: {
                                    loadStepConfiguration(step: .consentCreation)
                                    showAPIEditor = true
                                }
                            )
                            
                            // Step 2: Check Consent Details
                            ConnectionStepCard(
                                stepNumber: 2,
                                title: "Check Consent Details",
                                description: "Verify the consent details and status",
                                icon: "magnifyingglass.circle.fill",
                                color: .cyan,
                                isCompleted: isConsentDetailsChecked,
                                isFailed: isConsentDetailsCheckFailed,
                                isActive: isConsentCreated && !isConsentDetailsChecked && !isConsentDetailsCheckFailed,
                                action: {
                                    checkConsentDetails()
                                },
                                onEditAPI: {
                                    loadStepConfiguration(step: .checkConsentDetails)
                                    showAPIEditor = true
                                }
                            )
                            
                            // Step 3: Generating SCA link
                            ConnectionStepCard(
                                stepNumber: 3,
                                title: "Generating SCA Link",
                                description: "Generate Strong Customer Authentication link",
                                icon: "link.circle.fill",
                                color: .orange,
                                isCompleted: isSCAGenerated,
                                isFailed: isSCAFailed,
                                isActive: isConsentDetailsChecked && !isSCAGenerated && !isSCAFailed,
                                action: {
                                    generateSCALink()
                                },
                                onEditAPI: {
                                    loadStepConfiguration(step: .scaLinkGeneration)
                                    showAPIEditor = true
                                }
                            )
                            
                            // Step 4: Consent Authorization (Web View with SCA Link)
                            ConnectionStepCard(
                                stepNumber: 4,
                                title: "Consent Authorization",
                                description: "Authorize the consent with your bank credentials",
                                icon: "checkmark.shield.fill",
                                color: .green,
                                isCompleted: isAuthorized,
                                isFailed: false,
                                isActive: isSCAGenerated && !isAuthorized,
                                action: {
                                    if !scaLink.isEmpty {
                                        print("🔗 Opening SCA Link: \(scaLink)")
                                        attemptDeepLinkThenWebView(urlString: scaLink)
                                    } else {
                                        print("❌ No SCA link available")
                                    }
                                },
                                onEditAPI: nil,
                                buttonLabel: "Launch SCA Redirect"
                            )
                            
                            // Step 5: Validate Consent Active
                            ConnectionStepCard(
                                stepNumber: 5,
                                title: "Validate Consent Active",
                                description: "Check if the consent is active and valid",
                                icon: "checkmark.circle.fill",
                                color: .blue,
                                isCompleted: isConsentValidated,
                                isFailed: isConsentValidationFailed,
                                isActive: isSCARedirectLaunched && !isConsentValidated && !isConsentValidationFailed,
                                action: {
                                    validateConsent()
                                },
                                onEditAPI: {
                                    loadStepConfiguration(step: .validateConsent)
                                    showAPIEditor = true
                                },
                                buttonLabel: "Validate Consent"
                            )
                            
                            // Step 6: Generate Active Access Token
                            ConnectionStepCard(
                                stepNumber: 6,
                                title: "Generate Active Access Token",
                                description: "Generate an active access token for API calls",
                                icon: "key.fill",
                                color: .purple,
                                isCompleted: isAccessTokenGenerated,
                                isFailed: isAccessTokenFailed,
                                isActive: isConsentStatusValid && !isAccessTokenGenerated && !isAccessTokenFailed,
                                action: {
                                    generateAccessToken()
                                },
                                onEditAPI: {
                                    loadStepConfiguration(step: .generateAccessToken)
                                    showAPIEditor = true
                                }
                            )
                        }
                        .padding(.horizontal)
                        
                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.red.opacity(0.1))
                                )
                                .padding(.horizontal)
                        }
                        
                        // Consent Creation Response display
                        if (isConsentCreated || isConsentFailed) && !consentResponse.isEmpty {
                            ResponseCard(title: "Consent Creation Response", response: consentResponse)
                        }
                        
                        // Check Consent Details Response display
                        if (isConsentDetailsChecked || isConsentDetailsCheckFailed) && !checkConsentDetailsResponse.isEmpty {
                            ResponseCard(title: "Check Consent Details Response", response: checkConsentDetailsResponse)
                        }
                        
                        // SCA Response display
                        if (isSCAGenerated || isSCAFailed) && !scaResponse.isEmpty {
                            ResponseCard(title: "Generating SCA Link Response", response: scaResponse)
                        }
                        
                        // Validate Consent Response display
                        if (isConsentValidated || isConsentValidationFailed) && !validateConsentResponse.isEmpty {
                            ResponseCard(title: "Validate Consent Response", response: validateConsentResponse)
                        }
                        
                        // Generate Access Token Response display
                        if (isAccessTokenGenerated || isAccessTokenFailed) && !generateTokenResponse.isEmpty {
                            ResponseCard(title: "Generate Access Token Response", response: generateTokenResponse)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.vertical)
                }
            }
            } else {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading configurations...")
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
            }
        }
        .sheet(isPresented: $showAPIEditor) {
            APIRequestEditorView(
                bank: bank,
                environment: environment,
                requestMethod: $requestMethod,
                requestURL: $requestURL,
                headers: $headers,
                requestBody: $requestBody,
                certificatePath: $certificatePath,
                certificatePassword: $certificatePassword,
                queryParameters: $queryParameters,
                onSaveConfiguration: {
                    saveAPIConfiguration()
                }
            )
        }
        .sheet(isPresented: $showAuthWebView, onDismiss: {
            print("🔄 [BankDetailView] Safari sheet dismissed - isAuthorized: \(isAuthorized)")
            preventDismiss = false
        }) {
            if !scaLink.isEmpty, let url = URL(string: scaLink) {
                SafariView(url: url, onDismiss: {
                    print("👋 [BankDetailView] User manually closed Safari")
                    showAuthWebView = false
                    preventDismiss = true
                    // Don't set isAuthorized here - only set it when we actually receive the authorization code
                    // If user manually closes without completing auth, they stay on this page
                })
            } else {
                VStack {
                    Text("No SCA URL available")
                        .foregroundColor(.secondary)
                        .padding()
                    Button("Close") {
                        showAuthWebView = false
                    }
                    .padding()
                }
            }
        }
        .interactiveDismissDisabled(showAuthWebView)
        .onAppear {
            print("🔍 [BankDetailView] onAppear - user: \(user?.id.uuidString ?? "nil"), profile: \(profile?.id.uuidString ?? "nil")")
            
            // Set context for config manager if user and profile are available
            if let user = user, let profile = profile {
                print("✅ [BankDetailView] Setting config manager context")
                configManager.setContext(userId: user.id, profileId: profile.id)
            } else {
                print("⚠️ [BankDetailView] User or profile is nil, cannot set context")
            }
            
            loadAPIConfiguration()
            
            print("📋 [BankDetailView] Configurations loaded:")
            print("   - Consent: \(consentConfig != nil)")
            print("   - Check Consent Details: \(checkConsentDetailsConfig != nil)")
            print("   - SCA: \(scaConfig != nil)")
            print("   - Auth: \(authConfig != nil)")
            
            // Listen for authorization code from deep link/universal link
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("AuthorizationCodeReceived"),
                object: nil,
                queue: .main
            ) { notification in
                if let code = notification.userInfo?["code"] as? String {
                    print("🔗 [BankDetailView] Received authorization code from callback: \(code)")
                    print("   - Code length: \(code.count)")
                    authorizationCode = code
                    
                    // Also save to UserDefaults
                    UserDefaults.standard.set(code, forKey: "PSD2_AuthorizationCode")
                    print("   - Saved to UserDefaults")
                    
                    // Automatically mark authorization as complete and close webview
                    isAuthorized = true
                    showAuthWebView = false
                    
                    print("✅ [BankDetailView] Authorization completed successfully")
                } else {
                    print("❌ [BankDetailView] Notification received but no code found in userInfo")
                    print("   - userInfo: \(notification.userInfo ?? [:])")
                }
            }
            
            // Mark view as ready after a brief delay to ensure all state updates
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isViewReady = true
                print("✅ [BankDetailView] View marked as ready")
            }
        }
    }
    
    // MARK: - Configuration Loading
    
    private func loadAPIConfiguration() {
        print("🔄 [loadAPIConfiguration] Starting to load configurations")
        print("   - Bank ID: \(bank.id)")
        print("   - Environment: \(environment.rawValue)")
        
        consentConfig = configManager.getConfiguration(for: bank.id, environment: environment.rawValue, step: .consentCreation)
        checkConsentDetailsConfig = configManager.getConfiguration(for: bank.id, environment: environment.rawValue, step: .checkConsentDetails)
        scaConfig = configManager.getConfiguration(for: bank.id, environment: environment.rawValue, step: .scaLinkGeneration)
        authConfig = configManager.getConfiguration(for: bank.id, environment: environment.rawValue, step: .consentAuthorization)
        validateConsentConfig = configManager.getConfiguration(for: bank.id, environment: environment.rawValue, step: .validateConsent)
        generateTokenConfig = configManager.getConfiguration(for: bank.id, environment: environment.rawValue, step: .generateAccessToken)
        
        print("✅ [loadAPIConfiguration] Configurations retrieved:")
        print("   - Consent URL: \(consentConfig?.url ?? "nil")")
        print("   - Check Consent Details URL: \(checkConsentDetailsConfig?.url ?? "nil")")
        print("   - SCA URL: \(scaConfig?.url ?? "nil")")
        print("   - Auth URL: \(authConfig?.url ?? "nil")")
        print("   - Validate Consent URL: \(validateConsentConfig?.url ?? "nil")")
        print("   - Generate Token URL: \(generateTokenConfig?.url ?? "nil")")
        
        loadStepConfiguration(step: .consentCreation)
    }
    
    private func loadStepConfiguration(step: APIStep) {
        currentEditingStep = step
        
        let config: APIConfiguration?
        switch step {
        case .consentCreation:
            config = consentConfig
            consentResponse = config?.response ?? ""
        case .checkConsentDetails:
            config = checkConsentDetailsConfig
            checkConsentDetailsResponse = config?.response ?? ""
        case .scaLinkGeneration:
            config = scaConfig
            scaResponse = config?.response ?? ""
        case .consentAuthorization:
            config = authConfig
            authorizationURL = config?.response ?? ""
        case .validateConsent:
            config = validateConsentConfig
            validateConsentResponse = config?.response ?? ""
        case .generateAccessToken:
            config = generateTokenConfig
            generateTokenResponse = config?.response ?? ""
        }
        
        guard let config = config else { return }
        requestMethod = config.method
        requestURL = config.url
        headers = config.headers
        queryParameters = config.queryParameters
        requestBody = config.body
    }
    
    // MARK: - Configuration Saving
    
    private func saveAPIConfiguration() {
        guard let user = user, let profile = profile else { return }
        
        let config = APIConfiguration(
            userId: user.id,
            profileId: profile.id,
            bankId: bank.id,
            environment: environment.rawValue,
            step: currentEditingStep,
            method: requestMethod,
            url: requestURL,
            headers: headers,
            queryParameters: queryParameters,
            body: requestBody,
            response: ""
        )
        configManager.saveConfiguration(config)
        
        // Update the current step config
        switch currentEditingStep {
        case .consentCreation:
            consentConfig = config
        case .checkConsentDetails:
            checkConsentDetailsConfig = config
        case .scaLinkGeneration:
            scaConfig = config
        case .consentAuthorization:
            authConfig = config
        case .validateConsent:
            validateConsentConfig = config
        case .generateAccessToken:
            generateTokenConfig = config
        }
    }
    
    private func saveStepResponse(step: APIStep, response: String) {
        guard let user = user, let profile = profile else { return }
        
        var config: APIConfiguration
        switch step {
        case .consentCreation:
            config = consentConfig ?? APIConfiguration(
                userId: user.id,
                profileId: profile.id,
                bankId: bank.id,
                environment: environment.rawValue,
                step: step,
                method: "POST",
                url: requestURL,
                headers: headers,
                queryParameters: queryParameters,
                body: requestBody,
                response: response
            )
            config.response = response
            consentConfig = config
            consentResponse = response
        case .checkConsentDetails:
            config = checkConsentDetailsConfig ?? APIConfiguration(
                userId: user.id,
                profileId: profile.id,
                bankId: bank.id,
                environment: environment.rawValue,
                step: step,
                method: "GET",
                url: requestURL,
                headers: headers,
                queryParameters: queryParameters,
                body: requestBody,
                response: response
            )
            config.response = response
            checkConsentDetailsConfig = config
            checkConsentDetailsResponse = response
        case .scaLinkGeneration:
            config = scaConfig ?? APIConfiguration(
                userId: user.id,
                profileId: profile.id,
                bankId: bank.id,
                environment: environment.rawValue,
                step: step,
                method: "POST",
                url: requestURL,
                headers: headers,
                queryParameters: queryParameters,
                body: requestBody,
                response: response
            )
            config.response = response
            scaConfig = config
            scaResponse = response
        case .consentAuthorization:
            config = authConfig ?? APIConfiguration(
                userId: user.id,
                profileId: profile.id,
                bankId: bank.id,
                environment: environment.rawValue,
                step: step,
                method: "GET",
                url: "",
                headers: [:],
                queryParameters: [:],
                body: "",
                response: response
            )
            config.response = response
            authConfig = config
            authorizationURL = response
        case .validateConsent:
            config = validateConsentConfig ?? APIConfiguration(
                userId: user.id,
                profileId: profile.id,
                bankId: bank.id,
                environment: environment.rawValue,
                step: step,
                method: "GET",
                url: "",
                headers: [:],
                queryParameters: [:],
                body: "",
                response: response
            )
            config.response = response
            validateConsentConfig = config
            validateConsentResponse = response
        case .generateAccessToken:
            config = generateTokenConfig ?? APIConfiguration(
                userId: user.id,
                profileId: profile.id,
                bankId: bank.id,
                environment: environment.rawValue,
                step: step,
                method: "POST",
                url: "",
                headers: [:],
                queryParameters: [:],
                body: "",
                response: response
            )
            config.response = response
            generateTokenConfig = config
            generateTokenResponse = response
        }
        
        configManager.saveConfiguration(config)
    }
    
    // MARK: - API Methods
    
    private func createConsent() {
        isLoading = true
        errorMessage = nil
        isConsentFailed = false
        
        // Load consent creation configuration
        if let config = consentConfig {
            requestMethod = config.method
            requestURL = config.url
            headers = config.headers
            queryParameters = config.queryParameters
            requestBody = config.body
            certificatePath = getCertificatePath()
            certificatePassword = getCertificatePassword()
        }
        
        // Execute the request with mTLS certificate via URLSession
        executeRequestWithMTLS { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let (statusCode, response, headers)):
                    saveStepResponse(step: .consentCreation, response: response)
                    
                    // Extract consentId from response
                    if let extractedConsentId = extractConsentId(from: response) {
                        consentId = extractedConsentId
                    }
                    
                    if [200, 201, 302].contains(statusCode) {
                        isConsentCreated = true
                        isConsentFailed = false
                    } else {
                        isConsentCreated = false
                        isConsentFailed = true
                        errorMessage = "Request failed with status code: \(statusCode)"
                    }
                case .failure(let error):
                    isConsentCreated = false
                    isConsentFailed = true
                    errorMessage = error.localizedDescription
                    saveStepResponse(step: .consentCreation, response: "Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func checkConsentDetails() {
        isLoading = true
        errorMessage = nil
        isConsentDetailsCheckFailed = false
        
        // Load check consent details configuration
        if let config = checkConsentDetailsConfig {
            requestMethod = config.method
            requestURL = config.url
            headers = config.headers
            queryParameters = config.queryParameters
            requestBody = config.body
            certificatePath = getCertificatePath()
            certificatePassword = getCertificatePassword()
            
            // Replace {consentId} placeholder with actual consentId
            if !consentId.isEmpty {
                requestURL = requestURL.replacingOccurrences(of: "{consentId}", with: consentId)
                print("✅ Replaced consentId in URL: \(requestURL)")
            }
        }
        
        // Execute the request with mTLS certificate
        executeRequestWithMTLS { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let (statusCode, response, _)):
                    saveStepResponse(step: .checkConsentDetails, response: response)
                    
                    if [200, 201, 302].contains(statusCode) {
                        isConsentDetailsChecked = true
                        isConsentDetailsCheckFailed = false
                    } else {
                        isConsentDetailsChecked = false
                        isConsentDetailsCheckFailed = true
                        errorMessage = "Consent details check failed with status code: \(statusCode)"
                    }
                case .failure(let error):
                    isConsentDetailsChecked = false
                    isConsentDetailsCheckFailed = true
                    errorMessage = error.localizedDescription
                    saveStepResponse(step: .checkConsentDetails, response: "Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func generateSCALink() {
        isLoading = true
        errorMessage = nil
        isSCAFailed = false
        
        // Load SCA link generation configuration
        if let config = scaConfig {
            requestMethod = config.method
            requestURL = config.url
            headers = config.headers
            queryParameters = config.queryParameters
            requestBody = config.body
            certificatePath = getCertificatePath()
            certificatePassword = getCertificatePassword()
            
            // Inject consentId into SCA URL if available
            if !consentId.isEmpty {
                if requestURL.contains("?") {
                    requestURL = requestURL + "&consentId=\(consentId)"
                } else {
                    requestURL = requestURL + "?consentId=\(consentId)"
                }
                print("✅ Injected consentId into SCA Link URL: \(requestURL)")
            }
        }
        
        // Execute the request with mTLS certificate via URLSession
        executeRequestWithMTLS { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let (statusCode, response, headers)):
                    saveStepResponse(step: .scaLinkGeneration, response: response)
                    
                    // Extract Location header from response headers
                    if let locationURL = headers["Location"] as? String {
                        scaLink = locationURL
                        print("✅ SCA Link extracted from Location header: \(locationURL)")
                    } else {
                        print("⚠️ No Location header found in response headers")
                    }
                    
                    if [200, 201, 302].contains(statusCode) {
                        isSCAGenerated = true
                        isSCAFailed = false
                    } else {
                        isSCAGenerated = false
                        isSCAFailed = true
                        errorMessage = "Request failed with status code: \(statusCode)"
                    }
                case .failure(let error):
                    isSCAGenerated = false
                    isSCAFailed = true
                    errorMessage = error.localizedDescription
                    saveStepResponse(step: .scaLinkGeneration, response: "Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func resetConnection() {
        consentResponse = ""
        scaResponse = ""
        validateConsentResponse = ""
        generateTokenResponse = ""
        scaLink = ""
        consentId = ""
        authorizationURL = ""
        isConsentCreated = false
        isSCAGenerated = false
        isAuthorized = false
        isConsentValidated = false
        isAccessTokenGenerated = false
        isConsentFailed = false
        isSCAFailed = false
        isConsentValidationFailed = false
        isAccessTokenFailed = false
        isLoading = false
        errorMessage = nil
    }
    
    private func validateConsent() {
        isLoading = true
        errorMessage = nil
        isConsentValidationFailed = false
        isConsentStatusValid = false
        
        // Load validate consent configuration
        if let config = validateConsentConfig {
            requestMethod = config.method
            requestURL = config.url
            headers = config.headers
            queryParameters = config.queryParameters
            requestBody = config.body
            certificatePath = getCertificatePath()
            certificatePassword = getCertificatePassword()
            
            // Replace {consentId} placeholder with actual consentId
            if !consentId.isEmpty {
                requestURL = requestURL.replacingOccurrences(of: "{consentId}", with: consentId)
                print("✅ Replaced consentId in URL: \(requestURL)")
            }
        }
        
        // Execute the request with mTLS certificate
        executeRequestWithMTLS { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let (statusCode, response, _)):
                    saveStepResponse(step: .validateConsent, response: response)
                    
                    if [200, 201, 302].contains(statusCode) {
                        isConsentValidated = true
                        isConsentValidationFailed = false
                        
                        // Parse response to check if consentStatus is "valid"
                        // Response may include headers, so extract the JSON body
                        var jsonBody = response
                        
                        // If response contains headers (double newline), extract the body
                        if let bodyRange = response.range(of: "\n\n") {
                            jsonBody = String(response[bodyRange.upperBound...])
                        } else if let bodyRange = response.range(of: "\n{\n") {
                            // Handle case where body starts with newline
                            jsonBody = String(response[bodyRange.lowerBound...]).trimmingCharacters(in: .newlines)
                        }
                        
                        if let responseData = jsonBody.data(using: .utf8),
                           let jsonObject = try? JSONSerialization.jsonObject(with: responseData),
                           let json = jsonObject as? [String: Any],
                           let consentStatus = json["consentStatus"] as? String {
                            isConsentStatusValid = (consentStatus == "valid")
                            print("📊 Consent Status: \(consentStatus) - Valid: \(isConsentStatusValid)")
                            
                            if !isConsentStatusValid {
                                errorMessage = "Consent status is not valid: \(consentStatus)"
                            }
                        } else {
                            isConsentStatusValid = false
                            errorMessage = "Could not parse consent status from response"
                            print("❌ Failed to parse response. Body: \(jsonBody)")
                        }
                    } else {
                        isConsentValidated = false
                        isConsentValidationFailed = true
                        errorMessage = "Consent validation failed with status code: \(statusCode)"
                    }
                case .failure(let error):
                    isConsentValidated = false
                    isConsentValidationFailed = true
                    errorMessage = error.localizedDescription
                    saveStepResponse(step: .validateConsent, response: "Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func attemptDeepLinkThenWebView(urlString: String) {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL string: \(urlString)")
            return
        }
        
        print("🔗 Opening SCA redirect URL: \(urlString)")
        isSCARedirectLaunched = true
        
        // Open the URL directly - will open in other app or Safari
        UIApplication.shared.open(url, options: [:]) { success in
            if success {
                print("✅ Successfully opened URL: \(urlString)")
                // The other app will handle the auth and redirect back via universal link
            } else {
                print("❌ Failed to open URL: \(urlString)")
            }
        }
    }
    
    private func generateAccessToken() {
        isLoading = true
        errorMessage = nil
        isAccessTokenFailed = false
        
        print("🔐 [generateAccessToken] Starting access token generation")
        print("   - Current authorizationCode: \(authorizationCode.isEmpty ? "❌ EMPTY" : "✅ \(authorizationCode)")")
        
        // Load generate access token configuration
        if let config = generateTokenConfig {
            requestMethod = config.method
            requestURL = config.url
            headers = config.headers
            queryParameters = config.queryParameters
            requestBody = config.body
            certificatePath = getCertificatePath()
            certificatePassword = getCertificatePassword()
            
            print("   - Request URL: \(requestURL)")
            print("   - Original body: \(requestBody)")
            
            // Replace {authorizationCode} placeholder with actual code from deep link
            if !authorizationCode.isEmpty {
                requestBody = requestBody.replacingOccurrences(of: "{authorizationCode}", with: authorizationCode)
                print("✅ Replaced authorization code in request body")
                print("   - New body: \(requestBody)")
            } else {
                // Try to get from UserDefaults if not in state
                if let savedCode = UserDefaults.standard.string(forKey: "PSD2_AuthorizationCode") {
                    authorizationCode = savedCode
                    requestBody = requestBody.replacingOccurrences(of: "{authorizationCode}", with: savedCode)
                    print("✅ Retrieved and replaced authorization code from UserDefaults: \(savedCode)")
                    print("   - New body: \(requestBody)")
                } else {
                    print("⚠️ No authorization code available - neither in state nor in UserDefaults")
                    errorMessage = "No authorization code available. Please complete the SCA redirect first."
                    isAccessTokenFailed = true
                    isLoading = false
                    return
                }
            }
        }
        
        // Execute the request with mTLS certificate
        executeRequestWithMTLS { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let (statusCode, response, _)):
                    saveStepResponse(step: .generateAccessToken, response: response)
                    
                    if [200, 201, 302].contains(statusCode) {
                        isAccessTokenGenerated = true
                        isAccessTokenFailed = false
                        print("✅ Access token generated successfully")
                    } else {
                        isAccessTokenGenerated = false
                        isAccessTokenFailed = true
                        errorMessage = "Access token generation failed with status code: \(statusCode)"
                        print("❌ Access token generation failed: \(statusCode)")
                    }
                case .failure(let error):
                    isAccessTokenGenerated = false
                    isAccessTokenFailed = true
                    errorMessage = error.localizedDescription
                    print("❌ Access token generation error: \(error.localizedDescription)")
                    saveStepResponse(step: .generateAccessToken, response: "Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Helper functions to get certificate info
    private func getCertificatePath() -> String {
        // Return the certificate path from configuration or construct it
        let bankFolderName = bank.name.replacingOccurrences(of: " ", with: "_")
        
        // Extract environment type from rawValue (e.g., "SB Test" -> "Test", "RD Test" -> "Test")
        let environmentParts = environment.rawValue.components(separatedBy: " ")
        let envPrefix = environmentParts.first ?? "SB" // SB or RD
        let envType = environmentParts.last ?? "Test" // Test, Prelive, Production
        
        // Expected certificate filename: SB_Test_Raiffeisen_Bank.p12
        let expectedCertName = "\(envPrefix)_\(envType)_\(bankFolderName).p12"
        
        print("🔍 Looking for certificate: \(expectedCertName)")
        
        // Approach 1: Look for certificate at bundle root (most common after build)
        if let bundlePath = Bundle.main.path(forResource: expectedCertName.replacingOccurrences(of: ".p12", with: ""), ofType: "p12") {
            print("✅ Certificate found at bundle root: \(bundlePath)")
            return bundlePath
        }
        
        // Approach 2: Try in PSD2_Certificates subdirectory
        if let bundlePath = Bundle.main.url(forResource: expectedCertName.replacingOccurrences(of: ".p12", with: ""), 
                                            withExtension: "p12",
                                            subdirectory: "PSD2_Certificates/\(bankFolderName)")?.path {
            print("✅ Certificate found in subdirectory: \(bundlePath)")
            return bundlePath
        }
        
        // Approach 3: Build full path manually from bundle root
        if let resourcePath = Bundle.main.resourcePath {
            let fullPath = "\(resourcePath)/\(expectedCertName)"
            if FileManager.default.fileExists(atPath: fullPath) {
                print("✅ Certificate found via full path: \(fullPath)")
                return fullPath
            }
        }
        
        print("❌ Certificate not found in bundle")
        
        // Fall back to Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PSD2_Certificates")
            .appendingPathComponent(bankFolderName)
            .appendingPathComponent(expectedCertName)
            .path
        
        print("📍 Fallback path in Documents: \(documentsPath)")
        return certificatePath.isEmpty ? documentsPath : certificatePath
    }
    
    private func getCertificatePassword() -> String {
        return certificatePassword
    }
    
    // Extract Location header from HTTP response
    private func extractLocationHeader(from response: String) -> String? {
        print("🔍 Extracting SCA link from response...")
        print("📄 Response length: \(response.count) characters")
        
        let lines = response.components(separatedBy: "\n")
        
        // First, try to find Location header
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.lowercased().hasPrefix("location:") {
                let locationValue = trimmed.replacingOccurrences(of: "Location:", with: "", options: .caseInsensitive)
                    .trimmingCharacters(in: .whitespaces)
                if !locationValue.isEmpty {
                    print("✅ Found Location header: \(locationValue)")
                    return locationValue
                }
            }
        }
        
        // If no Location header, try to find URL in JSON response body
        if let bodyStart = response.firstIndex(where: { $0.isNewline }),
           let afterFirstNewline = response.index(bodyStart, offsetBy: 1, limitedBy: response.endIndex) {
            let bodyPart = String(response[afterFirstNewline...])
            
            // Look for common SCA URL patterns
            let urlPatterns = [
                "scaRedirect",
                "sca_redirect",
                "authorisationUrl",
                "authorization_url",
                "authUrl",
                "auth_url",
                "redirectUrl",
                "redirect_url",
                "href"
            ]
            
            if let jsonData = bodyPart.data(using: .utf8),
               let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                for pattern in urlPatterns {
                    if let url = jsonObject[pattern] as? String, !url.isEmpty && url.contains("http") {
                        print("✅ Found SCA URL in JSON [\(pattern)]: \(url)")
                        return url
                    }
                }
            }
        }
        
        print("❌ No SCA link found in response")
        print("📝 Response preview: \(response.prefix(500))")
        return nil
    }
    
    // MARK: - URLSession Execution with mTLS
    
    // Extract consentId from Consent Creation response
    private func extractConsentId(from response: String) -> String? {
        print("🔍 Extracting consentId from response...")
        
        // Try to extract JSON from the response
        // The response may contain HTTP headers, so we need to find the JSON part
        var jsonString = response
        
        // Look for the start of JSON (either { or [)
        if let jsonStart = response.firstIndex(where: { $0 == "{" || $0 == "[" }) {
            jsonString = String(response[jsonStart...])
        }
        
        print("🔍 Attempting to parse JSON: \(jsonString.prefix(100))...")
        
        if let jsonData = jsonString.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let extractedConsentId = jsonObject["consentId"] as? String {
            print("✅ Found consentId: \(extractedConsentId)")
            return extractedConsentId
        } else {
            print("❌ Failed to parse JSON or extract consentId from response")
        }
        
        print("❌ No consentId found in response")
        return nil
    }
    
    private func executeRequestWithMTLS(completion: @escaping (Result<(statusCode: Int, response: String, headers: [AnyHashable: Any]), Error>) -> Void) {
        // Build URL with query parameters
        var fullURL = requestURL
        if !queryParameters.isEmpty {
            let queryString = queryParameters
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
            
            // Check if URL already has query parameters
            if fullURL.contains("?") {
                fullURL += "&\(queryString)"
            } else {
                fullURL += "?\(queryString)"
            }
        }
        
        print("🌐 Request URL: \(fullURL)")
        print("🔐 Certificate Path: \(certificatePath)")
        print("🔐 Certificate Exists: \(FileManager.default.fileExists(atPath: certificatePath))")
        
        guard let url = URL(string: fullURL) else {
            completion(.failure(NSError(domain: "RequestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(fullURL)"])))
            return
        }
        
        // Validate certificate exists if path is provided
        if !certificatePath.isEmpty {
            let fileExists = FileManager.default.fileExists(atPath: certificatePath)
            if !fileExists {
                print("❌ Certificate file NOT FOUND at: \(certificatePath)")
                // List available certificates for debugging
                let bankFolderName = bank.name.replacingOccurrences(of: " ", with: "_")
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("PSD2_Certificates")
                    .appendingPathComponent(bankFolderName)
                    .path
                
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: documentsPath)
                    print("📂 Available files at \(documentsPath): \(contents)")
                } catch {
                    print("❌ Cannot list directory: \(error)")
                }
                
                completion(.failure(NSError(domain: "CertificateError", code: -1, 
                    userInfo: [NSLocalizedDescriptionKey: "Certificate file not found at path: \(certificatePath)"])))
                return
            }
            print("✅ Certificate file found at: \(certificatePath)")
        } else {
            print("⚠️ Certificate path is empty - request will proceed without mTLS")
        }
        
        var request = URLRequest(url: url, timeoutInterval: 60)
        request.httpMethod = requestMethod.uppercased()
        
        // Set headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Set body for methods that allow it
        if !requestBody.isEmpty,
           ["POST", "PUT", "PATCH"].contains(requestMethod.uppercased()) {
            request.httpBody = requestBody.data(using: .utf8)
        }
        
        // Build session with delegate for client certificate if provided
        let delegate = MTLSURLSessionDelegate(p12Path: certificatePath, password: certificatePassword)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = true
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        
        let task = session.dataTask(with: request) { data, response, error in
            // Combine headers + body similar to curl -i
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let httpResponse = response as? HTTPURLResponse
            var headerLines = ""
            if let httpResponse = httpResponse {
                headerLines += "HTTP/1.1 \(httpResponse.statusCode)\n"
                for (key, value) in httpResponse.allHeaderFields {
                    headerLines += "\(key): \(value)\n"
                }
                headerLines += "\n"
            }
            
            let bodyString: String
            if let data = data, !data.isEmpty {
                bodyString = String(data: data, encoding: .utf8) ?? data.base64EncodedString()
            } else {
                bodyString = ""
            }
            
            let statusCode = httpResponse?.statusCode ?? 0
            let fullResponse = headerLines + bodyString
            
            // Extract Location header if present (for SCA links)
            if let locationHeader = httpResponse?.value(forHTTPHeaderField: "Location") {
                print("📍 Location header found: \(locationHeader)")
            }
            
            completion(.success((statusCode: statusCode, response: fullResponse, headers: httpResponse?.allHeaderFields ?? [:])))
            
            // Invalidate session to reset TLS connection after each call
            session.finishTasksAndInvalidate()
        }
        task.resume()
    }
}

// MARK: - Connection Step Card

struct ConnectionStepCard: View {
    let stepNumber: Int
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isCompleted: Bool
    let isFailed: Bool
    let isActive: Bool
    let action: () -> Void
    let onEditAPI: (() -> Void)?
    var buttonLabel: String = "Start"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Step indicator
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : (isFailed ? Color.red : (isActive ? color : Color.gray.opacity(0.3))))
                        .frame(width: 32, height: 32)
                    
                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else if isFailed {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(stepNumber)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isActive ? .white : .gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isActive ? .primary : .secondary)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isCompleted ? .green : (isFailed ? .red : (isActive ? color : .gray.opacity(0.3))))
            }
            
            // Action button
            if (isActive || isFailed) && !isCompleted {
                HStack(spacing: 10) {
                    if let onEditAPI = onEditAPI {
                        Button(action: onEditAPI) {
                            Label("Edit API", systemImage: "terminal")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isFailed ? .red : color)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isFailed ? .red : color, lineWidth: 1.5)
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                                )
                        }
                    }
                    
                    Button(action: action) {
                        Text(isFailed ? "Retry" : buttonLabel)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isFailed ? Color.red : color)
                            )
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .opacity(isActive || isCompleted ? 1 : 0.6)
    }
}

// MARK: - Response Card
struct ResponseCard: View {
    let title: String
    let response: String
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    UIPasteboard.general.string = response
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copied = false
                    }
                }) {
                    Label(copied ? "Copied" : "Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(copied ? .green : .blue)
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if let formatted = formatResponse(response) {
                        // Display formatted sections
                        if !formatted.statusLine.isEmpty {
                            Text(formatted.statusLine)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(formatted.isSuccess ? .green : .red)
                        }
                        
                        if !formatted.headers.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(formatted.headers.enumerated()), id: \.offset) { _, header in
                                    HStack(alignment: .top, spacing: 4) {
                                        Text(header.key + ":")
                                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                            .foregroundColor(.blue)
                                        Text(header.value)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.bottom, 4)
                        }
                        
                        if !formatted.body.isEmpty {
                            Divider()
                            if let jsonData = formatted.body.data(using: .utf8),
                               let jsonObject = try? JSONSerialization.jsonObject(with: jsonData),
                               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
                               let prettyString = String(data: prettyData, encoding: .utf8) {
                                Text(prettyString)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .textSelection(.enabled)
                            } else {
                                Text(formatted.body)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .textSelection(.enabled)
                            }
                        }
                    } else {
                        // Fallback to plain text
                        Text(response)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 200)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private func formatResponse(_ response: String) -> (statusLine: String, headers: [(key: String, value: String)], body: String, isSuccess: Bool)? {
        let lines = response.components(separatedBy: "\n")
        guard !lines.isEmpty else { return nil }
        
        var statusLine = ""
        var headers: [(key: String, value: String)] = []
        var bodyStartIndex = 0
        var isSuccess = false
        
        // Parse status line
        if let firstLine = lines.first, firstLine.hasPrefix("HTTP/") {
            statusLine = firstLine
            // Check if status code is 2xx or 3xx
            if let statusCode = Int(firstLine.components(separatedBy: " ").dropFirst().first ?? "") {
                isSuccess = (200...399).contains(statusCode)
            }
            bodyStartIndex = 1
        }
        
        // Parse headers (until empty line)
        for i in bodyStartIndex..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                bodyStartIndex = i + 1
                break
            }
            if let colonIndex = line.firstIndex(of: ":") {
                let key = String(line[..<colonIndex])
                let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                headers.append((key: key, value: value))
            }
        }
        
        // Everything after empty line is body
        let body = lines[bodyStartIndex..<lines.count].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (statusLine: statusLine, headers: headers, body: body, isSuccess: isSuccess)
    }
}

#Preview {
    NavigationView {
        BankDetailView(
            bank: Bank(
                name: "Raiffeisen Bank",
                logoName: "raiffeisen_logo",
                logoColor: "yellow",
                bic: "RZBBROBU"
            ),
            environment: .sandboxTest
        )
    }
}

// MARK: - URLSessionDelegate for mTLS
private final class MTLSURLSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    private let p12Path: String
    private let password: String
    private var certificateError: String?
    
    init(p12Path: String, password: String) {
        self.p12Path = p12Path
        self.password = password
        super.init()
    }
    
    private lazy var identityAndCerts: (SecIdentity, [SecCertificate])? = {
        guard !p12Path.isEmpty else { 
            certificateError = "Certificate path is empty"
            return nil 
        }
        
        let url = URL(fileURLWithPath: p12Path)
        guard let p12Data = try? Data(contentsOf: url) else { 
            certificateError = "Failed to read certificate file at: \(p12Path)"
            print("❌ Certificate Error: Failed to read P12 file")
            return nil 
        }
        
        let options: NSDictionary = [kSecImportExportPassphrase as NSString: password]
        var items: CFArray?
        let status = SecPKCS12Import(p12Data as NSData, options, &items)
        
        guard status == errSecSuccess else {
            let errorMsg: String
            switch status {
            case errSecAuthFailed:
                errorMsg = "Invalid certificate password"
            case errSecDecode:
                errorMsg = "Invalid certificate format"
            case errSecUnknownFormat:
                errorMsg = "Unknown certificate format"
            default:
                errorMsg = "Certificate import failed with status: \(status)"
            }
            certificateError = errorMsg
            print("❌ Certificate Error: \(errorMsg)")
            return nil
        }
        
        guard let array = items as? [[String: Any]],
              let first = array.first,
              let identity = first[kSecImportItemIdentity as String] as! SecIdentity?
        else {
            certificateError = "Failed to extract identity from certificate"
            print("❌ Certificate Error: Failed to extract identity")
            return nil
        }
        
        var certs: [SecCertificate] = []
        if let certArray = first[kSecImportItemCertChain as String] as? [SecCertificate] {
            certs = certArray
        } else {
            var certificate: SecCertificate?
            if SecIdentityCopyCertificate(identity, &certificate) == errSecSuccess, let certificate {
                certs = [certificate]
            }
        }
        
        print("✅ Certificate loaded successfully with \(certs.count) certificate(s)")
        return (identity, certs)
    }()
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("🔐 Authentication challenge: \(challenge.protectionSpace.authenticationMethod)")
        
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodClientCertificate:
            print("🔐 Client certificate requested")
            if let (identity, certs) = identityAndCerts {
                print("✅ Providing client certificate with \(certs.count) cert(s)")
                let credential = URLCredential(identity: identity, certificates: certs, persistence: .forSession)
                completionHandler(.useCredential, credential)
            } else {
                print("❌ No client certificate available. Error: \(certificateError ?? "Unknown")")
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        case NSURLAuthenticationMethodServerTrust:
            print("🔐 Server trust challenge")
            if let serverTrust = challenge.protectionSpace.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        default:
            print("🔐 Default authentication handling")
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    // Intercept redirects to prevent automatic following of redirect URLs with untrusted certificates
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        print("🔀 Redirect intercepted: \(response.statusCode) -> \(newRequest.url?.absoluteString ?? "unknown")")
        // Return nil to prevent automatic redirect
        completionHandler(nil)
    }
}

// MARK: - WebView Component
// MARK: - Safari View Component
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        
        let safari = SFSafariViewController(url: url, configuration: config)
        safari.delegate = context.coordinator
        safari.dismissButtonStyle = .done
        
        print("🌐 Safari View loading: \(url.absoluteString)")
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No update needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let onDismiss: () -> Void
        
        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            print("✅ Safari View dismissed by user")
            onDismiss()
        }
    }
}