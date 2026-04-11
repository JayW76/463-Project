import serial
import wave
import struct

# Configuration
SERIAL_PORT = 'COM3'  # Change to your ESP32 port
BAUD_RATE = 115200
SAMPLE_RATE = 16000
OUTPUT_FILE = "vocal_sample_raw.wav"

ser = serial.Serial(SERIAL_PORT, BAUD_RATE)
print(f"Recording from {SERIAL_PORT}...")

# Create Wave file
with wave.open(OUTPUT_FILE, 'wb') as wav_file:
    wav_file.setnchannels(1)  # Mono
    wav_file.setsampwidth(4) # 32-bit (matches ESP32 I2S config)
    wav_file.setframerate(SAMPLE_RATE)

    try:
        while True:
            # Read line from Serial
            line = ser.readline().decode('utf-8').strip()
            if line:
                try:
                    sample = int(line)
                    # Pack as 32-bit integer
                    wav_file.writeframes(struct.pack('<i', sample))
                except ValueError:
                    continue
    except KeyboardInterrupt:
        print("Recording stopped. File saved.")
        ser.close()