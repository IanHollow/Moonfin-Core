# Apple external ASS rendering evidence

These are captures of Moonfin's production Apple subtitle overlay on macOS 27,
using AetherEngine 6.89.1 and libass 0.17.5. The harness compiles the actual shared
Swift files and links the engine's native build products. It plays generated
1920×1080 H.264 video with the supplied invented ASS text, then captures only the
overlay. These are not screenshots of the full Flutter application or an Apple
TV. No commercial content, desktop windows, accounts, or personal data is shown.

- Before: Core `b43363c9b0e4a007bde559b65fe8708c115c1355`, 1920×1080 capture.
- After: Core `e7df07f86c1ec6363dec8fad0bc9803fd24f2362`, 1920×1080 capture.
- UHD: the same fixed renderer at 3840×2160 backing pixels. This checks caption
  canvas scaling; the source remains the generated 1080p file.

The before image loses authored color, italic text, outlines, and top alignment.
The after images use the style header decoded from the external ASS file. The
reviewed log excerpts below describe the synthetic playback only.

## Reproduce the captures

Build the native Apple dependencies using Moonfin's documented macOS build setup.
Pass the build products and the resolved Dovi macOS slice to `build-capture.sh`.
This produces a test executable, without installing or modifying Moonfin.

```sh
bash build-capture.sh "$CHECKOUT" "$APPLE_PRODUCTS" "$DOVI_MACOS_SLICE" "$CAPTURE_BINARY"
mkdir -p "$FIXTURES"
cp styled.ass "$FIXTURES/styled.ass"
printf '1\n00:00:00,000 --> 00:00:12,000\nSynthetic plain caption\n' > "$FIXTURES/plain.srt"
ffmpeg -f lavfi -i 'color=c=0x20364a:s=1920x1080:r=24:d=12' \
  -an -c:v libx264 -preset ultrafast -crf 0 -pix_fmt yuv420p "$FIXTURES/video.mp4"
"$CAPTURE_BINARY" "$FIXTURES"
# capture.png is the HD overlay; compile against the before revision to compare.
"$CAPTURE_BINARY" "$FIXTURES" --4k
# capture.png now contains the UHD overlay.
```

The native regression test generates its own external fixtures and checks actual
rendered color and placement, repeated and rapid track changes, plain SRT,
disable/re-enable, and explicit HD/UHD pixel canvases. It also checks the generated
embedded ASS fixture committed in the test target. The two tests passed on a
physical Apple Silicon Mac through an isolated SwiftPM test module containing the
production Swift files and the pinned engine build products. That module adapts
only the test import and resource-bundle lookup. It does not validate the app's
Xcode resource-copy phase or a physical iOS/tvOS client.

To run the hosted app test target after the normal native setup:

```sh
xcodebuild test -workspace macos/Runner.xcworkspace -scheme Runner \
  -destination 'platform=macOS' -only-testing:RunnerTests/ExternalASSRenderingTests
```

The upstream code failed the external ASS regression with a missing styled
image. The fixed code passed both native tests. No playback profile, bitrate,
server transcode policy, caption preset, or font override is changed by the PR.
