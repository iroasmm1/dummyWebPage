//
//  Profile.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import Foundation

enum PSD2Environment: String, Codable, CaseIterable {
    case sandboxTest = "SB Test"
    case sandboxPrelive = "SB Prelive"
    case sandboxProduction = "SB Production"
    case realTest = "RD Test"
    case realPrelive = "RD Prelive"
    case realProduction = "RD Production"
    
    var color: String {
        switch self {
        case .sandboxTest, .sandboxPrelive, .sandboxProduction:
            return "orange"
        case .realTest, .realPrelive, .realProduction:
            return "green"
        }
    }
    
    var icon: String {
        switch self {
        case .sandboxTest:
            return "testtube.2"
        case .sandboxPrelive:
            return "arrow.triangle.2.circlepath"
        case .sandboxProduction:
            return "checkmark.seal.fill"
        case .realTest:
            return "wrench.and.screwdriver.fill"
        case .realPrelive:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .realProduction:
            return "star.circle.fill"
        }
    }
    
    var category: String {
        switch self {
        case .sandboxTest, .sandboxPrelive, .sandboxProduction:
            return "Sandbox"
        case .realTest, .realPrelive, .realProduction:
            return "Real Data"
        }
    }
    
    var subEnvironment: String {
        switch self {
        case .sandboxTest, .realTest:
            return "Test"
        case .sandboxPrelive, .realPrelive:
            return "Prelive"
        case .sandboxProduction, .realProduction:
            return "Production"
        }
    }
    
    static var sandboxEnvironments: [PSD2Environment] {
        [.sandboxTest, .sandboxPrelive, .sandboxProduction]
    }
    
    static var realDataEnvironments: [PSD2Environment] {
        [.realTest, .realPrelive, .realProduction]
    }
}

struct Profile: Identifiable, Codable {
    let id: UUID
    var name: String
    var color: String
    var icon: String
    let userId: UUID
    var isActive: Bool
    let createdAt: Date
    var connectedBanks: [UUID]
    var activeEnvironment: PSD2Environment
    var availableEnvironments: [PSD2Environment]
    
    init(id: UUID = UUID(), name: String, color: String = "blue", icon: String = "person.circle.fill", userId: UUID, isActive: Bool = false, createdAt: Date = Date(), connectedBanks: [UUID] = [], activeEnvironment: PSD2Environment = .sandboxTest, availableEnvironments: [PSD2Environment] = [.sandboxTest, .sandboxPrelive, .sandboxProduction, .realTest, .realPrelive, .realProduction]) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.userId = userId
        self.isActive = isActive
        self.createdAt = createdAt
        self.connectedBanks = connectedBanks
        self.activeEnvironment = activeEnvironment
        self.availableEnvironments = availableEnvironments
    }
}

// Profile presets
extension Profile {
    static let profileColors = ["blue", "purple", "green", "orange", "pink", "red", "teal", "indigo", "yellow"]
    static let profileIcons = [
        "person.circle.fill",
        "briefcase.circle.fill",
        "house.circle.fill",
        "cart.circle.fill",
        "heart.circle.fill",
        "star.circle.fill",
        "creditcard.circle.fill",
        "bag.circle.fill"
    ]
}
