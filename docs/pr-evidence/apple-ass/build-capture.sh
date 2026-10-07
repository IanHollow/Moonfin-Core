#!/bin/bash
set -eu
checkout=${1:?Usage: build-capture.sh CHECKOUT APPLE_PRODUCTS DOVI_SLICE OUTPUT_BINARY}
products=${2:?Apple build products directory required}
dovi=${3:?Dovi macOS slice directory required}
output=${4:?Output binary path required}
evidence=$(cd "$(dirname "$0")" && pwd)
source_dir="$checkout/tvos/Runner/Playback/Aether"
frameworks=()
for path in "$products"/AetherLib*.framework; do
 name=${path##*/}; frameworks+=(-framework "${name%.framework}")
done
xcrun swiftc -swift-version 5 -parse-as-library -I "$products" -I "$dovi/Headers" -F "$products" \
 -Xlinker -rpath -Xlinker "$products" \
 -framework Libass -framework Libfreetype -framework Libfribidi -framework Libharfbuzz -framework Libunibreak \
 -framework AppKit -framework AVFoundation -framework AVKit -framework MediaPlayer -framework QuartzCore \
 -framework VideoToolbox -framework AudioToolbox -liconv -lz -lbz2 "${frameworks[@]}" \
 "$products/AetherEngine.o" "$products/AetherFFmpegBuild.o" "$dovi/libdovi.a" \
 "$source_dir/AetherPlayerWrapper.swift" "$source_dir/AssRenderer.swift" "$source_dir/SubtitleOverlay.swift" \
 "$source_dir/SubtitleFontLocator.swift" "$source_dir/PlayerTypes.swift" "$source_dir/NowPlayingController.swift" \
 "$source_dir/EngineTrustPolicy.swift" "$evidence/Harness.swift" -o "$output"
