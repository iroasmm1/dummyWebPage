//
//  BankConnectionsView.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import SwiftUI

struct BankConnectionsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var banks = Bank.romanianBanks
    @State private var searchText = ""
    @State private var selectedBank: Bank?
    @State private var selectedEnvironment: PSD2Environment = .sandboxTest
    @State private var showBankDetail = false
    
    var filteredBanks: [Bank] {
        if searchText.isEmpty {
            return banks
        }
        return banks.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header stats
            VStack(spacing: 15) {
                Text("Connected Banks")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("\(banks.filter { $0.isConnected }.count)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.blue)
                
                Text("out of \(banks.count) available Romanian banks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(Color(.systemGroupedBackground))
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search banks...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .padding()
            
            // Banks list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredBanks) { bank in
                        Button(action: {
                            selectedBank = bank
                            // Capture the current environment when bank is selected
                            if let activeEnv = authViewModel.profileManager.activeProfile?.activeEnvironment {
                                selectedEnvironment = activeEnv
                            }
                            showBankDetail = true
                        }) {
                            BankRow(bank: bank)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Bank Connections")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            // Initialize environment from active profile when view appears
            if let activeEnv = authViewModel.profileManager.activeProfile?.activeEnvironment {
                selectedEnvironment = activeEnv
            }
        }
        .sheet(isPresented: $showBankDetail, onDismiss: {
            print("🔄 [BankConnectionsView] BankDetailView sheet dismissed")
            selectedBank = nil
        }) {
            if let bank = selectedBank {
                NavigationView {
                    BankDetailView(
                        bank: bank,
                        environment: selectedEnvironment,
                        user: authViewModel.currentUser,
                        profile: authViewModel.profileManager.activeProfile
                    )
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}

// Bank Row Component
struct BankRow: View {
    let bank: Bank
    
    var body: some View {
        HStack(spacing: 15) {
                // Bank logo
                ZStack {
                    Circle()
                        .fill(colorFromString(bank.isConnected ? "green" : bank.logoColor).opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    // Try to load image, fallback to text initial
                    if let uiImage = UIImage(named: bank.logoName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Text(String(bank.name.prefix(1)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colorFromString(bank.isConnected ? "green" : bank.logoColor))
                    }
                }
                .overlay(
                    Circle()
                        .stroke(bank.isConnected ? Color.green : Color.clear, lineWidth: 2)
                )
                
                // Bank info
                VStack(alignment: .leading, spacing: 4) {
                    Text(bank.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("BIC: \(bank.bic)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Connection status
                if bank.isConnected {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Connected")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "indigo": return .indigo
        case "teal": return .teal
        default: return .blue
        }
    }
}

// Bank Connection Sheet
struct BankConnectionSheet: View {
    let bank: Bank
    let onConnect: (Bank) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var username = ""
    @State private var password = ""
    @State private var isConnecting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // Bank header
                VStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(colorFromString(bank.logoColor).opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        // Try to load image, fallback to text initial
                        if let uiImage = UIImage(named: bank.logoName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                        } else {
                            Text(String(bank.name.prefix(1)))
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(colorFromString(bank.logoColor))
                        }
                    }
                    
                    Text(bank.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("PSD2 Compliant")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.top, 30)
                
                // Connection form
                VStack(spacing: 16) {
                    Text("Enter your online banking credentials")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            TextField("Username", text: $username)
                                .textContentType(.username)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Security notice
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Secure Connection")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("Your credentials are encrypted and never stored on our servers")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Connect button
                Button(action: {
                    connectBank()
                }) {
                    if isConnecting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(bank.isConnected ? "Disconnect" : "Connect Bank")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(bank.isConnected ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(isConnecting || (!bank.isConnected && (username.isEmpty || password.isEmpty)))
                
            }
            .navigationTitle("Connect Bank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func connectBank() {
        isConnecting = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            var updatedBank = bank
            updatedBank.isConnected.toggle()
            onConnect(updatedBank)
            isConnecting = false
        }
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "indigo": return .indigo
        case "teal": return .teal
        default: return .blue
        }
    }
}

#Preview {
    NavigationView {
        BankConnectionsView()
    }
}
