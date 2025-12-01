//
//  ProfileManager.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileManager: ObservableObject {
    @Published var profiles: [Profile] = []
    @Published var activeProfile: Profile?
    
    private let profilesKey = "PSD2_Profiles"
    private let activeProfileKey = "PSD2_ActiveProfile"
    
    init() {
        loadProfiles()
    }
    
    // Load profiles from UserDefaults
    func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let savedProfiles = try? JSONDecoder().decode([Profile].self, from: data) {
            profiles = savedProfiles
            
            // Load active profile
            if let activeData = UserDefaults.standard.data(forKey: activeProfileKey),
               let active = try? JSONDecoder().decode(Profile.self, from: activeData) {
                activeProfile = active
            } else if let first = profiles.first {
                activeProfile = first
            }
        }
    }
    
    // Save profiles to UserDefaults
    private func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: profilesKey)
        }
        
        if let activeProfile = activeProfile,
           let encoded = try? JSONEncoder().encode(activeProfile) {
            UserDefaults.standard.set(encoded, forKey: activeProfileKey)
        }
    }
    
    // Create new profile
    func createProfile(name: String, color: String, icon: String, userId: UUID) {
        let newProfile = Profile(
            name: name,
            color: color,
            icon: icon,
            userId: userId,
            isActive: profiles.isEmpty
        )
        
        profiles.append(newProfile)
        
        if profiles.count == 1 {
            activeProfile = newProfile
        }
        
        saveProfiles()
    }
    
    // Switch to a different profile
    func switchProfile(_ profile: Profile) {
        // Deactivate all profiles
        for index in profiles.indices {
            profiles[index].isActive = false
        }
        
        // Activate selected profile
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index].isActive = true
            activeProfile = profiles[index]
        }
        
        saveProfiles()
    }
    
    // Update profile
    func updateProfile(_ profile: Profile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            
            if activeProfile?.id == profile.id {
                activeProfile = profile
            }
            
            saveProfiles()
        }
    }
    
    // Delete profile
    func deleteProfile(_ profile: Profile) {
        profiles.removeAll { $0.id == profile.id }
        
        if activeProfile?.id == profile.id {
            activeProfile = profiles.first
            if let first = profiles.first {
                switchProfile(first)
            }
        }
        
        saveProfiles()
    }
    
    // Add bank to profile
    func addBankToProfile(bankId: UUID, profileId: UUID) {
        if let index = profiles.firstIndex(where: { $0.id == profileId }) {
            if !profiles[index].connectedBanks.contains(bankId) {
                profiles[index].connectedBanks.append(bankId)
                
                if activeProfile?.id == profileId {
                    activeProfile = profiles[index]
                }
                
                saveProfiles()
            }
        }
    }
    
    // Remove bank from profile
    func removeBankFromProfile(bankId: UUID, profileId: UUID) {
        if let index = profiles.firstIndex(where: { $0.id == profileId }) {
            profiles[index].connectedBanks.removeAll { $0 == bankId }
            
            if activeProfile?.id == profileId {
                activeProfile = profiles[index]
            }
            
            saveProfiles()
        }
    }
    
    // Get profiles for user
    func getProfilesForUser(_ userId: UUID) -> [Profile] {
        return profiles.filter { $0.userId == userId }
    }
    
    // Switch environment for profile
    func switchEnvironment(_ environment: PSD2Environment, for profileId: UUID) {
        if let index = profiles.firstIndex(where: { $0.id == profileId }) {
            profiles[index].activeEnvironment = environment
            
            if activeProfile?.id == profileId {
                activeProfile = profiles[index]
            }
            
            saveProfiles()
        }
    }
    
    // Add environment to profile
    func addEnvironment(_ environment: PSD2Environment, to profileId: UUID) {
        if let index = profiles.firstIndex(where: { $0.id == profileId }) {
            if !profiles[index].availableEnvironments.contains(environment) {
                profiles[index].availableEnvironments.append(environment)
                
                if activeProfile?.id == profileId {
                    activeProfile = profiles[index]
                }
                
                saveProfiles()
            }
        }
    }
    
    // Remove environment from profile
    func removeEnvironment(_ environment: PSD2Environment, from profileId: UUID) {
        if let index = profiles.firstIndex(where: { $0.id == profileId }) {
            profiles[index].availableEnvironments.removeAll { $0 == environment }
            
            // If removing active environment, switch to first available
            if profiles[index].activeEnvironment == environment,
               let firstEnv = profiles[index].availableEnvironments.first {
                profiles[index].activeEnvironment = firstEnv
            }
            
            if activeProfile?.id == profileId {
                activeProfile = profiles[index]
            }
            
            saveProfiles()
        }
    }
    
    // Delete all profiles for a user
    func deleteAllProfilesForUser(_ userId: UUID) {
        profiles.removeAll { $0.userId == userId }
        
        // If active profile was deleted, select a new one
        if activeProfile?.userId == userId {
            activeProfile = profiles.first
        }
        
        saveProfiles()
    }
}
