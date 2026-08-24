import AppKit
import Combine
import SwiftUI

private let dailyGoal = 10

@MainActor
final class CounterStore: ObservableObject {
    @Published private(set) var count = 0

    private let defaults: UserDefaults
    private let countKey = "applyCounter.count"
    private let dayKey = "applyCounter.day"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        rolloverIfNeeded()
    }

    var remaining: Int {
        max(dailyGoal - count, 0)
    }

    var progress: Double {
        min(Double(count) / Double(dailyGoal), 1)
    }

    var motivation: String {
        switch count {
        case 0:
            return "One click starts the streak."
        case 1...2:
            return "Momentum looks good on you."
        case 3...4:
            return "The cats say: keep going."
        case 5:
            return "Halfway there — paws up!"
        case 6...7:
            return "You’re in the home stretch."
        case 8:
            return "Two more. You’ve got this."
        case 9:
            return "Just one more application!"
        case 10:
            return "Goal crushed. Your cats are impressed."
        default:
            return "Bonus application! Absolutely unstoppable."
        }
    }

    func increment() {
        rolloverIfNeeded()
        count += 1
        persist()
    }

    func undo() {
        rolloverIfNeeded()
        count = max(count - 1, 0)
        persist()
    }

    func reset() {
        count = 0
        persist()
    }

    func rolloverIfNeeded(now: Date = Date()) {
        let today = Self.localDayIdentifier(for: now)

        if defaults.string(forKey: dayKey) == today {
            count = max(defaults.integer(forKey: countKey), 0)
        } else {
            count = 0
            defaults.set(today, forKey: dayKey)
            defaults.set(0, forKey: countKey)
        }
    }

    private func persist() {
        defaults.set(Self.localDayIdentifier(for: Date()), forKey: dayKey)
        defaults.set(count, forKey: countKey)
    }

    private static func localDayIdentifier(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}

private struct ApplyCounterView: View {
    @ObservedObject var store: CounterStore
    let hideWindow: () -> Void

    @State private var buttonPressed = false
    @State private var celebrationPulse = false
    @State private var isHovering = false

