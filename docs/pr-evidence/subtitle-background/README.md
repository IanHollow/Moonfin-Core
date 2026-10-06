# Synthetic subtitle background comparison

These images support Moonfin-Core PR #1758. They show mpv 0.41 rendering an external SRT track on a generated 1280 × 720 solid-color video. No personal media or server data appears in them.

Both renders use white text, a black outline, and `sub-back-color=#bf000000`. `before.png` uses mpv's default `outline-and-shadow` border style with zero shadow offset. `after.png` uses `background-box` with offset 4, matching the PR's mpv properties. The box covers both caption lines. These are mpv renderer captures, not Moonfin application screenshots.

The test video was generated with:

```sh
ffmpeg -f lavfi -i 'color=c=0x253047:s=1280x720:r=1:d=3' -c:v ffv1 video.mkv
```

mpv used `--vo=image --vo-image-format=png --frames=1 --start=1`, `fixture.srt`, `--sub-font-size=42`, `--sub-border-size=2`, and the property values above. Its log identified the 1280 × 720 FFV1 video and the external SubRip track in both runs, then exited normally after saving the frame.
