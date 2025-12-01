//
//  Bank.swift
//  PSD2TestingApplication
//
//  Created by Mircea Stanciu on 29.11.2025.
//

import Foundation

struct Bank: Identifiable, Codable {
    let id: UUID
    let name: String
    let logoName: String // Asset name for the bank logo
    let logoColor: String
    let bic: String
    let country: String
    var isConnected: Bool
    
    init(id: UUID = UUID(), name: String, logoName: String, logoColor: String = "blue", bic: String, country: String = "Romania", isConnected: Bool = false) {
        self.id = id
        self.name = name
        self.logoName = logoName
        self.logoColor = logoColor
        self.bic = bic
        self.country = country
        self.isConnected = isConnected
    }
}

// Romanian Banks that support PSD2
extension Bank {
    static let romanianBanks: [Bank] = [
        Bank(name: "Raiffeisen Bank", logoName: "raiffeisen_logo", logoColor: "yellow", bic: "RZBBROBU"),
        Bank(name: "BCR", logoName: "bcr_logo", logoColor: "yellow", bic: "RNCBROBU"),
        Bank(name: "BRD - Société Générale", logoName: "brd_logo", logoColor: "red", bic: "BRDEROBU"),
        Bank(name: "Banca Transilvania", logoName: "bt_logo", logoColor: "orange", bic: "BTRLRO22"),
        Bank(name: "ING Bank Romania", logoName: "ing_logo", logoColor: "orange", bic: "INGBROBU"),
        Bank(name: "UniCredit Bank", logoName: "unicredit_logo", logoColor: "red", bic: "BACXROBU"),
        Bank(name: "CEC Bank", logoName: "cec_logo", logoColor: "blue", bic: "CECEROBU"),
        Bank(name: "Alpha Bank", logoName: "alpha_logo", logoColor: "blue", bic: "BUCOROBU"),
        Bank(name: "Garanti BBVA", logoName: "garanti_logo", logoColor: "blue", bic: "TGBARO22"),
        Bank(name: "OTP Bank", logoName: "otp_logo", logoColor: "green", bic: "OTPVROBU"),
        Bank(name: "Banca Românească", logoName: "br_logo", logoColor: "purple", bic: "BRMAROBU"),
        Bank(name: "Libra Bank", logoName: "libra_logo", logoColor: "indigo", bic: "LIROROBU"),
        Bank(name: "Patria Bank", logoName: "patria_logo", logoColor: "blue", bic: "PATNROBU"),
        Bank(name: "Vista Bank", logoName: "vista_logo", logoColor: "teal", bic: "CRDOROBU"),
        Bank(name: "Intesa Sanpaolo", logoName: "intesa_logo", logoColor: "blue", bic: "BCPTROBU"),
        Bank(name: "ProCredit Bank", logoName: "procredit_logo", logoColor: "green", bic: "MIRO ROBU"),
        Bank(name: "First Bank", logoName: "first_logo", logoColor: "blue", bic: "FINVROBU"),
        Bank(name: "Exim Bank", logoName: "exim_logo", logoColor: "purple", bic: "EXIM ROBU")
    ]
}
