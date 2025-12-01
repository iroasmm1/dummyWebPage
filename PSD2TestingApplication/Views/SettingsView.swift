//
//  SettingsView.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import SwiftUI
internal import LocalAuthentication

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @ObservedObject var biometricManager: BiometricAuthManager
    
    @State private var showLogoutAlert = false
    @State private var showDeleteAccountAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // User Profile Section
                Section(header: Text("Profile")) {
                    if let user = authViewModel.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.fullName)
                                    .font(.headline)
                                Text("@\(user.username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 5)
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.gray)
                            Text(user.email)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Security Section
                Section(header: Text("Security")) {
                    if biometricManager.isBiometricAvailable {
                        Toggle(isOn: Binding(
                            get: { biometricManager.isBiometricEnabled },
                            set: { newValue in
                                if newValue {
                                    Task {
                                        let success = await biometricManager.authenticate(
                                            reason: "Enable \(biometricManager.biometricTypeName) for quick login"
                                        )
                                        if success {
                                            biometricManager.enableBiometric()
                                        }
                                    }
                                } else {
                                    biometricManager.disableBiometric()
                                }
                            }
                        )) {
                            HStack {
                                Image(systemName: biometricManager.biometricType == .faceID ? "faceid" : "touchid")
                                    .foregroundColor(.blue)
                                Text("\(biometricManager.biometricTypeName) Login")
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Biometric authentication not available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        // Change password action
                    }) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.gray)
                            Text("Change Password")
                        }
                    }
                }
                
                // App Information
                Section(header: Text("About")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.gray)
                        Text("PSD2 Compliance")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                // Account Actions
                Section {
                    Button(role: .destructive, action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Logout")
                        }
                    }
                    
                    Button(role: .destructive, action: {
                        showDeleteAccountAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                            Text("Delete Account")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    authViewModel.logout()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    authViewModel.deleteAccount()
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone. All your data, including profiles and connected banks, will be permanently deleted.")
            }
        }
    }
}

#Preview {
    SettingsView(biometricManager: BiometricAuthManager())
        .environmentObject(AuthViewModel())
}