    private let dayTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(store.count >= dailyGoal ? Color(hex: 0xF5E3D2) : Color(hex: 0xFFF7ED))

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    store.count >= dailyGoal
                        ? Color(hex: 0xD99A62).opacity(0.65)
                        : Color.white.opacity(0.9),
                    lineWidth: 1
                )

            VStack(spacing: 5) {
                petPortrait
                petCounterRow
                petPaws
            }
            .padding(8)

            Button(action: hideWindow) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(Color(hex: 0x715D54))
                    .frame(width: 20, height: 20)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(7)
            .opacity(isHovering ? 0.9 : 0)
            .allowsHitTesting(isHovering)
            .accessibilityLabel("Hide Apply Counter")
        }
        .frame(width: 210, height: 184)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 12, y: 5)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onReceive(dayTimer) { _ in
            store.rolloverIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            store.rolloverIfNeeded()
        }
        .onChange(of: store.count) { _, newValue in
            guard newValue >= dailyGoal else {
                celebrationPulse = false
                return
            }

            withAnimation(.spring(response: 0.45, dampingFraction: 0.48)) {
                celebrationPulse = true
            }
        }
    }

    private var petPortrait: some View {
        Group {
            if let image = Self.catImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(buttonPressed ? 1.012 : 1)
            } else {
                ZStack {
                    Color(hex: 0xF4E9DC)
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color(hex: 0xC88967))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .clipped()
        .background(Color(hex: 0xF4E9DC))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityLabel("Your three cats")
    }

    private var petCounterRow: some View {
        HStack(spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(store.count)")
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0x3E3430))
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("/10")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x91766A))
                    .padding(.bottom, 3)
            }

            Spacer(minLength: 4)

            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.55)) {
                    buttonPressed.toggle()
                    store.increment()
                }
            } label: {
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 35, height: 35)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0xD97852), Color(hex: 0xB85842)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                    .shadow(color: Color(hex: 0x9D4533).opacity(0.2), radius: 5, y: 3)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return, modifiers: [])
            .accessibilityLabel("Log one application")
            .help("Log one application")
        }
        .frame(height: 35)
        .padding(.horizontal, 4)
    }

    private var petPaws: some View {
        HStack(spacing: 4) {
            ForEach(0..<dailyGoal, id: \.self) { index in
                Image(systemName: index < store.count ? "pawprint.fill" : "pawprint")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(
                        index < store.count
                            ? Color(hex: 0xD87852)
                            : Color(hex: 0xBDA89E).opacity(0.6)
                    )
                    .accessibilityHidden(true)
            }
        }
        .frame(height: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(min(store.count, dailyGoal)) of \(dailyGoal)")
    }

    private var header: some View {
        HStack(spacing: 7) {
            VStack(alignment: .leading, spacing: 2) {
                Text("APPLY SPRINT")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(Color(hex: 0x9A5F45))

                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: 0x725E55).opacity(0.8))
            }

            Spacer()

            Text("DAILY GOAL 10")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.45)
                .foregroundStyle(Color(hex: 0x8B6B5D))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.62), in: Capsule())

            Button(action: hideWindow) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: 0x7B6258))
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.58), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Hide counter — use the paw in the menu bar to bring it back")
            .accessibilityLabel("Hide Apply Counter")
        }
    }

    private var catPortrait: some View {
        Group {
            if let image = Self.catImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(hex: 0xF4E9DC)
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(Color(hex: 0xC88967))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 125)
        .clipped()
        .background(Color(hex: 0xF4E9DC))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.9), lineWidth: 1)
        }
        .shadow(color: Color(hex: 0x7F4F39).opacity(0.12), radius: 8, y: 4)
        .accessibilityLabel("An illustration of your three cats")
    }

    private var countSection: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(store.count)")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: 0x3E3430))
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)

                Text("/ 10")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: 0x96776A))
                    .padding(.bottom, 6)
            }

            Text(store.motivation)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0x65524A))
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)

            Text(remainingText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: 0x8D7469).opacity(0.82))
        }
    }

    private var pawProgress: some View {
        HStack(spacing: 6) {
            ForEach(0..<dailyGoal, id: \.self) { index in
                Image(systemName: index < store.count ? "pawprint.fill" : "pawprint")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        index < store.count
                            ? Color(hex: 0xD87852)
                            : Color(hex: 0xBEA99F).opacity(0.62)
                    )
                    .scaleEffect(index < store.count ? 1.05 : 0.92)
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.58).delay(Double(index) * 0.018),
                        value: store.count
                    )
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(min(store.count, dailyGoal)) of \(dailyGoal) daily applications complete")
    }

    private var applyButton: some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                buttonPressed.toggle()
                store.increment()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .bold))

                Text("I APPLIED")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .tracking(0.7)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0xD97852), Color(hex: 0xB85842)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
            }
            .shadow(color: Color(hex: 0x9D4533).opacity(0.26), radius: 8, y: 5)
            .scaleEffect(buttonPressed ? 1.0 : 0.985)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.return, modifiers: [])
        .accessibilityLabel("Add one application")
        .help("Add one application — Return")
    }

    private var footerControls: some View {
        HStack {
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    store.undo()
                }
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(store.count == 0)
            .keyboardShortcut("z", modifiers: .command)

            Spacer()

            Label("Resets every day", systemImage: "sunrise.fill")
                .foregroundStyle(Color(hex: 0x92796D).opacity(0.8))

            Spacer()

            Button("Reset") {
                withAnimation(.easeOut(duration: 0.2)) {
                    store.reset()
                }
            }
            .disabled(store.count == 0)
        }
        .buttonStyle(.borderless)
        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
        .foregroundStyle(Color(hex: 0x80675D))
    }

    private var celebrationSparkles: some View {
        ZStack {
            sparkle(x: -115, y: -54, size: 12, delay: 0.0)
            sparkle(x: 115, y: -70, size: 14, delay: 0.08)
            sparkle(x: -110, y: 63, size: 9, delay: 0.14)
            sparkle(x: 110, y: 72, size: 10, delay: 0.2)
        }
    }

    private func sparkle(x: CGFloat, y: CGFloat, size: CGFloat, delay: Double) -> some View {
        Image(systemName: "sparkles")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(Color(hex: 0xE5A73B))
            .offset(x: x, y: y)
            .scaleEffect(celebrationPulse ? 1.1 : 0.4)
            .opacity(celebrationPulse ? 1 : 0.35)
            .animation(
                .easeInOut(duration: 0.75).repeatForever(autoreverses: true).delay(delay),
                value: celebrationPulse
            )
    }

    private var remainingText: String {
        if store.remaining == 0 {
            return store.count == dailyGoal
                ? "Today’s goal is complete"
                : "\(store.count - dailyGoal) bonus \((store.count - dailyGoal) == 1 ? "application" : "applications")"
        }

        return "\(store.remaining) \(store.remaining == 1 ? "application" : "applications") to today’s goal"
    }

    private static let catImage: NSImage? = {
        guard let url = Bundle.main.url(forResource: "cat-trio-cream", withExtension: "png") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }()
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let store = CounterStore()
    private var window: NSWindow?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configureWindow()
        showCounter()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    @objc private func showCounter() {
        store.rolloverIfNeeded()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func logApplication() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.58)) {
            store.increment()
        }
        showCounter()
    }

    @objc private func resetToday() {
        store.reset()
        showCounter()
    }

    @objc private func undoApplication() {
        store.undo()
        showCounter()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "pawprint.fill",
            accessibilityDescription: "Apply Counter"
        )
        item.button?.toolTip = "Apply Counter"

        let menu = NSMenu()
        menu.addItem(withTitle: "Show Apply Counter", action: #selector(showCounter), keyEquivalent: "")
        menu.addItem(withTitle: "Log an Application", action: #selector(logApplication), keyEquivalent: "\r")
        menu.addItem(withTitle: "Undo Last", action: #selector(undoApplication), keyEquivalent: "z")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Reset Today", action: #selector(resetToday), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Apply Counter", action: #selector(quitApp), keyEquivalent: "q")
        menu.items.forEach { $0.target = self }

        item.menu = menu
        statusItem = item
    }

    private func configureWindow() {
        let size = NSSize(width: 210, height: 184)
        let newWindow = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .fullSizeContentView, .closable],
            backing: .buffered,
            defer: false
        )

        newWindow.title = "Apply Counter"
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.hasShadow = true
        newWindow.isMovableByWindowBackground = true
        newWindow.isReleasedWhenClosed = false
        newWindow.level = .floating
        newWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newWindow.delegate = self
        newWindow.standardWindowButton(.closeButton)?.isHidden = true
        newWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        newWindow.standardWindowButton(.zoomButton)?.isHidden = true
        newWindow.contentView = NSHostingView(
            rootView: ApplyCounterView(store: store) { [weak newWindow] in
                newWindow?.orderOut(nil)
            }
        )
        newWindow.setContentSize(size)

        let frameWasRestored = newWindow.setFrameUsingName("ApplyCounterPetWindow", force: false)
        if !frameWasRestored, let visibleFrame = NSScreen.main?.visibleFrame {
            let origin = NSPoint(
                x: visibleFrame.maxX - size.width - 24,
                y: visibleFrame.maxY - size.height - 24
            )
            newWindow.setFrameOrigin(origin)
        }
        newWindow.setFrameAutosaveName("ApplyCounterPetWindow")

        window = newWindow
    }
}

private extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

@main
struct ApplyCounterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
