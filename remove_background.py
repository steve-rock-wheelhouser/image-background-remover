#!/usr/bin/python3
# -*- coding: utf-8 -*-
# This script resizes an image using a graphical user interface and saves it as a PNG.
# It supports PNG, JPG, JPEG, TIFF, WEBP, AVIF, PDF, SVG, and BMP input formats.
# For PDF support, the 'poppler' library must be installed on the system.
# It uses the Pillow library for image processing and PySide6 for the GUI.
#
#
# Copyright (C) 2025 steve.rock@wheelhouser.com
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# --- Setup Instructions ---
# 1. Set up the virtual environment:
#    python3 -m venv .venv
#    source .venv/bin/activate
#    pip install --upgrade pip
#    pip install -r requirements.txt
# 
# 1. On Windows, activate the virtual environment with:
#   python3 -m venv .venv
#   .\.venv\Scripts\Activate.ps1
#   python.exe -m pip install --upgrade pip
#   pip install -r requirements.txt
#
#===========================================================================================

import os
import sys

from rembg import remove
from PIL import Image
import io
from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                               QHBoxLayout, QPushButton, QLabel, QFileDialog, 
                               QMessageBox, QSizePolicy)
from PySide6.QtGui import QPixmap, QImage, QFont, QIcon
from PySide6.QtCore import Qt

#============================================================================================
#--- Helper Functions ---
#============================================================================================
def resource_path(relative_path):
    """ Get absolute path to resource, works for dev and for PyInstaller """
    if hasattr(sys, '_MEIPASS'):
        return os.path.join(sys._MEIPASS, relative_path)
    
    # For py2app, the resources are in a 'Resources' directory
    if 'py2app' in sys.argv:
        return os.path.join(os.path.dirname(sys.executable), '..', 'Resources', relative_path)

    return os.path.join(os.path.dirname(os.path.abspath(__file__)), relative_path)

