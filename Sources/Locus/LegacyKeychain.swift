import Foundation
import Security

/// Cleans up after the password-unlock version of Locus, which stored a password hash
/// in the Keychain. Hold to exit (PRD-0005) needs no secret, so the item is deleted at launch.
enum LegacyKeychain {
    static func removeUnlockPassword() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.dimastatz.locus",
            kSecAttrAccount as String: "unlock-password",
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            NSLog("Locus: couldn't remove the legacy unlock password from the Keychain (\(status))")
        }
    }
}
