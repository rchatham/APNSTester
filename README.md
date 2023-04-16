# APNSTester
APNSTester is a simple macOS SwiftUI application for testing Apple Push Notification Service (APNs) notifications. It allows you to send push notifications to your iOS devices using a custom payload or a predefined alert with a title and body. The app supports both the sandbox and production APNs environments.

## Features
- Select a certificate from the Keychain
- Enter the app ID and device token
- Customize push notification title, body, and payload
- Toggle between advanced mode (custom JSON payload) and basic mode (predefined title and body)
- Choose between sandbox and production APNs environments
- Display status messages (success or error)

## Installation
1. Clone the repository
```
git clone https://github.com/yourusername/APNSTester.git
```
2. Open the project in Xcode
```
cd APNSTester
open APNSTester.xcodeproj
```
3. Build and run the project in Xcode

## Usage
1. Choose a certificate from your Keychain.
2. Enter your app ID and device token.
3. Choose between advanced and basic mode. For basic mode, enter a title and body. For advanced mode, enter a custom JSON payload.
4. Toggle the "Use Sandbox" switch if you want to use the APNs sandbox environment.
5. Click "Send Push Notification" to send the push notification.

## License
The APNSTester is released under the MIT License. See the LICENSE file for details.
