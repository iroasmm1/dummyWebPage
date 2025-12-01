//
//  EnvironmentSwitcherView.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import SwiftUI

struct EnvironmentSwitcherView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var profileManager: ProfileManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if let activeProfile = profileManager.activeProfile {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            VStack(spacing: 8) {
                                Image(systemName: "server.rack")
                                    .font(.system(size: 50))
                                    .foregroundColor(.blue)
                                
                                Text("Switch Environment")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Choose the environment for \(activeProfile.name)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            
                            // Sandbox Environments
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "cube.transparent.fill")
                                        .foregroundColor(.orange)
                                    Text("Sandbox")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    ForEach(PSD2Environment.sandboxEnvironments.filter { activeProfile.availableEnvironments.contains($0) }, id: \.self) { environment in
                                        Button(action: {
                                            profileManager.switchEnvironment(environment, for: activeProfile.id)
                                            dismiss()
                                        }) {
                                            EnvironmentRowButton(
                                                environment: environment,
                                                isActive: environment == activeProfile.activeEnvironment
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Real Data Environments
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "server.rack")
                                        .foregroundColor(.green)
                                    Text("Real Data")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)
                                
                                VStack(spacing: 12) {
                                    ForEach(PSD2Environment.realDataEnvironments.filter { activeProfile.availableEnvironments.contains($0) }, id: \.self) { environment in
                                        Button(action: {
                                            profileManager.switchEnvironment(environment, for: activeProfile.id)
                                            dismiss()
                                        }) {
                                            EnvironmentRowButton(
                                                environment: environment,
                                                isActive: environment == activeProfile.activeEnvironment
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.top, 20)
                    }
                } else {
                    Text("No active profile")
                        .foregroundColor(.secondary)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getEnvironmentDescription(_ environment: PSD2Environment) -> String {
        "\(environment.category) - \(environment.subEnvironment)"
    }
}

// Environment Row Button Component
struct EnvironmentRowButton: View {
    let environment: PSD2Environment
    let isActive: Bool
    
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
                    .foregroundColor(.primary)
                
                Text(getEnvironmentDescription(environment))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.green : Color.clear, lineWidth: 2)
        )
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
    EnvironmentSwitcherView(profileManager: ProfileManager())
}