#============================================================================================
#--- Background Remover Class ---
#============================================================================================
class BackgroundRemoverApp(QMainWindow):
    def __init__(self):
        super().__init__()

        # Window setup
        self.setWindowTitle("Image Background Remover")
        self.setWindowIcon(QIcon(resource_path("assets/icons/icon.ico")))
        self.resize(900, 600)

        # Apply Dark Theme
        self.setStyleSheet("""
            QWidget {
                background-color: #1e1e1e;
                color: #ffffff;
            }
            QPushButton {
                background-color: #323232;
                border: 1px solid #555;
                border-radius: 4px;
                padding: 6px;
                icon-size: 0px;
            }
            QPushButton:hover {
                background-color: #424242;
                border: 1px solid #007AFF;
            }
            QPushButton:disabled {
                background-color: #1e1e1e;
                color: #555;
                border: 1px solid #333;
            }
            QPushButton#aboutButton {
                background-color: transparent;
                border: none;
                padding: 4px 8px;
                color: #00BFFF;
            }
            QPushButton#aboutButton:hover {
                background-color: #444444;
                border: none;
                border-radius: 4px;
            }
            QPushButton#aboutButton:pressed {
                background-color: #333333;
                border: none;
            }
        """)

        # Variables
        self.original_image = None
        self.processed_image = None
        self.file_path = None
        self.last_opened_dir = os.path.expanduser("~/Pictures")

        self._setup_ui()

    def _setup_ui(self):
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)

        # --- Header Section ---
        header_layout = QHBoxLayout()
        
        self.btn_load = QPushButton("Select Image")
        self.btn_load.clicked.connect(self.load_image)
        header_layout.addWidget(self.btn_load)

        header_layout.addStretch()

        self.btn_process = QPushButton("Remove Background")
        self.btn_process.clicked.connect(self.process_image)
        self.btn_process.setEnabled(False)
        header_layout.addWidget(self.btn_process)

        self.btn_save = QPushButton("Save Result")
        self.btn_save.clicked.connect(self.save_image)
        self.btn_save.setEnabled(False)
        header_layout.addWidget(self.btn_save)

        about_button = QPushButton("About")
        about_button.setObjectName("aboutButton")
        about_button.clicked.connect(self.show_about_dialog)
        header_layout.addWidget(about_button)

        main_layout.addLayout(header_layout)

        # --- Image Display Section ---
        image_layout = QHBoxLayout()

        # Left side: Original
        left_layout = QVBoxLayout()
        lbl_left_title = QLabel("Original Image")
        lbl_left_title.setAlignment(Qt.AlignCenter)
        lbl_left_title.setFont(QFont("Arial", 12, QFont.Bold))
        left_layout.addWidget(lbl_left_title)

        self.lbl_original_img = QLabel("No Image Loaded")
        self.lbl_original_img.setAlignment(Qt.AlignCenter)
        self.lbl_original_img.setStyleSheet("border: 1px solid #444; background-color: #252525; color: #888;")
        self.lbl_original_img.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        left_layout.addWidget(self.lbl_original_img)
        
        image_layout.addLayout(left_layout)

        # Right side: Processed
        right_layout = QVBoxLayout()
        lbl_right_title = QLabel("Background Removed")
        lbl_right_title.setAlignment(Qt.AlignCenter)
        lbl_right_title.setFont(QFont("Arial", 12, QFont.Bold))
        right_layout.addWidget(lbl_right_title)

        self.lbl_processed_img = QLabel("")
        self.lbl_processed_img.setAlignment(Qt.AlignCenter)
        self.lbl_processed_img.setStyleSheet("border: 1px solid #444; background-color: #252525; color: #888;")
        self.lbl_processed_img.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        right_layout.addWidget(self.lbl_processed_img)

        image_layout.addLayout(right_layout)
        main_layout.addLayout(image_layout)

        # Status Bar
        self.lbl_status = QLabel("Ready")
        self.statusBar().addWidget(self.lbl_status)

    def load_image(self):
        file_path, _ = QFileDialog.getOpenFileName(
            self, "Open Image", self.last_opened_dir, "Images (*.png *.jpg *.jpeg *.bmp *.webp)"
        )
        if not file_path:
            return

        self.file_path = file_path
        self.last_opened_dir = os.path.dirname(file_path)
        try:
            self.original_image = Image.open(file_path)
            
            # Reset processed image
            self.processed_image = None
            self.lbl_processed_img.clear()
            self.lbl_processed_img.setText("")
            self.btn_save.setEnabled(False)
            
            # Update Preview
            self.display_image(self.original_image, self.lbl_original_img)
            self.btn_process.setEnabled(True)
            self.lbl_status.setText(f"Loaded: {os.path.basename(file_path)}")
            
        except Exception as e:
            QMessageBox.critical(self, "Error", f"Failed to load image: {e}")

    def process_image(self):
        if not self.original_image:
            return
        
        self.lbl_status.setText("Processing... This may take a moment.")
        QApplication.processEvents() # Force UI update before heavy processing

        try:
            # REMBG Processing
            # Convert PIL image to bytes for rembg
            img_byte_arr = io.BytesIO()
            self.original_image.save(img_byte_arr, format='PNG')
            img_byte_arr = img_byte_arr.getvalue()

            # The magic happens here
            output_data = remove(img_byte_arr)

            # Convert back to PIL Image
            self.processed_image = Image.open(io.BytesIO(output_data))

            # Display result
            self.display_image(self.processed_image, self.lbl_processed_img)
            
            self.btn_save.setEnabled(True)
            self.lbl_status.setText("Background removal complete.")

        except Exception as e:
            self.lbl_status.setText("Error occurred.")
            QMessageBox.critical(self, "Error", f"Processing failed: {e}")

    def display_image(self, pil_image, label_widget):
        # Resize image to fit the label while maintaining aspect ratio
        w_box = label_widget.width()
        h_box = label_widget.height()
        
        # Fallback if window hasn't drawn yet
        if w_box < 10 or h_box < 10: 
            w_box, h_box = 400, 400

        # Create copy to resize
        img_copy = pil_image.copy()
        img_copy.thumbnail((w_box, h_box))
        
        # Convert PIL to QPixmap
        # Ensure image is in a format QImage likes (RGBA is safest)
        if img_copy.mode != "RGBA":
            img_copy = img_copy.convert("RGBA")
            
        data = img_copy.tobytes("raw", "RGBA")
        qim = QImage(data, img_copy.size[0], img_copy.size[1], QImage.Format_RGBA8888)
        pixmap = QPixmap.fromImage(qim)
        
        label_widget.setPixmap(pixmap)

    def save_image(self):
        if not self.processed_image:
            return

        initial_dir = os.path.dirname(self.file_path) if self.file_path else os.path.expanduser("~/Pictures")

        if self.file_path:
            base_name = os.path.splitext(os.path.basename(self.file_path))[0]
            default_filename = f"{base_name}-bg.png"
            initial_path = os.path.join(initial_dir, default_filename)
        else:
            initial_path = initial_dir

        save_path, _ = QFileDialog.getSaveFileName(
            self, "Save Image", initial_path, "PNG Image (*.png)"
        )
        
        if save_path:
            if not save_path.lower().endswith(".png"):
                save_path += ".png"
                
            try:
                self.processed_image.save(save_path)
                QMessageBox.information(self, "Success", "Image saved successfully!")
                self.lbl_status.setText(f"Saved to: {save_path}")
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Failed to save image: {e}")

    def show_about_dialog(self):
        """Shows the about dialog."""
        about_dlg = QMessageBox(self)
        about_dlg.setWindowTitle("About Image Background Remover")

        # Set the icon
        icon_path = resource_path("assets/icons/icon.ico")
        pixmap = QPixmap(icon_path)
        if not pixmap.isNull():
            about_dlg.setIconPixmap(pixmap.scaled(128, 128, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation))

        about_dlg.setTextFormat(Qt.TextFormat.RichText) # to allow HTML link
        about_dlg.setText("<h3>Image Background Remover</h3>")
        about_dlg.setInformativeText(
            "<div style='font-size: 1.5em;'>"
            "A simple tool to remove backgrounds from images.<br><br>"
            "<span style='color: #00BFFF;'>"
            "Version 1.0.0<br>"
            "Current support for: png, jpg, jpeg, bmp, and webp file formats.<br>"
            "</span><br>"
            "© 2025 Wheelhouser LLC<br>"
            "Visit our website to see what else we have to offer: <a href='https://wheelhouser.com' style='color: #00BFFF;'>wheelhouser.com</a>"
            "</div>"
        )
        about_dlg.setStandardButtons(QMessageBox.StandardButton.Ok)
        about_dlg.exec()

#============================================================================================
#--- Main Application Entry Point ---
#============================================================================================
if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = BackgroundRemoverApp()
    window.show()
    sys.exit(app.exec())