//
//  ContentView.swift
//  APNS Push Notification Tester
//
//  Created by Reid Chatham on 4/14/23.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedCertificate: SecCertificate?
    @State private var deviceToken: String = ""
    @State private var alertTitle: String = ""
    @State private var alertBody: String = ""
    @State private var statusMessage: String = ""
    @State private var showCertificatePicker: Bool = false
    @State private var appId: String = ""
    @State private var useSandbox: Bool = true
    @State private var useAdvanced: Bool = false
    @State private var jsonPayload: String = ""

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("Certificate:")
                Button("Choose") {
                    showCertificatePicker = true
                }
                if let certificate = selectedCertificate,
                   let commonName = getCommonName(from: certificate) {
                    Text(commonName)
                        .foregroundColor(.blue)
                }
                TextField("App ID", text: $appId) // Add the App ID text field
                TextField("Device token", text: $deviceToken)
                if !useAdvanced {
                    TextField("Alert title", text: $alertTitle)
                    TextField("Alert body", text: $alertBody)
                } else {
                    Text("JSON Payload (advanced)")
                    TextEditor(text: $jsonPayload)
                        .border(Color.gray, width: 1)
                        .frame(height: 150)
                }
                Toggle("Use Advanced", isOn: $useAdvanced)
                Toggle("Use Sandbox", isOn: $useSandbox)
                Button("Send Push Notification") {
                    sendPushNotification()
                }
            }.padding()
            Text(statusMessage)
                .foregroundColor(.red)
        }
        .sheet(isPresented: $showCertificatePicker) {
            CertificatePickerView(selectedCertificate: $selectedCertificate, showCertificatePicker: $showCertificatePicker)
                .frame(minWidth: 300, minHeight: 200)
        }
    }

    private func getCertificate(from identity: SecIdentity) -> SecCertificate? {
        var certificate: SecCertificate?
        let status = SecIdentityCopyCertificate(identity, &certificate)
        return status == errSecSuccess ? certificate : nil
    }

    private func getCommonName(from certificate: SecCertificate) -> String? {
        var commonName: CFString?
        let status = SecCertificateCopyCommonName(certificate, &commonName)
        return status == errSecSuccess ? commonName! as String : nil
    }

    private func sendPushNotification() {
        guard let certificate = selectedCertificate, !deviceToken.isEmpty, !appId.isEmpty else {
            statusMessage = "Please select a certificate, enter the device token, and enter the app ID."
            return
        }

        APNSManager.shared.sendPushNotification(certificate: certificate, appId: appId, deviceToken: deviceToken, title: useAdvanced ? "" : alertTitle, body: useAdvanced ? "" : alertBody, customPayload: useAdvanced ? jsonPayload : "", useSandbox: useSandbox) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    statusMessage = "Push notification sent successfully."
                case .failure(let error):
                    switch error {
                    case .invalidDeviceToken:
                        statusMessage = "Invalid device token."
                    case .connectionError:
                        statusMessage = "Connection error."
                    case .invalidIdentity:
                        statusMessage = "Invalid identity."
                    case .payloadError:
                        statusMessage = "Payload error."
                    default:
                        statusMessage = "Error: \(error.localizedDescription)"
                    }
                    print(error.localizedDescription)
                }
            }
        }
    }
}
