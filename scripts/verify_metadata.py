#!/usr/bin/env python3
import os
import xml.etree.ElementTree as ET

def check_file_exists(path, description):
    if os.path.exists(path):
        print(f"[OK] {description} found: {path}")
        return True
    else:
        print(f"[FAIL] {description} NOT found: {path}")
        return False

def verify_setup():
    print("--- Verifying AppStream and Desktop File Setup ---")
    
    # 1. Check Files
    desktop_file = "com.wheelhouser.image-remove-background.desktop"
    metainfo_file = "com.wheelhouser.image-remove-background.metainfo.xml"
    
    if not check_file_exists(desktop_file, "Desktop file"):
        return
    if not check_file_exists(metainfo_file, "Metainfo file"):
        return

    # 2. Analyze Desktop File
    print(f"\nAnalyzing {desktop_file}...")
    icon_name = None
    with open(desktop_file, 'r') as f:
        for line in f:
            if line.startswith("Icon="):
                icon_name = line.strip().split("=")[1]
                print(f"  Found Icon entry: '{icon_name}'")
            if line.startswith("Exec="):
                print(f"  Found Exec entry: '{line.strip().split('=')[1]}'")

    if not icon_name:
        print("[FAIL] No 'Icon=' line found in desktop file.")
    
    # 3. Analyze Metainfo File
    print(f"\nAnalyzing {metainfo_file}...")
    try:
        tree = ET.parse(metainfo_file)
        root = tree.getroot()
        
        # Check ID
        app_id = root.find("id").text
        print(f"  Found AppStream ID: '{app_id}'")
        
        # Check Launchable
        launchable = root.find("launchable")
        if launchable is not None:
            launchable_id = launchable.text
            print(f"  Found Launchable ID: '{launchable_id}'")
            
            if launchable_id != desktop_file:
                print(f"[WARN] Launchable ID '{launchable_id}' does not match filename '{desktop_file}'")
        else:
            print("[FAIL] No <launchable> tag found.")

        # Check Consistency
        expected_id = desktop_file
        if app_id != expected_id:
            print(f"[WARN] AppStream ID '{app_id}' does not match desktop filename '{desktop_file}'.")
            print("       Some Software Centers require exact match (including .desktop suffix).")
        else:
            print("[OK] AppStream ID matches desktop filename.")

    except Exception as e:
        print(f"[FAIL] Failed to parse XML: {e}")

    # 4. Check Icon Assets
    print("\nChecking Icon Assets...")
    #icon_found = False
    # We know the spec renames them, but let's check if the source exists
    if os.path.exists("assets/icons/linux"):
        print("[OK] assets/icons/linux directory exists.")
    else:
        print("[FAIL] assets/icons/linux directory missing.")

    print("\n--- Verification Complete ---")

if __name__ == "__main__":
    verify_setup()
