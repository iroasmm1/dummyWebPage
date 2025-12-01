//
//  BiometricAuthManager.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import Foundation
internal import LocalAuthentication
import SwiftUI
import Combine

class BiometricAuthManager: ObservableObject {
    @Published var isBiometricEnabled = false
    @Published var biometricType: LABiometryType = .none
    
    private let biometricEnabledKey = "PSD2_BiometricEnabled"
    
    init() {
        checkBiometricAvailability()
        loadBiometricPreference()
    }
    
    // Check what type of biometric authentication is available
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }
    
    // Get biometric type name
    var biometricTypeName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Biometric"
        @unknown default:
            return "Biometric"
        }
    }
    
    // Check if biometric is available
    var isBiometricAvailable: Bool {
        return biometricType != .none
    }
    
    // Authenticate with biometrics
    func authenticate(reason: String = "Authenticate to access your account") async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch {
            return false
        }
    }
    
    // Enable biometric authentication
    func enableBiometric() {
        isBiometricEnabled = true
        UserDefaults.standard.set(true, forKey: biometricEnabledKey)
    }
    
    // Disable biometric authentication
    func disableBiometric() {
        isBiometricEnabled = false
        UserDefaults.standard.set(false, forKey: biometricEnabledKey)
    }
    
    // Load biometric preference
    private func loadBiometricPreference() {
        isBiometricEnabled = UserDefaults.standard.bool(forKey: biometricEnabledKey)
    }
}
