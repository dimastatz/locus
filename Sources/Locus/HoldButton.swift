import AppKit
import LocusCore

/// A button that fires only after being held down with the mouse or trackpad
/// for the full duration (PRD-0005).
///
/// - Releasing, dragging off the button, or the window losing key status resets progress to zero.
/// - It never becomes first responder, so Space/Return (and key auto-repeat) can't trigger it.
final class HoldButton: NSView {
    /// Called once the hold completes.
    var onComplete: (() -> Void)?
    /// Called when a hold ends before completing, e.g. a plain click.
    var onInterrupted: (() -> Void)?

    private let title: String
    private var hold: HoldToConfirm
    private var ticker: Timer?
    private var resignKeyObserver: NSObjectProtocol?

    init(title: String, duration: TimeInterval = HoldToConfirm.defaultDuration) {
        self.title = title
        self.hold = HoldToConfirm(duration: duration)
        super.init(frame: .zero)
        setAccessibilityRole(.button)
        setAccessibilityLabel("\(title), hold for \(Int(duration)) seconds")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        ticker?.invalidate()
        if let resignKeyObserver {
            NotificationCenter.default.removeObserver(resignKeyObserver)
        }
    }

    override var intrinsicContentSize: NSSize { NSSize(width: 180, height: 32) }
    override var acceptsFirstResponder: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let resignKeyObserver {
            NotificationCenter.default.removeObserver(resignKeyObserver)
        }
        resignKeyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification, object: window, queue: .main
        ) { [weak self] _ in
            self?.interrupt()
        }
    }

    // MARK: Mouse tracking

    override func mouseDown(with event: NSEvent) {
        hold.press(at: Date())
        let ticker = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in self?.advance() }
        RunLoop.main.add(ticker, forMode: .common)
        self.ticker = ticker
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if !bounds.contains(point) {
            interrupt()
        }
    }

    override func mouseUp(with event: NSEvent) {
        interrupt()
    }

    /// Resets progress if a hold is in progress.
    func interrupt() {
        guard hold.isHolding else { return }
        stopHolding()
        onInterrupted?()
    }

    private func advance() {
        if hold.isComplete(at: Date()) {
            stopHolding()
            onComplete?()
        } else {
            needsDisplay = true
        }
    }

    private func stopHolding() {
        ticker?.invalidate()
        ticker = nil
        hold.reset()
        needsDisplay = true
    }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        let now = Date()
        let shape = NSBezierPath(roundedRect: bounds, xRadius: 7, yRadius: 7)

        NSColor.systemRed.withAlphaComponent(0.15).setFill()
        shape.fill()

        if hold.isHolding {
            NSGraphicsContext.saveGraphicsState()
            shape.addClip()
            var filled = bounds
            filled.size.width *= hold.fraction(at: now)
            NSColor.systemRed.withAlphaComponent(0.55).setFill()
            filled.fill()
            NSGraphicsContext.restoreGraphicsState()
        }

        NSColor.systemRed.setStroke()
        shape.lineWidth = 1
        shape.stroke()

        let label = hold.isHolding ? "Keep holding… \(Int(hold.remaining(at: now).rounded(.up)))s" : title
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .semibold),
            .foregroundColor: NSColor.labelColor,
        ]
        let size = label.size(withAttributes: attributes)
        let origin = NSPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2)
        label.draw(at: origin, withAttributes: attributes)
    }
}
