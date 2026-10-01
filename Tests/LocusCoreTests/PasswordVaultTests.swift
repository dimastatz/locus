import Foundation
import LocusCore
import Testing

struct PasswordVaultTests {
    @Test func noPasswordInitially() {
        let vault = PasswordVault(store: InMemorySecretStore())
        #expect(!vault.hasPassword)
        #expect(!vault.verify(""))
    }

    @Test func rejectsShortPassword() {
        let vault = PasswordVault(store: InMemorySecretStore())
        let short = String(repeating: "a", count: PasswordVault.minimumLength - 1)
        #expect(throws: PasswordError.tooShort(minimum: PasswordVault.minimumLength)) {
            try vault.setPassword(short, confirmation: short)
        }
        #expect(!vault.hasPassword)
    }

    @Test func rejectsMismatchedConfirmation() {
        let vault = PasswordVault(store: InMemorySecretStore())
        #expect(throws: PasswordError.mismatch) {
            try vault.setPassword(longPassword, confirmation: longPassword + "x")
        }
    }

    @Test func verifiesOnlyTheCorrectPassword() throws {
        let vault = try vaultWithPassword()
        #expect(vault.hasPassword)
        #expect(vault.verify(longPassword))
        #expect(!vault.verify(longPassword + " "))
        #expect(!vault.verify(""))
    }

    @Test func neverStoresThePlaintext() throws {
        let store = InMemorySecretStore()
        try PasswordVault(store: store).setPassword(longPassword, confirmation: longPassword)
        let stored = try #require(store.data)
        #expect(stored.range(of: Data(longPassword.utf8)) == nil)
    }

    @Test func saltsEachHash() throws {
        let first = InMemorySecretStore()
        let second = InMemorySecretStore()
        try PasswordVault(store: first).setPassword(longPassword, confirmation: longPassword)
        try PasswordVault(store: second).setPassword(longPassword, confirmation: longPassword)
        #expect(first.data != second.data)
    }

    @Test func treatsCorruptDataAsNoPassword() {
        let store = InMemorySecretStore()
        store.data = Data([1, 2, 3])
        let vault = PasswordVault(store: store)
        #expect(!vault.hasPassword)
        #expect(!vault.verify(longPassword))
    }
}
