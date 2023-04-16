//
//  APNSManager.swift
//  APNS Push Notification Tester
//
//  Created by Reid Chatham on 4/14/23.
//

import Foundation

class APNSManager: NSObject, URLSessionDelegate {
    enum APNSError: Error {
        case invalidIdentity
        case invalidDeviceToken
        case connectionError
        case payloadError
    }
    
    static let shared = APNSManager()
    
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    private var certificate: SecCertificate?
    
    
    /*
     Test payload:
     {
       aps: {
         alert: {
           title: "test title",
           body: "test body"
         },
         sound: "default"
       }
     }
     */
    
    func sendPushNotification(certificate: SecCertificate, appId: String, deviceToken: String, title: String, body: String, customPayload: String, useSandbox: Bool, completion: @escaping (Result<Void, APNSError>) -> Void) {
        self.certificate = certificate
        // 1. Extract the identity from the keychain
        guard let identity = extractIdentity(certificate: certificate) else {
            completion(.failure(.invalidIdentity))
            return
        }
        
        // 2. Establish a secure connection to the APNS server
        let environment = useSandbox ? "api.sandbox" : "api"
        let apnsURL = URL(string: "https://\(environment).push.apple.com/3/device/\(deviceToken)")!
        var request = URLRequest(url: apnsURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("bearer \(identity)", forHTTPHeaderField: "authorization")
        request.setValue(appId, forHTTPHeaderField: "apns-topic") // Add the app ID to the request headers
        
        // 3. Create a JSON payload
        if customPayload.isEmpty {
            let payload: [String: Any] = [
                "aps": [
                    "alert": [
                        "title": title,
                        "body": body
                    ],
                    "sound": "default"
                ]
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
            } catch {
                completion(.failure(.payloadError))
                return
            }
        } else {
            if let processedPayload = processCustomPayload(customPayload) {
               request.httpBody = processedPayload.data(using: .utf8)
           } else {
               completion(.failure(.payloadError))
               return
           }
        }
        
        // 4. Send the push notification
        let task = urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(.failure(.connectionError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.connectionError))
                return
            }
            
            // 5. Handle the response from the APNS server
            completion(.success(()))
        }
        
        task.resume()
    }
    
    private func extractIdentity(certificate: SecCertificate) -> SecIdentity? {
        var identity: SecIdentity?
        var identityRef: CFTypeRef?
        let query: [CFString: Any] = [
            kSecClass: kSecClassIdentity,
            kSecReturnRef: true,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecMatchItemList: [certificate] as CFArray
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, &identityRef)
        guard status == errSecSuccess, let ref = identityRef else {
            print("Error extracting identity: \(status)")
            return nil
        }
        
        identity = (ref as! SecIdentity)
        return identity
    }
    
    func processCustomPayload(_ payload: String) -> String? {
        let trimmedPayload = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        let replacedSmartQuotes = trimmedPayload.replacingOccurrences(of: "“|”", with: "\"", options: .regularExpression)
        let fixedEscapedQuotes = replacedSmartQuotes.replacingOccurrences(of: "\\\\\"", with: "\"", options: .regularExpression)
        let fixedKeys = addQuotesToKeys(in: fixedEscapedQuotes)
        let unwrappedPayload = fixedKeys.trimmingCharacters(in: .init(charactersIn: "\""))
        
        guard let data = unwrappedPayload.data(using: .utf8) else {
            return nil
        }

        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)

            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error processing custom payload: \(error.localizedDescription)")
            return nil
        }
    }

    private func addQuotesToKeys(in jsonString: String) -> String {
        let regexPattern = "(?<=\\s|^)(\\w+)(?=\\s*:)"

        do {
            let regex = try NSRegularExpression(pattern: regexPattern, options: [])
            let nsRange = NSRange(jsonString.startIndex..<jsonString.endIndex, in: jsonString)
            let fixedKeys = regex.stringByReplacingMatches(in: jsonString, options: [], range: nsRange, withTemplate: "\"$1\"")
            return fixedKeys
        } catch {
            print("Error in regex pattern: \(error.localizedDescription)")
            return jsonString
        }
    }
    
    // URLSessionDelegate methods
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate,
              let certificate = self.certificate,
              let identity = extractIdentity(certificate: certificate) else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        let credential = URLCredential(identity: identity, certificates: [certificate], persistence: .forSession)
        completionHandler(.useCredential, credential)
    }
}
