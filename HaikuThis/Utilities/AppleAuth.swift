import SwiftUI
import AuthenticationServices
import Foundation
import FirebaseAuth
import CryptoKit

extension authModel {


	 func randomNonceString(length: Int = 32) -> String {
			precondition(length > 0)
			var randomBytes = [UInt8](repeating: 0, count: length)
			let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
			if errorCode != errSecSuccess {
				 fatalError(
						"Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
				 )
			}

			let charset: [Character] =
			Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

			let nonce = randomBytes.map { byte in
						// Pick a random character from the set, wrapping around if needed.
				 charset[Int(byte) % charset.count]
			}

			return String(nonce)
	 }

	 func sha256(_ input: String) -> String {
			let inputData = Data(input.utf8)
			let hashedData = SHA256.hash(data: inputData)
			let hashString = hashedData.compactMap {
				 String(format: "%02x", $0)
			}.joined()

			return hashString
	 }

	 func loginWithApple(_ authorization: ASAuthorization) {
			if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {

				 guard let nonce else {
						fatalError("Invalid state: A login callback was received, but no login request was sent.")
				 }

				 guard let appleIDToken = appleIDCredential.identityToken else {
						print("❌ Unable to fetch identity token")
						return
				 }

				 guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
						print("❌ Unable to serialize token string from data: \(appleIDToken.debugDescription)")
						return
				 }

				 let credential = OAuthProvider.appleCredential(
						withIDToken: idTokenString,
						rawNonce: nonce,
						fullName: appleIDCredential.fullName
				 )

				 Auth.auth().signIn(with: credential) { (authResult, error) in
						if let error {
							 print("❌ Apple Sign-In error:", error.localizedDescription)
							 return
						}

						guard let user = authResult?.user else {
							 print("❌ Failed to unwrap Firebase user from Apple credential.")
							 return
						}

						DispatchQueue.main.async {
							 self.userSession = user
							 self.isLoading = false
						}
				 }
			}
	 }

}
