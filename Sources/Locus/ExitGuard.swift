import AppKit
import LocusCore

/// Watches for attempts to leave the locked app during a session (PRD-0003).
///
/// Two layers of defense:
/// - a keyboard event tap that swallows escape shortcuts (⌘Q, ⌘Tab, ⌃⌘F, …) before they act;
/// - workspace notifications that catch what the tap can't, e.g. clicking the Dock or a
///   system-level shortcut the WindowServer handles first.
/// The 1-second session tick in `AppDelegate` is the final fallback.
final class ExitGuard {
    enum Event {
        case appActivated(pid_t)
        case spaceChanged
        case blockedShortcut
        case targetTerminated
    }

    var onEvent: ((Event) -> Void)?

    private let lockedProcessID: pid_t
    private var observers: [NSObjectProtocol] = []
    private var tap: CFMachPort?
    private var tapSource: CFRunLoopSource?

    init(lockedProcessID: pid_t) {
        self.lockedProcessID = lockedProcessID
    }

    deinit { stop() }

    func start() {
        let center = NSWorkspace.shared.notificationCenter
        observers = [
            center.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) {
                [weak self] note in
                guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                    return
                }
                self?.onEvent?(.appActivated(app.processIdentifier))
            },
            center.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) {
                [weak self] _ in
                self?.onEvent?(.spaceChanged)
            },
            center.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) {
                [weak self] note in
                guard let self,
                    let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                    app.processIdentifier == self.lockedProcessID
                else { return }
                self.onEvent?(.targetTerminated)
            },
        ]
        installEventTap()
    }

    func stop() {
        observers.forEach(NSWorkspace.shared.notificationCenter.removeObserver)
        observers = []
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let tapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), tapSource, .commonModes)
        }
        tap = nil
        tapSource = nil
    }

    private func installEventTap() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard
            let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: mask,
                callback: { _, type, event, refcon in
                    guard let refcon else { return Unmanaged.passUnretained(event) }
                    return Unmanaged<ExitGuard>.fromOpaque(refcon).takeUnretainedValue().handle(
                        type: type, event: event)
                },
                userInfo: refcon
            )
        else {
            NSLog("Locus: couldn't create keyboard event tap; relying on workspace notifications")
            return
        }
        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        self.tapSource = source
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        case .keyDown:
            let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            if BlockedShortcuts.isBlocked(keyCode: keyCode, modifiers: KeyModifiers(event.flags)) {
                // Report asynchronously so UI work doesn't run inside the tap callback.
                DispatchQueue.main.async { [weak self] in self?.onEvent?(.blockedShortcut) }
                return nil
            }
        default:
            break
        }
        return Unmanaged.passUnretained(event)
    }
}

private extension KeyModifiers {
    init(_ flags: CGEventFlags) {
        self = []
        if flags.contains(.maskCommand) { insert(.command) }
        if flags.contains(.maskControl) { insert(.control) }
        if flags.contains(.maskAlternate) { insert(.option) }
        if flags.contains(.maskShift) { insert(.shift) }
    }
}
