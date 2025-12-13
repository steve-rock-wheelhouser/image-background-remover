# Image Background Remover

A professional desktop application for Linux that automatically removes backgrounds from images using AI.

## Features
- **AI-Powered**: Uses `rembg` (U2-Net) for high-quality background removal.
- **Modern GUI**: Built with PySide6 (Qt) with a dark theme.
- **Format Support**: Supports PNG, JPG, JPEG, BMP, and WEBP.
- **Privacy**: Runs entirely offline on your local machine.

## Installation

### Fedora / RHEL / CentOS
Download the latest `.rpm` release and install:
```bash
sudo dnf install ./remove-background-1.0.0-1.x86_64.rpm
```

### Development Setup
1. Clone the repository.
2. Create a virtual environment:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run the app:
   ```bash
   python remove_background.py
   ```

## Building from Source
To compile a standalone binary and build an RPM package:
```bash
chmod +x build-rpm.sh
./build-rpm.sh
```

## License
GPLv3 - See LICENSE file for details.