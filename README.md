# SecureMark

SecureMark is a professional Flutter application designed to secure documents and images with visible watermarks and advanced invisible steganography before sharing them.

The project is designed for high-security document distribution: choose files, apply multi-layered protection, preview results, and securely share them.

![App Screenshot](app.jpg)

## Features

- **Visible Watermarking**: Add text stamps to images and PDF files with control over transparency, density, and color.
- **Robust Blind Watermarking**: Frequency-domain (DCT) signatures that survive image transformations like resizing and compression.
- **Multi-Layer Steganography**: Simultaneously hide text signatures and entire files within image pixels using independent RGB channels.
- **Advanced QR Codes**: Generate visible QR codes for Metadata (JSON), Website Redirects, or vCard Contact sharing (cross-platform compatible).
- **Anti-AI Protection**: Apply specialized visual noise to disrupt AI model training and unauthorized scraping.
- **Batch Processing**: Secure multiple files in one operation with Isolate-based background processing.
- **File Analyzer**: Built-in tool to detect and extract hidden signatures and files from protected documents.
- **Multilingual support**: Full support for English and French.
- **Log Management**: Integrated log viewer with the ability to export logs for auditing.

## Supported Input Formats

- **PNG** - Lossless compression
- **JPG / JPEG** - With adjustable quality control
- **WebP** - Modern format with quality control
- **HEIC / HEIF** - Native support for modern mobile photo formats
- **PDF** - Vector or rasterized (flattened) processing

## Security & Steganography

SecureMark provides multiple levels of hidden protection:
- **LSB Signature (Blue Channel)**: Classical invisible text signature.
- **Hidden File (Green Channel)**: Embed an entire secondary file (encrypted with AES-256).
- **Robust DCT**: Experimental frequency-domain marking for persistence against lossy compression.

## Font Options

### System Fonts
- Arial (System Default)

### Google Fonts
- Roboto, Open Sans, Lato, Montserrat, Poppins, Noto Sans, Source Code Pro, Playfair Display, Oswald.

### Custom TTF Fonts
Pre-configured support for Charis SIL, Liberation Mono/Serif, and Bitstream Vera Sans. Add your own by placing TTF files in `assets/fonts/`.

## How It Works

1. Enter the watermark text or configure a QR code.
2. Pick files (images or PDFs) or drag and drop them.
3. (Optional) Configure Steganography to hide secret data or files.
4. Adjust visibility settings (Transparency, Density, Font).
5. Click `Apply SecureMark`.
6. Preview the result (with A/B comparison) and verify the hidden signatures.
7. Save or share the protected outputs.

## Expert Settings

- **Anti-AI Level**: Disrupt AI scraping patterns.
- **JPEG/WebP Quality**: Balance file size and protection.
- **Target Size**: Auto-resize for mobile-friendly sharing.
- **File Prefix & Timestamps**: Customize output naming conventions.
- **Rasterization**: Flatten PDFs into images for maximum security.

## Development & Testing

Install dependencies:
```bash
flutter pub get
```

Run the application:
```bash
flutter run
```

Run security & steganography tests:
```bash
flutter test test/unit/steganography_test.dart
```

## Project Goal

SecureMark focuses on providing verifiable proof of ownership and secure distribution for shared documents. It bridges the gap between simple visual watermarking and advanced forensic steganography.

## License

This project is licensed under the GNU General Public License v3.0. See `LICENSE` for details.
