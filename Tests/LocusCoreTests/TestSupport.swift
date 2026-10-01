import Foundation
import LocusCore

final class InMemorySecretStore: SecretStore {
    var data: Data?

    func load() throws -> Data? { data }
    func save(_ data: Data) throws { self.data = data }
}

let longPassword = String(repeating: "focus-", count: 6) // 36 characters
let start = Date(timeIntervalSinceReferenceDate: 1_000_000)
let xcode = LockTarget(processID: 42, bundleIdentifier: "com.apple.dt.Xcode", appName: "Xcode")

func vaultWithPassword() throws -> PasswordVault {
    let vault = PasswordVault(store: InMemorySecretStore())
    try vault.setPassword(longPassword, confirmation: longPassword)
    return vault
}
