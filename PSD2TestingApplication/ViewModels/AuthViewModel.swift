//
//  AuthViewModel.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    let biometricManager = BiometricAuthManager()
    let profileManager = ProfileManager()
    
    private let userDefaultsKey = "PSD2_Users"
    private let currentUserKey = "PSD2_CurrentUser"
    private let userDataKey = "PSD2_UserData"
    private let sessionExpirationKey = "PSD2_SessionExpiration"
    private let sessionDuration: TimeInterval = 15 * 60 // 15 minutes in seconds
    
    private var sessionTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkAuthentication()
        startSessionMonitoring()
        
        // Forward ProfileManager changes to AuthViewModel
        profileManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // Check if user is already authenticated
    func checkAuthentication() {
        // Check if session has expired
        if let expirationDate = UserDefaults.standard.object(forKey: sessionExpirationKey) as? Date {
            if Date() > expirationDate {
                // Session expired
                logout()
                return
            }
        }
        
        if let userData = UserDefaults.standard.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
            isAuthenticated = true
            refreshSession()
        }
    }
    
    // Start monitoring session expiration
    private func startSessionMonitoring() {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkSessionExpiration()
        }
    }
    
    // Check if session has expired
    @MainActor
    private func checkSessionExpiration() {
        guard isAuthenticated else { return }
        
        if let expirationDate = UserDefaults.standard.object(forKey: sessionExpirationKey) as? Date {
            if Date() > expirationDate {
                logout()
            }
        }
    }
    
    // Refresh session expiration time
    private func refreshSession() {
        let expirationDate = Date().addingTimeInterval(sessionDuration)
        UserDefaults.standard.set(expirationDate, forKey: sessionExpirationKey)
    }
    
    // Register new user
    func register(email: String, password: String, username: String, fullName: String) async {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Validate input
        guard !email.isEmpty, !password.isEmpty, !username.isEmpty, !fullName.isEmpty else {
            errorMessage = "All fields are required"
            isLoading = false
            return
        }
        
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email"
            isLoading = false
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return
        }
        
        // Check if user already exists
        var users = loadUsers()
        var userData = loadUserData()
        
        if users.contains(where: { $0.key == email }) {
            errorMessage = "User with this email already exists"
            isLoading = false
            return
        }
        
        if userData.contains(where: { $0.username == username }) {
            errorMessage = "Username already taken"
            isLoading = false
            return
        }
        
        // Create new user
        let newUser = User(email: email, username: username, fullName: fullName)
        users[email] = password
        userData.append(newUser)
        
        // Save users
        UserDefaults.standard.set(users, forKey: userDefaultsKey)
        
        // Save user data
        if let encoded = try? JSONEncoder().encode(userData) {
            UserDefaults.standard.set(encoded, forKey: userDataKey)
        }
        
        // Save current user
        if let encoded = try? JSONEncoder().encode(newUser) {
            UserDefaults.standard.set(encoded, forKey: currentUserKey)
        }
        
        currentUser = newUser
        isAuthenticated = true
        refreshSession()
        
        // Create default profile for new user
        profileManager.createProfile(
            name: "Personal",
            color: "blue",
            icon: "person.circle.fill",
            userId: newUser.id
        )
        
        isLoading = false
    }
    
    // Login existing user
    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Validate input
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Username and password are required"
            isLoading = false
            return
        }
        
        // Get user data
        let userData = loadUserData()
        guard let user = userData.first(where: { $0.username == username }) else {
            errorMessage = "Invalid username or password"
            isLoading = false
            return
        }
        
        // Check credentials
        let users = loadUsers()
        guard let storedPassword = users[user.email], storedPassword == password else {
            errorMessage = "Invalid username or password"
            isLoading = false
            return
        }
        
        // Save current user
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: currentUserKey)
        }
        
        currentUser = user
        isAuthenticated = true
        refreshSession()
        isLoading = false
    }
    
    // Login with biometrics
    func loginWithBiometrics() async {
        guard biometricManager.isBiometricEnabled else {
            errorMessage = "Biometric login not enabled"
            return
        }
        
        // Try to get the current user, or load the last user from storage
        if currentUser == nil {
            // Try to load the last user from storage
            if !checkForLastUser() {
                errorMessage = "No user found for biometric login. Please log in first."
                return
            }
        }
        
        isLoading = true
        let success = await biometricManager.authenticate(reason: "Login to PSD2 Banking")
        
        if success {
            isAuthenticated = true
            print("✅ Biometric authentication successful for user: \(currentUser?.username ?? "unknown")")
            refreshSession()
        } else {
            errorMessage = "Biometric authentication failed"
            print("❌ Biometric authentication failed")
        }
        
        isLoading = false
    }
    
    // Check for last logged in user
    private func checkForLastUser() -> Bool {
        if let userData = UserDefaults.standard.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
            return true
        }
        return false
    }
    
    // Logout
    func logout() {
        sessionTimer?.invalidate()
        // Keep currentUserKey for biometric login - only remove session
        UserDefaults.standard.removeObject(forKey: sessionExpirationKey)
        currentUser = nil
        isAuthenticated = false
        print("✅ User logged out - biometric login data preserved")
    }
    
    // Delete Account
    func deleteAccount() {
        guard let user = currentUser else {
            errorMessage = "No user to delete"
            return
        }
        
        // Remove user from credentials
        var users = loadUsers()
        users.removeValue(forKey: user.email)
        UserDefaults.standard.set(users, forKey: userDefaultsKey)
        
        // Remove user from user data
        var userData = loadUserData()
        userData.removeAll { $0.id == user.id }
        if let encoded = try? JSONEncoder().encode(userData) {
            UserDefaults.standard.set(encoded, forKey: userDataKey)
        }
        
        // Remove current user and session
        UserDefaults.standard.removeObject(forKey: currentUserKey)
        UserDefaults.standard.removeObject(forKey: sessionExpirationKey)
        sessionTimer?.invalidate()
        
        // Delete user's profiles and configurations
        profileManager.deleteAllProfilesForUser(user.id)
        
        // Reset state
        currentUser = nil
        isAuthenticated = false
        
        print("✅ Account deleted for user: \(user.email)")
    }
    
    // Helper: Load users from UserDefaults
    private func loadUsers() -> [String: String] {
        return UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: String] ?? [:]
    }
    
    // Helper: Load user data from UserDefaults
    private func loadUserData() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: userDataKey),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return []
        }
        return users
    }
}
