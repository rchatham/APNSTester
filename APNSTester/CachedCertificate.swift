//
//  CachedCertificate.swift
//  APNSTester
//
//  Created by Reid Chatham on 4/16/23.
//

import SwiftUI
import Security

struct CachedCertificate {
    private static var cache: [String: SecCertificate] = [:]
    private let userDefaultsKey: String

    init(userDefaultsKey: String) {
        self.userDefaultsKey = userDefaultsKey
        certificate = commonName != nil ? CachedCertificate.retrieveCertificate(withCommonName: commonName!) : nil
    }

    var certificate: SecCertificate? {
        didSet {
            if let certificate = certificate, let commonName = CachedCertificate.getCommonName(from: certificate) {
                UserDefaults.standard.setValue(commonName, forKey: userDefaultsKey)
            }
        }
    }

    var commonName: String? {
        UserDefaults.standard.string(forKey: userDefaultsKey)
    }

    static func getCommonName(from certificate: SecCertificate) -> String? {
        var commonName: CFString?
        let status = SecCertificateCopyCommonName(certificate, &commonName)
        return status == errSecSuccess ? commonName! as String : nil
    }

    static func retrieveCertificate(withCommonName commonName: String) -> SecCertificate? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassCertificate,
            kSecAttrLabel: commonName,
            kSecReturnRef: kCFBooleanTrue!,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }

        return item as! SecCertificate
    }

    static func searchKeychainForCerts() -> [SecCertificate] {
        let query: [CFString: Any] = [
            kSecClass: kSecClassCertificate,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecReturnRef: true
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let certs = result as? [SecCertificate] else {
            print("Error searching keychain: \(status)")
            return []
        }

        return certs
    }
}
