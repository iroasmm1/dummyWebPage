//
//  ManageEnvironmentsView.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import SwiftUI

struct ManageEnvironmentsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileManager = ProfileManager()
    let profile: Profile
    
    @State private var localProfile: Profile
    
    init(profile: Profile) {
        self.profile = profile
        _localProfile = State(initialValue: profile)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "gearshape.2.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            
                            Text("Manage Environments")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Configure environments for \(profile.name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        
                        // Active Environment
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active Environment")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            HStack(spacing: 15) {
                                ZStack {
                                    Circle()
                                        .fill(colorFromString(localProfile.activeEnvironment.color).opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: localProfile.activeEnvironment.icon)
                                        .font(.title3)
                                        .foregroundColor(colorFromString(localProfile.activeEnvironment.color))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(localProfile.activeEnvironment.rawValue)
                                        .font(.headline)
                                    
                                    Text("Currently active")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Available Environments
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Available Environments")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            // Sandbox Environments
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "cube.transparent.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Text("Sandbox")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)
                                
                                VStack(spacing: 12) {
                                    ForEach(PSD2Environment.sandboxEnvironments, id: \.self) { environment in
                                        EnvironmentRow(
                                            environment: environment,
                                            isEnabled: localProfile.availableEnvironments.contains(environment),
                                            isActive: localProfile.activeEnvironment == environment,
                                            onToggle: {
                                                toggleEnvironment(environment)
                                            },
                                            onActivate: {
                                                activateEnvironment(environment)
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Real Data Environments
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "server.rack")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text("Real Data")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.top, 12)
                                
                                VStack(spacing: 12) {
                                    ForEach(PSD2Environment.realDataEnvironments, id: \.self) { environment in
                                        EnvironmentRow(
                                            environment: environment,
                                            isEnabled: localProfile.availableEnvironments.contains(environment),
                                            isActive: localProfile.activeEnvironment == environment,
                                            onToggle: {
                                                toggleEnvironment(environment)
                                            },
                                            onActivate: {
                                                activateEnvironment(environment)
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                }
            }
        }
        .onAppear {
            // Reload profile data
            if let updated = profileManager.profiles.first(where: { $0.id == profile.id }) {
                localProfile = updated
            }
        }
    }
    
    private func toggleEnvironment(_ environment: PSD2Environment) {
        if localProfile.availableEnvironments.contains(environment) {
            // Don't allow removing if it's the only one or if it's active
            if localProfile.availableEnvironments.count > 1 && localProfile.activeEnvironment != environment {
                localProfile.availableEnvironments.removeAll { $0 == environment }
            }
        } else {
            localProfile.availableEnvironments.append(environment)
        }
    }
    
    private func activateEnvironment(_ environment: PSD2Environment) {
        if localProfile.availableEnvironments.contains(environment) {
            localProfile.activeEnvironment = environment
        }
    }
    
    private func saveChanges() {
        profileManager.updateProfile(localProfile)
    }
}

// Environment Row Component
struct EnvironmentRow: View {
    let environment: PSD2Environment
    let isEnabled: Bool
    let isActive: Bool
    let onToggle: () -> Void
    let onActivate: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(colorFromString(environment.color).opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: environment.icon)
                    .font(.title3)
                    .foregroundColor(colorFromString(environment.color))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(environment.subEnvironment)
                    .font(.headline)
                    .foregroundColor(isEnabled ? .primary : .secondary)
                
                Text(getEnvironmentDescription(environment))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else if isEnabled {
                Button("Set Active") {
                    onActivate()
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .disabled(isActive) // Can't disable active environment
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
    
    private func getEnvironmentDescription(_ environment: PSD2Environment) -> String {
        switch environment {
        case .sandboxTest:
            return "Test with mock data"
        case .sandboxPrelive:
            return "Prelive sandbox environment"
        case .sandboxProduction:
            return "Production sandbox environment"
        case .realTest:
            return "Test with real data"
        case .realPrelive:
            return "Prelive with real data"
        case .realProduction:
            return "Live production environment"
        }
    }
}

#Preview {
    ManageEnvironmentsView(profile: Profile(
        name: "Personal",
        userId: UUID()
    ))
}
