import CryptoKit
import Foundation

/// Persists the unlock-password hash. The app backs this with the Keychain.
public protocol SecretStore: AnyObject {
    func load() throws -> Data?
    func save(_ data: Data) throws
}

public enum PasswordError: Error, Equatable {
    case tooShort(minimum: Int)
    case mismatch
}

/// Sets and verifies the unlock password. Stores only `salt + SHA256(salt + password)`,
/// never the password itself (PRD-0003).
public final class PasswordVault {
    public static let minimumLength = 32
    private static let saltLength = 16
    private static let storedLength = saltLength + SHA256.byteCount

    private let store: SecretStore

    public init(store: SecretStore) {
        self.store = store
    }

    public var hasPassword: Bool {
        storedHash() != nil
    }

    public func setPassword(_ password: String, confirmation: String) throws {
        guard password.count >= Self.minimumLength else {
            throw PasswordError.tooShort(minimum: Self.minimumLength)
        }
        guard password == confirmation else { throw PasswordError.mismatch }
        var generator = SystemRandomNumberGenerator()
        let salt = Data((0..<Self.saltLength).map { _ in UInt8.random(in: .min ... .max, using: &generator) })
        try store.save(salt + Self.digest(password, salt: salt))
    }

    public func verify(_ password: String) -> Bool {
        guard let stored = storedHash() else { return false }
        let salt = stored.prefix(Self.saltLength)
        let expected = stored.suffix(SHA256.byteCount)
        let actual = Self.digest(password, salt: Data(salt))
        // Constant-time comparison; both sides are SHA256.byteCount long.
        return zip(actual, expected).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }

    private func storedHash() -> Data? {
        guard let data = try? store.load(), data.count == Self.storedLength else { return nil }
        return data
    }

    private static func digest(_ password: String, salt: Data) -> Data {
        Data(SHA256.hash(data: salt + Data(password.utf8)))
    }
}
