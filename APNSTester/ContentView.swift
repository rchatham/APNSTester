//
//  ContentView.swift
//  APNS Push Notification Tester
//
//  Created by Reid Chatham on 4/14/23.
//

import SwiftUI

struct ContentView: View {
    @State private var cachedCertificate = CachedCertificate(userDefaultsKey: "selectedCertificateCommonName")
    @AppStorage("appId") private var appId: String = ""
    @AppStorage("deviceToken") private var deviceToken: String = ""
    @AppStorage("alertTitle") private var alertTitle: String = ""
    @AppStorage("alertBody") private var alertBody: String = ""
    @AppStorage("jsonPayload") private var jsonPayload: String = ""
    @AppStorage("useAdvanced") private var useAdvanced: Bool = false
    @AppStorage("useSandbox") private var useSandbox: Bool = true
    @State private var showCertificatePicker: Bool = false
    @State private var statusMessage: String = ""
    @State private var statusSuccess: Bool = false

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("Certificate:")
                Button("Choose") {
                    showCertificatePicker = true
                }
                if cachedCertificate.certificate != nil {
                    Text(cachedCertificate.commonName ?? "")
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
                .foregroundColor(statusSuccess ? .green : .red)
        }
        .sheet(isPresented: $showCertificatePicker) {
            CertificatePickerView(cachedCertificate: $cachedCertificate, showCertificatePicker: $showCertificatePicker)
                .frame(minWidth: 300, minHeight: 200)
        }
    }

    private func sendPushNotification() {
        guard let certificate = cachedCertificate.certificate, !deviceToken.isEmpty, !appId.isEmpty else {
            statusSuccess = false
            statusMessage = "Please select a certificate, enter the device token, and enter the app ID."
            return
        }

        APNSManager.shared.sendPushNotification(certificate: certificate, appId: appId, deviceToken: deviceToken, title: useAdvanced ? "" : alertTitle, body: useAdvanced ? "" : alertBody, customPayload: useAdvanced ? jsonPayload : "", useSandbox: useSandbox) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    statusSuccess = true
                    statusMessage = "Push notification sent successfully."
                case .failure(let error):
                    statusSuccess = false
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
