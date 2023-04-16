//
//  CertificatePicker.swift
//  APNS Push Notification Tester
//
//  Created by Reid Chatham on 4/14/23.
//

import SwiftUI

struct CertificatePickerView: View {
    @Binding var cachedCertificate: CachedCertificate
    @Binding var showCertificatePicker: Bool
    @State private var certificates: [SecCertificate] = []

    var body: some View {
        List(certificates.indices, id: \.self) { index in
            if let commonName = SecCertificateCopySubjectSummary(certificates[index]) as String? {
                Text(commonName)
                    .onTapGesture {
                        cachedCertificate.certificate = certificates[index]
                        showCertificatePicker = false
                    }
            }
        }
        .onAppear {
            certificates = CachedCertificate.searchKeychainForCerts()
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    showCertificatePicker = false
                }
            }
        }
    }
}
