import serial
import wave
import os

# --- SETTINGS ---
PORT = 'COM4'      # <--- DOUBLE CHECK THIS (e.g., COM3, COM4)
BAUD = 921600      # Matches the corrected ESP32 code
FS = 16000         # 16kHz
DURATION = 5       # Seconds to record
FILENAME = "vocal_sample_raw.wav"

print(f"Current Folder: {os.getcwd()}") # This tells you where the file will be
print(f"Connecting to {PORT}...")

try:
    ser = serial.Serial(PORT, BAUD, timeout=2)
    ser.flushInput()
    
    # Calculate bytes: 16000 samples/sec * 5 sec * 4 bytes per sample (32-bit)
    total_bytes = FS * DURATION * 4
    
    print(f"READY! Speak into the mic now for {DURATION} seconds...")
    raw_data = ser.read(total_bytes)
    
    print("Recording finished. Saving file...")
    
    with wave.open(FILENAME, 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(4) # 32-bit
        wf.setframerate(FS)
        wf.writeframes(raw_data)

    print(f"DONE! File '{FILENAME}' is now in your folder.")
    ser.close()

except Exception as e:
    print(f"ERROR: {e}")