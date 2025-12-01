//
//  ProfilesView.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import SwiftUI

struct ProfilesView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var profileManager: ProfileManager
    @Environment(\.dismiss) var dismiss
    
    @State private var showCreateProfile = false
    
    var userProfiles: [Profile] {
        guard let userId = authViewModel.currentUser?.id else { return [] }
        return profileManager.getProfilesForUser(userId)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Active Profile
                    if let activeProfile = profileManager.activeProfile {
                        VStack(spacing: 15) {
                            Text("Active Profile")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ActiveProfileCard(profile: activeProfile)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    
                    // All Profiles
                    VStack(spacing: 15) {
                        HStack {
                            Text("All Profiles")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                showCreateProfile = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("New")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(userProfiles) { profile in
                                ProfileCard(
                                    profile: profile,
                                    isActive: profile.id == profileManager.activeProfile?.id,
                                    onSwitch: {
                                        profileManager.switchProfile(profile)
                                    },
                                    onEdit: {
                                        // Edit action
                                    },
                                    onDelete: {
                                        if userProfiles.count > 1 {
                                            profileManager.deleteProfile(profile)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCreateProfile) {
                CreateProfileView(profileManager: profileManager)
                    .environmentObject(authViewModel)
            }
        }
    }
}

// Active Profile Card
struct ActiveProfileCard: View {
    let profile: Profile
    @State private var showEnvironmentManager = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(colorFromString(profile.color).opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: profile.icon)
                        .font(.system(size: 28))
                        .foregroundColor(colorFromString(profile.color))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Active Profile")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                    
                    Text("\(profile.connectedBanks.count) connected banks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Environment info
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: profile.activeEnvironment.icon)
                        .font(.caption)
                    Text("Environment:")
                        .font(.caption)
                    Text(profile.activeEnvironment.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    showEnvironmentManager = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                        Text("Manage")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showEnvironmentManager) {
            ManageEnvironmentsView(profile: profile)
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

// Profile Card
struct ProfileCard: View {
    let profile: Profile
    let isActive: Bool
    let onSwitch: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(colorFromString(profile.color).opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: profile.icon)
                    .font(.title3)
                    .foregroundColor(colorFromString(profile.color))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.headline)
                
                Text("\(profile.connectedBanks.count) banks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button(action: onSwitch) {
                    Text("Switch")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: {
                    showDeleteAlert = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .alert("Delete Profile", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete this profile? This action cannot be undone.")
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

// Create Profile View
struct CreateProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject var profileManager: ProfileManager
    @Environment(\.dismiss) var dismiss
    
    @State private var profileName = ""
    @State private var selectedColor = "blue"
    @State private var selectedIcon = "person.circle.fill"
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Details")) {
                    TextField("Profile Name", text: $profileName)
                }
                
                Section(header: Text("Choose Color")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 15) {
                        ForEach(Profile.profileColors, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                Circle()
                                    .fill(colorFromString(color))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Choose Icon")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 15) {
                        ForEach(Profile.profileIcons, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(.systemGray6))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .foregroundColor(selectedIcon == icon ? .blue : .secondary)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(selectedIcon == icon ? Color.blue : Color.clear, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        guard let userId = authViewModel.currentUser?.id else { return }
                        profileManager.createProfile(
                            name: profileName.isEmpty ? "New Profile" : profileName,
                            color: selectedColor,
                            icon: selectedIcon,
                            userId: userId
                        )
                        dismiss()
                    }) {
                        Text("Create")
                            .fontWeight(.semibold)
                    }
                }
            }
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
    ProfilesView(profileManager: ProfileManager())
        .environmentObject(AuthViewModel())
}
