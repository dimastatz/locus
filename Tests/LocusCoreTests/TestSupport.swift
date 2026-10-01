import Foundation
import LocusCore

let start = Date(timeIntervalSinceReferenceDate: 1_000_000)
let xcode = LockTarget(processID: 42, bundleIdentifier: "com.apple.dt.Xcode", appName: "Xcode")
