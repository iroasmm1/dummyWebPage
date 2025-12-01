//
//  LoginView.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import SwiftUI
internal import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var showRegistration = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Logo and title
                    VStack(spacing: 10) {
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                        
                        Text("PSD2 Banking")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Payment Services Directive 2")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 40)
                    
                    // Login form
                    VStack(spacing: 16) {
                        // Username field
                        HStack {
                            Image(systemName: "at")
                                .foregroundColor(.gray)
                            TextField("Username", text: $username)
                                .textContentType(.username)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        // Password field
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        // Error message
                        if let errorMessage = authViewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                        
                        // Login button
                        Button(action: {
                            Task {
                                await authViewModel.login(username: username, password: password)
                            }
                        }) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Login")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .disabled(authViewModel.isLoading)
                        
                        // Biometric login button
                        if authViewModel.biometricManager.isBiometricAvailable {
                            Button(action: {
                                Task {
                                    await authViewModel.loginWithBiometrics()
                                }
                            }) {
                                HStack {
                                    Image(systemName: authViewModel.biometricManager.biometricType == .faceID ? "faceid" : "touchid")
                                    Text("Login with \(authViewModel.biometricManager.biometricTypeName)")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                            )
                            .disabled(authViewModel.isLoading || !authViewModel.biometricManager.isBiometricEnabled)
                            .opacity(authViewModel.biometricManager.isBiometricEnabled ? 1 : 0.5)
                        }
                        
                        // Register link
                        Button(action: {
                            showRegistration = true
                        }) {
                            Text("Don't have an account? Register")
                                .foregroundColor(.white)
                                .font(.footnote)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                .padding(.top, 60)
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .sheet(isPresented: $showRegistration) {
                RegistrationView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
