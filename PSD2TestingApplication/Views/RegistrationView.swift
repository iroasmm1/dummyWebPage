//
//  RegistrationView.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var fullName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 10) {
                            Image(systemName: "person.badge.plus.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text("Create Account")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Join PSD2 Banking Platform")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 30)
                        
                        // Registration form
                        VStack(spacing: 16) {
                            // Full name field
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                TextField("Full Name", text: $fullName)
                                    .textContentType(.name)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
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
                            
                            // Email field
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.gray)
                                TextField("Email", text: $email)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
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
                                    .textContentType(.newPassword)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            // Confirm password field
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gray)
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            // Password validation message
                            if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords do not match")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                            }
                            
                            // Terms and conditions
                            HStack(alignment: .top, spacing: 10) {
                                Button(action: {
                                    agreedToTerms.toggle()
                                }) {
                                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                        .foregroundColor(agreedToTerms ? .blue : .white)
                                        .font(.title3)
                                }
                                
                                Text("I agree to the Terms & Conditions and PSD2 compliance requirements")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 5)
                            
                            // Error message
                            if let errorMessage = authViewModel.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.horizontal)
                            }
                            
                            // Register button
                            Button(action: {
                                guard password == confirmPassword else {
                                    return
                                }
                                guard agreedToTerms else {
                                    return
                                }
                                Task {
                                    await authViewModel.register(email: email, password: password, username: username, fullName: fullName)
                                    if authViewModel.isAuthenticated {
                                        dismiss()
                                    }
                                }
                            }) {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                password == confirmPassword && agreedToTerms && !fullName.isEmpty && !username.isEmpty && !email.isEmpty
                                ? Color.green
                                : Color.gray
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .disabled(authViewModel.isLoading || password != confirmPassword || !agreedToTerms)
                            
                            // Back to login
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Already have an account? Login")
                                    .foregroundColor(.white)
                                    .font(.footnote)
                            }
                            .padding(.top, 10)
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    RegistrationView()
        .environmentObject(AuthViewModel())
}
