# Watermark App

Watermark App is a Flutter application for adding visible watermarks to images and PDF documents before sharing them.

The project is designed for lightweight document distribution workflows: choose one or more files, preview the result, adjust watermark settings, then save or share the processed outputs.

Author: Antoine Ginies

## Features

- Add watermarks to images and PDF files
- Process multiple files in one batch
- Preview processed results with swipe navigation
- Adjust watermark text, transparency, color, and density
- Share generated files with available applications
- Resize image output for faster sharing workflows
- Desktop drag-and-drop support on supported platforms

## Supported Inputs

- PNG
- JPG / JPEG
- PDF

## How It Works

1. Enter the watermark text.
2. Pick one or more image or PDF files.
3. Adjust transparency, density, and color settings.
4. Click `Apply Watermark`.
5. Swipe through previews.
6. Save or share the generated files.

## Platforms

This project is built with Flutter and can target multiple platforms, including:

- Linux
- Android
- iOS / iPadOS
- macOS
- Windows
- Web

Platform support depends on your local Flutter toolchain and native SDK setup.

## Development

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

Example for Linux:

```bash
flutter run -d linux
```

Build examples:

```bash
flutter build apk
flutter build appbundle
flutter build ios
```

## Project Goal

The application focuses on fast, practical watermarking for shared documents rather than archival-quality rendering. It favors smaller output size, quicker previews, and simple distribution through save and share actions.

## License

This project is licensed under the GNU General Public License v3.0. See `LICENSE` for details.
