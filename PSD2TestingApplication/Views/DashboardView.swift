//
//  DashboardView.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSettings = false
    @State private var showBankConnections = false
    @State private var showProfiles = false
    @State private var showEnvironmentSwitcher = false
    @State private var refreshTrigger = UUID()
    
    var userProfiles: [Profile] {
        guard let userId = authViewModel.currentUser?.id else { return [] }
        return authViewModel.profileManager.getProfilesForUser(userId)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Welcome header with integrated dropdowns
                            VStack(alignment: .leading, spacing: 16) {
                                // Dropdowns at top of banner
                                HStack(spacing: 10) {
                                    // Profile dropdown
                                    if let activeProfile = authViewModel.profileManager.activeProfile {
                                        Menu {
                                            ForEach(userProfiles) { profile in
                                                Button(action: {
                                                    authViewModel.profileManager.switchProfile(profile)
                                                }) {
                                                    HStack {
                                                        Image(systemName: profile.icon)
                                                            .foregroundColor(colorFromString(profile.color))
                                                        Text(profile.name)
                                                            .font(.system(size: 17, weight: .medium))
                                                        if profile.id == activeProfile.id {
                                                            Spacer()
                                                            Image(systemName: "checkmark.circle.fill")
                                                                .foregroundColor(.green)
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            Divider()
                                            
                                            Button(action: {
                                                showProfiles = true
                                            }) {
                                                Label("Manage Profiles", systemImage: "person.2.circle.fill")
                                                    .font(.system(size: 17, weight: .medium))
                                            }
                                        } label: {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Profile selection")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(.red)
                                                HStack(spacing: 6) {
                                                    Text(authViewModel.profileManager.activeProfile?.name ?? "Profile")
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .foregroundColor(.primary)
                                                    Image(systemName: "chevron.down")
                                                        .font(.system(size: 10, weight: .semibold))
                                                        .foregroundColor(.secondary)
                                                }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                    )
                                }                                        // Environment dropdown
                                        Menu {
                                            // Sandbox environments
                                            Section(header: HStack {
                                                Image(systemName: "cube.transparent.fill")
                                                    .foregroundColor(.orange)
                                                Text("Sandbox")
                                                    .font(.system(size: 17, weight: .semibold))
                                            }) {
                                                ForEach(PSD2Environment.sandboxEnvironments.filter { activeProfile.availableEnvironments.contains($0) }, id: \.self) { env in
                                                    Button(action: {
                                                        authViewModel.profileManager.switchEnvironment(env, for: activeProfile.id)
                                                    }) {
                                                        HStack {
                                                            Image(systemName: env.icon)
                                                                .foregroundColor(.orange)
                                                            Text(env.subEnvironment)
                                                                .font(.system(size: 17, weight: .medium))
                                                            if env == activeProfile.activeEnvironment {
                                                                Spacer()
                                                                Image(systemName: "checkmark.circle.fill")
                                                                    .foregroundColor(.green)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            // Real Data environments
                                            Section(header: HStack {
                                                Image(systemName: "server.rack")
                                                    .foregroundColor(.green)
                                                Text("Real Data")
                                                    .font(.system(size: 17, weight: .semibold))
                                            }) {
                                                ForEach(PSD2Environment.realDataEnvironments.filter { activeProfile.availableEnvironments.contains($0) }, id: \.self) { env in
                                                    Button(action: {
                                                        authViewModel.profileManager.switchEnvironment(env, for: activeProfile.id)
                                                    }) {
                                                        HStack {
                                                            Image(systemName: env.icon)
                                                                .foregroundColor(.green)
                                                            Text(env.subEnvironment)
                                                                .font(.system(size: 17, weight: .medium))
                                                            if env == activeProfile.activeEnvironment {
                                                                Spacer()
                                                                Image(systemName: "checkmark.circle.fill")
                                                                    .foregroundColor(.green)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            Divider()
                                            
                                            Button(action: {
                                                showEnvironmentSwitcher = true
                                            }) {
                                                Label("Manage Environments", systemImage: "gearshape.2.fill")
                                                    .font(.system(size: 17, weight: .medium))
                                            }
                                        } label: {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Manage Environment")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(.red)
                                                HStack(spacing: 6) {
                                                    if let activeEnv = authViewModel.profileManager.activeProfile?.activeEnvironment {
                                                        Image(systemName: activeEnv.icon)
                                                            .font(.system(size: 14))
                                                            .foregroundColor(colorFromString(activeEnv.color))
                                                    }
                                                    Text(authViewModel.profileManager.activeProfile?.activeEnvironment.subEnvironment ?? "Environment")
                                                        .font(.system(size: 15, weight: .semibold))
                                                        .foregroundColor(.primary)
                                                    Image(systemName: "chevron.down")
                                                        .font(.system(size: 10, weight: .semibold))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color(.systemBackground))
                                                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                            )
                                        }
                                    } else {
                                        // No profile - show create profile button
                                        Button(action: {
                                            showProfiles = true
                                        }) {
                                            HStack {
                                                Image(systemName: "person.badge.plus")
                                                    .font(.system(size: 14))
                                                Text("Create Profile")
                                                    .font(.system(size: 15, weight: .semibold))
                                            }
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                    )
                                    .foregroundColor(.primary)
                                }
                            }
                        }                                // Welcome text (always visible)
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Welcome back,")
                                                .font(.title3)
                                                .foregroundColor(.white.opacity(0.8))
                                            
                                            Text(authViewModel.currentUser?.fullName ?? "User")
                                                .font(.system(size: 32, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Spacer()
                                    }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .padding(.horizontal)
                            .padding(.top)
                            
                            VStack(spacing: 20) {
                                // Quick stats
                                HStack(spacing: 15) {
                                    StatCard(title: "Connected Banks", value: "0", icon: "building.2.fill", color: .blue)
                                    StatCard(title: "Accounts", value: "0", icon: "creditcard.fill", color: .green)
                                }
                                .padding(.horizontal)
                                
                                // Main features
                                VStack(spacing: 15) {
                                    Text("PSD2 Services")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal)
                                    
                                    FeatureCard(
                                        title: "Account Information Service",
                                        subtitle: "View accounts and transactions",
                                        icon: "list.bullet.rectangle.fill",
                                        color: .blue,
                                        action: {}
                                    )
                                    
                                    FeatureCard(
                                        title: "Payment Initiation Service",
                                        subtitle: "Initiate secure payments",
                                        icon: "arrow.right.arrow.left.circle.fill",
                                        color: .purple,
                                        action: {}
                                    )
                                    
                                    FeatureCard(
                                        title: "Bank Connections",
                                        subtitle: "Manage your bank links",
                                        icon: "link.circle.fill",
                                        color: .orange,
                                        action: {
                                            showBankConnections = true
                                        }
                                    )
                                    
                                    FeatureCard(
                                        title: "Transaction History",
                                        subtitle: "View all transactions",
                                        icon: "clock.arrow.circlepath",
                                        color: .teal,
                                        action: {}
                                    )
                                }
                                .padding(.horizontal)
                                
                                Spacer(minLength: 30)
                            }
                            .padding(.top, 10)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showSettings = true
                        }) {
                            Label("Settings", systemImage: "gear")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            authViewModel.logout()
                        }) {
                            Label("Logout", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(biometricManager: authViewModel.biometricManager)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showBankConnections) {
                NavigationView {
                    BankConnectionsView()
                }
            }
            .sheet(isPresented: $showProfiles) {
                ProfilesView(profileManager: authViewModel.profileManager)
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showEnvironmentSwitcher) {
                EnvironmentSwitcherView(profileManager: authViewModel.profileManager)
            }
        }
    }
}

// Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Feature Card Component
struct FeatureCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

func colorFromString(_ colorName: String) -> Color {
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

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
}
