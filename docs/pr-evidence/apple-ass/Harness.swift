import AppKit
import AetherEngine
import Foundation

@main
struct SubtitleHarness {
    @MainActor static func main() async {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let root = URL(fileURLWithPath: CommandLine.arguments[1])
        EngineLog.handler = { print($0) }
        let width: CGFloat = CommandLine.arguments.contains("--4k") ? 1920 : 960
        let height = width * 9 / 16
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: width, height: height), styleMask: [.borderless], backing: .buffered, defer: false)
        window.backgroundColor = NSColor(calibratedRed: 32/255, green: 54/255, blue: 74/255, alpha: 1)
        let view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        window.contentView = view
        window.orderFrontRegardless()
        let wrapper = AetherPlayerWrapper()
        wrapper.attachVideoView(view)
        var config = AetherPlayerWrapper.SourceConfiguration()
        config.externalSubtitles = [ExternalSubtitleTrack(url: root.appendingPathComponent("styled.ass"), name: "Styled fixture", language: "eng"), ExternalSubtitleTrack(url: root.appendingPathComponent("plain.srt"), name: "Plain fixture", language: "eng")]
        wrapper.configureSource(config)
        await wrapper.play(url: root.appendingPathComponent("video.mp4"))
        for _ in 0..<100 {
            if wrapper.subtitleTracks.count >= 2 && wrapper.isPlaying { break }
            try? await Task.sleep(for: .milliseconds(100))
        }
        wrapper.setSubtitleTrack(1)
        try? await Task.sleep(for: .seconds(2))
        wrapper.pause()
        wrapper.subtitleOverlay.layoutSubtreeIfNeeded()
        guard let engine = AetherPlayerWrapper.sharedEngine() else { fatalError("engine unavailable") }
        let bitmap = wrapper.subtitleOverlay.subviews.compactMap { $0 as? NSImageView }.last
        let rendered = bitmap?.isHidden == false && bitmap?.image != nil
        print("fixture: local generated 1920x1080 H264; external ASS")
        print("engine: ASS header=\(engine.sidecarASSHeader != nil), cues=\(engine.subtitleCues.count); styled overlay=\(rendered)")
        if let rep = wrapper.subtitleOverlay.bitmapImageRepForCachingDisplay(in: wrapper.subtitleOverlay.bounds) {
            wrapper.subtitleOverlay.cacheDisplay(in: wrapper.subtitleOverlay.bounds, to: rep)
            try? rep.representation(using: .png, properties: [:])?.write(to: root.appendingPathComponent("capture.png"))
        }
        wrapper.shutdown()
        print(rendered ? "PASS external ASS uses styled renderer" : "FAIL external ASS falls through to plain text")
        exit(rendered ? 0 : 1)
    }
}
