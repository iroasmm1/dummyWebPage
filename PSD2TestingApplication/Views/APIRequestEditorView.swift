//
//  APIRequestEditorView.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import SwiftUI

struct APIRequestEditorView: View {
    let bank: Bank
    let environment: PSD2Environment
    
    @Environment(\.dismiss) var dismiss
    @Binding var requestMethod: String
    @Binding var requestURL: String
    @Binding var headers: [String: String]
    @Binding var requestBody: String
    @Binding var certificatePath: String
    @Binding var certificatePassword: String
    @Binding var queryParameters: [String: String]
    var onSaveConfiguration: (() -> Void)? = nil
    
    @State private var headersList: [APIHeader] = []
    @State private var queryParamsList: [APIHeader] = []
    @State private var selectedTab: Int = 0
    @State private var hasPasswordProtection: Bool = false
    @State private var showPassword: Bool = false
    
    var certificateName: String {
        let envPrefix = environment.category == "Sandbox" ? "SB" : "RD"
        let envSuffix = environment.subEnvironment
        return "\(envPrefix)_\(envSuffix)_\(bank.name.replacingOccurrences(of: " ", with: "_")).p12"
    }
    
    var certificateExists: Bool {
        let bankFolderName = getBankFolderName()
        
        // Check if certificate exists in bundle root
        if Bundle.main.path(forResource: certificateName.replacingOccurrences(of: ".p12", with: ""), ofType: "p12") != nil {
            return true
        }
        
        // Check in PSD2_Certificates subdirectory
        if Bundle.main.url(forResource: certificateName.replacingOccurrences(of: ".p12", with: ""), 
                           withExtension: "p12",
                           subdirectory: "PSD2_Certificates/\(bankFolderName)") != nil {
            return true
        }
        
        // Check in bundle resource path
        if let resourcePath = Bundle.main.resourcePath {
            let fullPath = "\(resourcePath)/\(certificateName)"
            if FileManager.default.fileExists(atPath: fullPath) {
                return true
            }
        }
        
        return false
    }
    
