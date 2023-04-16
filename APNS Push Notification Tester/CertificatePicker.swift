//
//  CertificatePicker.swift
//  APNS Push Notification Tester
//
//  Created by Reid Chatham on 4/14/23.
//

import SwiftUI

struct CertificatePickerView: View {
    @Binding var selectedCertificate: SecCertificate?
    @Binding var showCertificatePicker: Bool
    @State private var certificates: [SecCertificate] = []

    var body: some View {
        List(certificates.indices, id: \.self) { index in
            if let commonName = SecCertificateCopySubjectSummary(certificates[index]) as String? {
                Text(commonName)
                    .onTapGesture {
                        selectedCertificate = certificates[index]
                        showCertificatePicker = false
                    }
            }
        }
        .onAppear {
            certificates = searchKeychainForCerts()
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    showCertificatePicker = false
                }
            }
        }
    }
    
    func searchKeychainForCerts() -> [SecCertificate] {
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
