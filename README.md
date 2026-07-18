<img width="1280" height="839" alt="ezgif com-video-to-gif-converter-2" src="https://github.com/user-attachments/assets/68854394-dd44-45cb-9414-61927d96d100" />

<img width="1280" height="735" alt="ezgif com-video-to-gif-converter" src="https://github.com/user-attachments/assets/e0c56e35-be94-45ec-91f2-e26dd75d3222" />

# TextExtractor

A free, open-source, fully offline text extraction tool for macOS. Drag in an image or PDF, get clean editable text out — no cloud, no API keys, no data ever leaving your Mac.

Built on Apple's on-device Vision framework, so it works in airplane mode and keeps anything you scan completely private.

<!-- Add a screenshot or GIF of the app here before publishing -->
<!-- ![TextExtractor screenshot](docs/screenshot.png) -->

## Features

- **Drag & drop** images or PDFs straight onto the app window
- **Open File** and **Paste from clipboard** (⌘V) as alternatives to dragging
- **Reset button** to clear everything and start fresh with new images
- **Batch mode** — drop multiple files at once, switch between results in a thumbnail strip
- **PDF support** — every page is OCR'd individually, processed one page at a time so even large scanned books don't crash the app or exhaust memory (auto-capped at 50 pages, with a heads-up if a document is longer)
- **Loading indicators** — a clear "Extracting text…" spinner while OCR is running, plus a page-by-page progress bar for PDFs
- **Global quick capture (⌘⇧2)** — select any region of your screen from anywhere on your Mac, text lands on your clipboard in about a second
- **Confidence highlighting** — low-confidence text is color-coded (orange/red) so you know what to double-check
- **ALL CAPS toggle** — instantly uppercase extracted text
- **No-text alert** — a clear popup if a photo was too blurry or had no text, instead of silent failure
- **History** — your last 25 extractions are saved locally and searchable
- **Export** — copy or save as `.txt` / `.md`, single result or combined batch
- **Menu bar app** — lives quietly in your menu bar, no dock window required
- **100% offline** — Vision runs entirely on-device; no network requests, no tracking, no accounts

## Requirements

- macOS 14 Sonoma or later
- Xcode 15+ (to build from source)

## Installation

> This app is currently **unsigned and not notarized** (a signed release requires a paid Apple Developer account, which isn't set up yet). This means macOS Gatekeeper will show a warning the first time you open it — this is normal and expected for free, unsigned indie apps, not a sign anything is wrong.

### Download & Install

1. Download `TextExtractor.pkg` from [Releases](../../releases)
2. Double-click to run the installer
3. Follow the prompts — the app installs directly to Applications
4. First launch: right-click `TextExtractor` → **Open**, then click **Open** on the warning dialog
5. After this first time, you can open it normally

If macOS still blocks it, go to **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to the TextExtractor warning.

### Building from source instead

1. Clone the repo:
   ```bash
   git clone https://github.com/Prathvix/TextExtractor.git
   cd TextExtractor
   ```
2. Open `TextExtractor.xcodeproj` in Xcode
3. In your target's **Signing & Capabilities**, remove **App Sandbox** if present (quick capture shells out to `screencapture`, which needs this)
4. Build and run (⌘R)
5. On first use of the quick capture hotkey (⌘⇧2), macOS will prompt you to grant **Accessibility** permission under **System Settings → Privacy & Security → Accessibility** — enable it and relaunch

## Why offline matters

Everything runs locally using Apple's Vision framework. Nothing you photograph, paste, or capture is ever uploaded anywhere. This makes it well-suited for anything sensitive — personal notes, documents, screenshots of private messages — since there's no server in the loop at all.

## Roadmap

- [ ] Signed & notarized release (removes the Gatekeeper warning for seamless installs)
- [ ] v1.1: Customizable hotkey, auto-copy toggle, text search in history, keyboard shortcuts, settings window
- [ ] v1.2: OCR language selection, image preprocessing, more export formats
- [ ] v2.0: Advanced features (drag text out, regex find/replace, batch operations, iCloud sync)

## Contributing

Issues and pull requests are welcome. This is an early-stage indie project, so feel free to open an issue if something breaks or you have an idea.

## Support

If this tool is useful to you, consider starring the repo — it genuinely helps visibility. 

## License

MIT — see [LICENSE](LICENSE) for details.
