import sys
try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Please install Pillow: pip install Pillow")
    sys.exit(1)

def create_mockup():
    # Canvas Setup (Software Center Dark Mode style)
    W, H = 1000, 1100
    bg_color = "#2d2d2d"
    card_color = "#383838"
    text_color = "#ffffff"
    subtext_color = "#bbbbbb"
    accent_color = "#3584e4" # Gnome Blue

    img = Image.new('RGB', (W, H), bg_color)
    draw = ImageDraw.Draw(img)

    # --- Load Fonts (Fallback to default if custom fonts missing) ---
    try:
        # Trying standard Linux paths for clean look
        title_font = ImageFont.truetype("/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf", 36)
        head_font = ImageFont.truetype("/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf", 24)
        body_font = ImageFont.truetype("/usr/share/fonts/dejavu/DejaVuSans.ttf", 18)
        small_font = ImageFont.truetype("/usr/share/fonts/dejavu/DejaVuSans.ttf", 14)
    except:
        # Fallback for minimal envs
        title_font = ImageFont.load_default()
        head_font = ImageFont.load_default()
        body_font = ImageFont.load_default()
        small_font = ImageFont.load_default()

    # --- Header Section ---
    # Icon Placeholder
    draw.rectangle([40, 40, 168, 168], fill="#555555", outline="#000000")
    draw.text((65, 90), "ICON", font=head_font, fill=subtext_color)

    # Title & Dev
    draw.text((200, 50), "Image Background Remover", font=title_font, fill=text_color)
    draw.text((200, 100), "Wheelhouser LLC", font=body_font, fill=subtext_color)
    draw.text((200, 130), "Automatically remove backgrounds from photos and images using on-device AI", font=body_font, fill=subtext_color)

    # Buttons
    draw.rectangle([200, 170, 350, 210], fill=accent_color, outline=None) # Install
    draw.text((245, 180), "INSTALL", font=body_font, fill="#ffffff")
    
    draw.rectangle([370, 170, 520, 210], fill=card_color, outline="#666666") # Website
    draw.text((415, 180), "Website", font=body_font, fill="#ffffff")

    # --- Screenshots Section ---
    y_scroll = 260
    # Hero Image
    draw.rectangle([40, y_scroll, 960, y_scroll+350], fill="#1e1e1e", outline="#444444")
    draw.text((350, y_scroll+170), "Screenshot 1: Main Window (Hero)", font=head_font, fill="#666666")
    
    # Thumbnails
    y_scroll += 370
    draw.rectangle([40, y_scroll, 490, y_scroll+150], fill="#1e1e1e", outline="#444444")
    draw.text((150, y_scroll+70), "Screenshot 2: Batch", font=body_font, fill="#666666")
    
    draw.rectangle([510, y_scroll, 960, y_scroll+150], fill="#1e1e1e", outline="#444444")
    draw.text((600, y_scroll+70), "Screenshot 3: Feathering", font=body_font, fill="#666666")

    # --- Description Section ---
    y_scroll += 190
    draw.text((40, y_scroll), "Image Background Remover is a desktop application for quickly and accurately\nremoving backgrounds from images.", font=body_font, fill=text_color)
    
    y_scroll += 60
    features = [
        "• Automatic subject detection with AI-powered matting",
        "• Supports common image formats: PNG, JPEG, WEBP",
        "• Batch processing and drag-and-drop workflow",
        "• Preserves alpha channel with optional feathering",
        "• Command-line mode for automation"
    ]
    for feat in features:
        draw.text((60, y_scroll), feat, font=body_font, fill=text_color)
        y_scroll += 30

    # --- Details / Footer ---
    y_scroll += 60
    draw.line([40, y_scroll, 960, y_scroll], fill="#555555", width=2)
    y_scroll += 20
    
    # Metadata Grid
    labels = [
        ("Version", "0.1.0"),
        ("License", "GPL-3.0"),
        ("Updated", "2025-12-12"),
        ("Size", "54.2 MB (est)"),
        ("Age Rating", "Safe (0+)"),
        ("Source", "GitHub")
    ]
    
    col_x = 40
    for label, val in labels:
        draw.text((col_x, y_scroll), label, font=small_font, fill=subtext_color)
        draw.text((col_x, y_scroll+20), val, font=body_font, fill=text_color)
        col_x += 160

    # Save
    output_file = "software_center_mockup.png"
    img.save(output_file)
    print(f"Mockup saved to {output_file}")

if __name__ == "__main__":
    create_mockup()