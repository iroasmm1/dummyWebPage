//
//  User.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let username: String
    let fullName: String
    let createdAt: Date
    
    init(id: UUID = UUID(), email: String, username: String, fullName: String, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.username = username
        self.fullName = fullName
        self.createdAt = createdAt
    }
}