    func getBankFolderName() -> String {
        if bank.name.contains("BCR") {
            return "BCR"
        } else if bank.name.contains("BRD") {
            return "BRD_Societe_Generale"
        } else if bank.name.contains("Alpha") {
            return "Alpha_Bank"
        } else if bank.name.contains("Banca Romaneasca") {
            return "Banca_Romaneasca"
        } else if bank.name.contains("Banca Transilvania") {
            return "Banca_Transilvania"
        } else if bank.name.contains("CEC") {
            return "CEC_Bank"
        } else if bank.name.contains("Exim") {
            return "Exim_Bank"
        } else if bank.name.contains("First") {
            return "First_Bank"
        } else if bank.name.contains("Garanti") {
            return "Garanti_BBVA"
        } else if bank.name.contains("ING") {
            return "ING_Bank_Romania"
        } else if bank.name.contains("Intesa") {
            return "Intesa_Sanpaolo"
        } else if bank.name.contains("Libra") {
            return "Libra_Bank"
        } else if bank.name.contains("OTP") {
            return "OTP_Bank"
        } else if bank.name.contains("Patria") {
            return "Patria_Bank"
        } else if bank.name.contains("ProCredit") {
            return "ProCredit_Bank"
        } else if bank.name.contains("Raiffeisen") {
            return "Raiffeisen_Bank"
        } else if bank.name.contains("UniCredit") {
            return "UniCredit_Bank"
        } else if bank.name.contains("Vista") {
            return "Vista_Bank"
        } else {
            return bank.name.replacingOccurrences(of: " ", with: "_")
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Edit API Request")
                        .font(.headline.weight(.semibold))
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Tabs
                Picker("Request Section", selection: $selectedTab) {
                    Text("URL & Method").tag(0)
                    Text("Headers").tag(1)
                    Text("Query").tag(2)
                    Text("Body").tag(3)
                    Text("cURL").tag(4)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedTab == 0 {
                            URLMethodSection(
                                method: $requestMethod,
                                url: $requestURL,
                                certificateName: certificateName,
                                certificateExists: certificateExists,
                                bankFolderName: getBankFolderName(),
                                hasPasswordProtection: $hasPasswordProtection,
                                certificatePassword: $certificatePassword,
                                showPassword: $showPassword
                            )
                        } else if selectedTab == 1 {
                            HeadersSection(headers: $headersList)
                        } else if selectedTab == 2 {
                            HeadersSection(headers: $queryParamsList)
                        } else if selectedTab == 3 {
                            BodySection(requestBody: $requestBody)
                        } else {
                            cURLEditSection(
                                method: $requestMethod,
                                url: $requestURL,
                                headers: $headersList,
                                queryParams: $queryParamsList,
                                requestBody: $requestBody
                            )
                        }
                    }
                    .padding()
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.6))
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        saveChanges()
                        dismiss()
                    }) {
                        Text("Save & Execute")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            // Initialize headersList from headers dictionary
            headersList = headers.map { APIHeader(key: $0.key, value: $0.value) }
            queryParamsList = queryParameters.map { APIHeader(key: $0.key, value: $0.value) }
            hasPasswordProtection = !certificatePassword.isEmpty
        }
    }
    
    private func saveChanges() {
        // Convert headersList back to dictionary
        headers = Dictionary(uniqueKeysWithValues: headersList.map { ($0.key, $0.value) })
        
        // Convert queryParamsList back to dictionary
        queryParameters = Dictionary(uniqueKeysWithValues: queryParamsList.map { ($0.key, $0.value) })
        
        // Get certificate path using bundle-aware lookup
        certificatePath = getCertificatePath()
        
        // Save API configuration via closure
        onSaveConfiguration?()
    }
    
    private func getCertificatePath() -> String {
        let bankFolderName = getBankFolderName()
        
        // Extract environment type from rawValue (e.g., "SB Test" -> "Test", "RD Test" -> "Test")
        let environmentParts = environment.rawValue.components(separatedBy: " ")
        let envPrefix = environmentParts.first ?? "SB" // SB or RD
        let envType = environmentParts.last ?? "Test" // Test, Prelive, Production
        
        // Expected certificate filename: SB_Test_Raiffeisen_Bank.p12
        let expectedCertName = "\(envPrefix)_\(envType)_\(bank.name.replacingOccurrences(of: " ", with: "_")).p12"
        
        print("🔍 [Editor] Looking for certificate: \(expectedCertName)")
        
        // Approach 1: Look for certificate at bundle root (most common after build)
        if let bundlePath = Bundle.main.path(forResource: expectedCertName.replacingOccurrences(of: ".p12", with: ""), ofType: "p12") {
            print("✅ [Editor] Certificate found at bundle root: \(bundlePath)")
            return bundlePath
        }
        
        // Approach 2: Try in PSD2_Certificates subdirectory
        if let bundlePath = Bundle.main.url(forResource: expectedCertName.replacingOccurrences(of: ".p12", with: ""), 
                                            withExtension: "p12",
                                            subdirectory: "PSD2_Certificates/\(bankFolderName)")?.path {
            print("✅ [Editor] Certificate found in subdirectory: \(bundlePath)")
            return bundlePath
        }
        
        // Approach 3: Build full path manually from bundle root
        if let resourcePath = Bundle.main.resourcePath {
            let fullPath = "\(resourcePath)/\(expectedCertName)"
            if FileManager.default.fileExists(atPath: fullPath) {
                print("✅ [Editor] Certificate found via full path: \(fullPath)")
                return fullPath
            }
        }
        
        print("❌ [Editor] Certificate not found in bundle")
        
        // Fall back to Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PSD2_Certificates")
            .appendingPathComponent(bankFolderName)
            .appendingPathComponent(expectedCertName)
            .path
        
        print("📍 [Editor] Fallback path in Documents: \(documentsPath)")
        return documentsPath
    }
}

// MARK: - URL & Method Section
struct URLMethodSection: View {
    @Binding var method: String
    @Binding var url: String
    let certificateName: String
    let certificateExists: Bool
    let bankFolderName: String
    @Binding var hasPasswordProtection: Bool
    @Binding var certificatePassword: String
    @Binding var showPassword: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 8) {
                Text("HTTP Method")
                    .font(.caption.weight(.semibold))
                
                Picker("Method", selection: $method) {
                    Text("GET").tag("GET")
                    Text("POST").tag("POST")
                    Text("PUT").tag("PUT")
                    Text("DELETE").tag("DELETE")
                    Text("PATCH").tag("PATCH")
                }
                .pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Request URL")
                    .font(.caption.weight(.semibold))
                
                TextField("Enter URL", text: $url)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                    .lineLimit(3)
            }
            
            // Certificate Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Client Certificate")
                    .font(.caption.weight(.semibold))
                
                if certificateExists {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.doc.fill")
                            .foregroundColor(.blue)
                        
                        Text(certificateName)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Certificate Not Found")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.red)
                                
                                Text("Expected: \(certificateName)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("Path: PSD2_Certificates/\(bankFolderName)/")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Password Protection
                Toggle(isOn: $hasPasswordProtection) {
                    Text("Certificate has password protection")
                        .font(.system(size: 14))
                }
                
                if hasPasswordProtection {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Certificate Password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if showPassword {
                                TextField("Enter password", text: $certificatePassword)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 14))
                            } else {
                                SecureField("Enter password", text: $certificatePassword)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 14))
                            }
                            
                            Button(action: {
                                showPassword.toggle()
                            }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
    }
}

