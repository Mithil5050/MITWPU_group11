#!/usr/bin/env python3
"""
Process robot_wave.mp4 frames: remove green background and save as transparent PNGs.
"""

import cv2
import numpy as np
import os
import sys

INPUT = os.path.join(os.path.dirname(__file__), "robot_wave.mp4")
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "robot_frames")

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    cap = cv2.VideoCapture(INPUT)
    if not cap.isOpened():
        print(f"ERROR: Cannot open {INPUT}")
        sys.exit(1)

    total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    print(f"Processing {total} frames for green screen removal...")

    # Define range for green
    # Based on Corner BGR: [ 58 210  48] which is RGB [48, 210, 58]
    # Let's use HSV for better range
    # Green is roughly H=120
    
    frame_idx = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # Convert to HSV
        hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
        
        # Wide range for green keying
        lower_green = np.array([35, 100, 50])
        upper_green = np.array([85, 255, 255])
        
        # Create mask
        mask = cv2.inRange(hsv, lower_green, upper_green)
        
        # Invert mask (robot is 255, background is 0)
        alpha = cv2.bitwise_not(mask)
        
        # Smooth the mask edges slightly
        alpha = cv2.GaussianBlur(alpha, (3, 3), 0)
        
        # Convert BGR -> BGRA
        bgra = cv2.cvtColor(frame, cv2.COLOR_BGR2BGRA)
        bgra[:, :, 3] = alpha

        out_path = os.path.join(OUTPUT_DIR, f"frame_{frame_idx:04d}.png")
        cv2.imwrite(out_path, bgra)

        frame_idx += 1
        if frame_idx % 30 == 0:
            print(f"  Processed {frame_idx}/{total} frames...")

    cap.release()
    print(f"Done! {frame_idx} frames saved to {OUTPUT_DIR}/")

if __name__ == "__main__":
    main()