// MARK: - Headers Section
struct HeadersSection: View {
    @Binding var headers: [APIHeader]
    @State private var newHeaderKey: String = ""
    @State private var newHeaderValue: String = ""
    
    var body: some View {
        VStack(spacing: 15) {
            // Existing headers
            ForEach($headers) { $header in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Header Name", text: $header.key)
                            .font(.caption.weight(.semibold))
                        
                        TextField("Header Value", text: $header.value)
                            .font(.system(size: 12, design: .monospaced))
                    }
                    
                    Button(action: {
                        headers.removeAll { $0.id == header.id }
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }
            
            // Add new header
            VStack(spacing: 10) {
                Text("Add Header")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 10) {
                    TextField("Key", text: $newHeaderKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                    
                    TextField("Value", text: $newHeaderValue)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                    
                    Button(action: {
                        if !newHeaderKey.isEmpty && !newHeaderValue.isEmpty {
                            headers.append(APIHeader(key: newHeaderKey, value: newHeaderValue))
                            newHeaderKey = ""
                            newHeaderValue = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
        }
    }
}

// MARK: - Body Section
struct BodySection: View {
    @Binding var requestBody: String
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Request Body (JSON)")
                    .font(.caption.weight(.semibold))
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        requestBody = ""
                    }) {
                        Label("Clear", systemImage: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        UIPasteboard.general.string = requestBody
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            copied = false
                        }
                    }) {
                        Label(copied ? "Copied" : "Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(copied ? .green : .blue)
                    }
                    
                    Button(action: {
                        formatJSON()
                    }) {
                        Label("Format", systemImage: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Text("Edit the JSON body below")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            TextEditor(text: $requestBody)
                .font(.system(size: 12, design: .monospaced))
                .frame(height: 300)
                .padding(8)
                .background(Color.black.opacity(0.05))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private func formatJSON() {
        guard let data = requestBody.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let formattedString = String(data: formatted, encoding: .utf8) else {
            return
        }
        requestBody = formattedString
    }
}

// MARK: - cURL Edit Section
struct cURLEditSection: View {
    @Binding var method: String
    @Binding var url: String
    @Binding var headers: [APIHeader]
    @Binding var queryParams: [APIHeader]
    @Binding var requestBody: String
    
    @State private var curlText: String = ""
    @State private var copied = false
    @State private var showParseSuccess = false
    
    var generatedCurl: String {
        var curl = "curl --request \(method) \\\n"
        
        // Build URL with query parameters
        var fullUrl = url
        if !queryParams.isEmpty {
            let queryString = queryParams
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
            fullUrl += "?\(queryString)"
        }
        curl += "  --url \(fullUrl)"
        
        for header in headers {
            curl += " \\\n  --header '\(header.key): \(header.value)'"
        }
        
        if !requestBody.isEmpty && (method == "POST" || method == "PUT" || method == "PATCH") {
            curl += " \\\n  --data '\(requestBody.replacingOccurrences(of: "'", with: "\\'"))'"
        }
        
        return curl
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("cURL Command")
                    .font(.caption.weight(.semibold))
                
                Spacer()
                
                HStack(spacing: 12) {
                    if showParseSuccess {
                        Label("Parsed", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Button(action: {
                        curlText = ""
                    }) {
                        Label("Clear", systemImage: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        UIPasteboard.general.string = curlText
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            copied = false
                        }
                    }) {
                        Label(copied ? "Copied" : "Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                            .foregroundColor(copied ? .green : .blue)
                    }
                    
                    Button(action: {
                        parseCurl()
                    }) {
                        Label("Apply", systemImage: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Text("Edit the cURL command below and tap 'Apply' to update the request")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            TextEditor(text: $curlText)
                .font(.system(size: 11, design: .monospaced))
                .frame(height: 300)
                .padding(8)
                .background(Color.black.opacity(0.05))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .onAppear {
            curlText = generatedCurl
        }
        .onChange(of: requestBody) { _ in
            curlText = generatedCurl
        }
        .onChange(of: method) { _ in
            curlText = generatedCurl
        }
        .onChange(of: url) { _ in
            curlText = generatedCurl
        }
        .onChange(of: headers) { _ in
            curlText = generatedCurl
        }
    }
    
    private func parseCurl() {
        // Simple cURL parser
        let lines = curlText.components(separatedBy: "\n")
        var newHeaders: [APIHeader] = []
        var newQueryParams: [APIHeader] = []
        var newUrl = ""
        var newMethod = "POST"
        var newBody = ""
        var inDataSection = false
        var dataLines: [String] = []
        
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "").trimmingCharacters(in: .whitespaces)
            
            // Check if we're starting a data section
            if trimmed.contains("--data") || trimmed.contains("-d") {
                inDataSection = true
                var bodyString = trimmed
                    .replacingOccurrences(of: "--data", with: "")
                    .replacingOccurrences(of: "-d", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                // Remove leading quote if present
                if bodyString.hasPrefix("'") || bodyString.hasPrefix("\"") {
                    bodyString.removeFirst()
                }
                
                // Check if this line also has the closing quote (single-line data)
                if bodyString.hasSuffix("'") || bodyString.hasSuffix("\"") {
                    bodyString.removeLast()
                    dataLines.append(bodyString)
                    inDataSection = false
                } else {
                    dataLines.append(bodyString)
                }
                continue
            }
            
            // If we're in data section
            if inDataSection {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                // Check if this line contains the closing quote (must end with }' or }")
                if trimmedLine.hasSuffix("}'") || trimmedLine.hasSuffix("}\"") {
                    // Remove the closing quote from the trimmed version
                    var finalLine = trimmedLine
                    finalLine.removeLast() // Remove the quote
                    dataLines.append(finalLine)
                    inDataSection = false
                } else {
                    // Regular line in data section, keep original formatting
                    dataLines.append(line)
                }
                continue
            }
            
            // Parse method
            if trimmed.contains("--request") || trimmed.contains("-X") {
                let components = trimmed.components(separatedBy: .whitespaces)
                if let methodIndex = components.firstIndex(where: { $0 == "--request" || $0 == "-X" }),
                   methodIndex + 1 < components.count {
                    newMethod = components[methodIndex + 1]
                }
            }
            
            // Parse URL
            if trimmed.contains("--url") {
                let urlString = trimmed.replacingOccurrences(of: "--url", with: "").trimmingCharacters(in: .whitespaces)
                newUrl = urlString
            } else if trimmed.hasPrefix("http") && !trimmed.contains("--") {
                newUrl = trimmed
            }
            
            // Parse headers
            if trimmed.contains("--header") || trimmed.contains("-H") {
                var headerString = trimmed
                    .replacingOccurrences(of: "--header", with: "")
                    .replacingOccurrences(of: "-H", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                // Remove quotes
                headerString = headerString.trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
                
                if let colonIndex = headerString.firstIndex(of: ":") {
                    let key = String(headerString[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                    let value = String(headerString[headerString.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                    newHeaders.append(APIHeader(key: key, value: value))
                }
            }
        }
        
        // Process collected data lines
        if !dataLines.isEmpty {
            var bodyString = dataLines.joined(separator: "\n")
            // Remove trailing quote if present
            if bodyString.hasSuffix("'") || bodyString.hasSuffix("\"") {
                bodyString.removeLast()
            }
            newBody = bodyString
        }
        
        // Extract query parameters from URL
        if !newUrl.isEmpty, let urlComponents = URLComponents(string: newUrl) {
            // Get base URL without query parameters
            var baseUrl = newUrl
            if let queryIndex = newUrl.firstIndex(of: "?") {
                baseUrl = String(newUrl[..<queryIndex])
            }
            
            // Extract query parameters
            if let queryItems = urlComponents.queryItems {
                for item in queryItems {
                    newQueryParams.append(APIHeader(key: item.name, value: item.value ?? ""))
                }
            }
            
            // Update URL to base URL without query params
            newUrl = baseUrl
        }
        
        // Apply parsed values - always overwrite to replace defaults
        method = newMethod
        url = newUrl
        headers = newHeaders
        queryParams = newQueryParams
        requestBody = newBody
        
        // Show success indicator
        showParseSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showParseSuccess = false
        }
    }
}

// MARK: - API Header Model
struct APIHeader: Identifiable, Equatable {
    let id: UUID = UUID()
    var key: String
    var value: String
    
    static func == (lhs: APIHeader, rhs: APIHeader) -> Bool {
        lhs.key == rhs.key && lhs.value == rhs.value
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var requestMethod = "POST"
        @State private var requestURL = "https://api.example.com/v1/consents"
        @State private var headers: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json"
        ]
        @State private var requestBody = """
{
  "access": {
    "accounts": []
  }
}
"""
        @State private var certificatePath = ""
        @State private var certificatePassword = ""
        @State private var queryParameters: [String: String] = [:]
        
        var body: some View {
            APIRequestEditorView(
                bank: Bank(
                    name: "Raiffeisen Bank",
                    logoName: "raiffeisen_logo",
                    logoColor: "yellow",
                    bic: "RZBBROBU"
                ),
                environment: .sandboxTest,
                requestMethod: $requestMethod,
                requestURL: $requestURL,
                headers: $headers,
                requestBody: $requestBody,
                certificatePath: $certificatePath,
                certificatePassword: $certificatePassword,
                queryParameters: $queryParameters
            )
        }
    }
    
    return PreviewWrapper()
}
