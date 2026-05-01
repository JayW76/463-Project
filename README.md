
***

# EGEC 463: Voice-Based Stress Analysis (Group 6)
**Author:** Willie Jarin

## 1. Project Overview
This project features a neck-worn wearable capable of detecting physiological stress through vocal micro-tremors—specifically **Jitter** (frequency variation) and **Shimmer** (amplitude variation). 

The system operates as a **Real-Time Closed-Loop**:
1. **Stage 1 (Capture):** ESP32-S3 captures audio via I2S and streams raw binary data at **921,600 Baud**.
2. **Stage 2 (Bridge):** A Python script encapsulates the high-speed stream into a `.wav` file locally.
3. **Stage 3 (Analysis):** A MATLAB engine extracts biomarkers, visualizes data, and executes detection logic.
4. **Stage 4 (Feedback):** A haptic command is pushed back to the wearable to trigger a vibration alert.

---

## 2. Hardware Specifications & BOM

### Unified Wiring Key
| Component | Signal Type | ESP32-S3 Pin | Purpose |
| :--- | :--- | :--- | :--- |
| **INMP441 Mic** | **I2S (Digital Audio)** | GPIO 14, 15, 16 | Captures vocal biomarkers. |
| **DRV2605L Driver** | **I2C (Control)** | GPIO 8, 9 | Controls haptic feedback (Req. 10k Pull-ups). |
| **MCP1700 LDO** | **Power** | 3.3V Out | Regulates battery to steady 3.3V. |
| **TP4056 Module** | **Power** | LiPo & USB-C | Safely charges the 3.7V battery. |

### Bill of Materials (Total Cost: $73.86)
| Item | Manufacturer/Description | Cost |
| :--- | :--- | :--- |
| **Main MCU** | Espressif ESP32-S3-DevKitC-1 | $15.00 |
| **MEMS Mic** | INMP441 Breakout Board | $6.99 |
| **Haptic Driver** | TI DRV2605L Breakout | $7.95 |
| **Power** | 3.7V 1000mAh LiPo & TP4056 Charger | $16.48 |
| **Connectivity** | 22AWG Wire / 10k Resistors / Perfboard | $18.95 |

---

## 3. Firmware: ESP32-S3 (`EGEC463_ProjectIno.cpp`)
*Configured for 16kHz/32-bit I2S acquisition and I2C haptic control.*

```cpp
#include <driver/i2s.h>
#include <Wire.h>
#include "Adafruit_DRV2605.h"

#define I2S_WS 15
#define I2S_SD 16
#define I2S_SCK 14
#define I2S_PORT I2S_NUM_0
#define BUFFER_LEN 512
#define I2C_SDA 8
#define I2C_SCL 9

Adafruit_DRV2605 drv;

void setup() {
  Serial.begin(921600); // High-speed binary link
  Wire.begin(I2C_SDA, I2C_SCL);
  if (drv.begin()) {
    drv.selectLibrary(1);
    drv.setMode(DRV2605_MODE_INTTRIG);
  }

  const i2s_config_t i2s_config = {
    .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX),
    .sample_rate = 16000,
    .bits_per_sample = I2S_BITS_PER_SAMPLE_32BIT,
    .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT,
    .communication_format = I2S_COMM_FORMAT_STAND_I2S,
    .dma_buf_count = 8,
    .dma_buf_len = BUFFER_LEN
  };

  const i2s_pin_config_t pin_config = {
    .bck_io_num = I2S_SCK, .ws_io_num = I2S_WS, .data_out_num = -1, .data_in_num = I2S_SD
  };

  i2s_driver_install(I2S_PORT, &i2s_config, 0, NULL);
  i2s_set_pin(I2S_PORT, &pin_config);
}

void loop() {
  int32_t samples[BUFFER_LEN];
  size_t bytes_read = 0;
  i2s_read(I2S_PORT, samples, sizeof(samples), &bytes_read, portMAX_DELAY);

  if (bytes_read > 0) {
    // Corrected to Binary Write for high-speed DSP sync
    Serial.write((uint8_t*)samples, bytes_read); 
  }

  if (Serial.available() > 0) {
    if (Serial.read() == 'S') { // Stress command from MATLAB
      drv.setWaveform(0, 47); drv.setWaveform(1, 0); drv.go();
    }
  }
}
```

---

## 4. Serial Bridge: Python (`logger.py`)
*Acts as a secure intermediary for local file generation.*

```python
import serial
import wave

PORT = 'COM4'      # Update to your ESP32 port
BAUD = 921600      
FS = 16000         
DURATION = 5       
FILENAME = "vocal_sample_raw.wav"

try:
    ser = serial.Serial(PORT, BAUD, timeout=2)
    ser.flushInput()
    print(f"READY: Recording {DURATION}s window...")
    raw_data = ser.read(FS * DURATION * 4) 
    
    with wave.open(FILENAME, 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(4) # 32-bit
        wf.setframerate(FS)
        wf.writeframes(raw_data)
    print("DONE: File saved.")
    ser.close()
except Exception as e:
    print(f"ERROR: {e}")
```

---

## 5. DSP Analysis: MATLAB (`JitterShimmer.m`)
*Extracts F0 and Amplitude Envelope to determine stress states.*

```matlab
[audio, fs] = audioread('vocal_sample_raw.wav');
bpFilter = designfilt('bandpassiir', 'FilterOrder', 8, ...
    'HalfPowerFrequency1', 300, 'HalfPowerFrequency2', 3000, 'SampleRate', fs);
cleanAudio = filter(bpFilter, audio);

[f0, f0_idx] = pitch(cleanAudio, fs);
upperEnv = envelope(cleanAudio, 100, 'rms');

jitter = mean(abs(diff(f0)), 'omitnan') / mean(f0, 'omitnan');
shimmer = mean(abs(diff(upperEnv))) / mean(upperEnv);

if jitter > 0.02 || shimmer > 0.15
    write(serialport('COM4', 921600), 'S', "char"); % Matches logger.py port
    statusStr = 'STRESS DETECTED';
else
    statusStr = 'CALM';
end
```

---

## 6. Regulatory Note & References
This device is a **Wellness Device** intended for stress awareness, following **FDA Guidance [4]**. It is not intended for medical diagnosis.

**References (IEEE):**
*   **[1]** Espressif Systems, "ESP32-S3 Technical Reference Manual," 2022.
*   **[2]** InvenSense, "INMP441 Digital MEMS Microphone," 2014.
*   **[3]** P. Boersma, "Praat, a system for doing phonetics by computer," 2001.
*   **[4]** FDA, "General Wellness: Policy for Low Risk Devices," 2019.
*   **[5]** A. Teixeira et al., "Vocal Acoustic Markers for Stress," *IEEE JBHI*, 2021.


---


---

## 7. Hardware & Wiring Specifications

### Comparison: Python vs MATLAB
| Feature | Python Logger | MATLAB Analysis |
| :--- | :--- | :--- |
| **Primary Use** | **Data Acquisition**: Captures and saves raw audio data. | **Signal Processing**: Extracts biomarkers and analyzes stress. |
| **Real-Time Ability** | Excellent for streaming high-speed serial data. | Better for batch processing or deep statistical analysis. |
| **Hardware Link** | Talks directly to the USB-C port. | Processes files generated by Python or local buffers. |

### I2C Pin Mapping (DRV2605L to ESP32-S3)
| DRV2605L Pin | ESP32-S3 Pin | Purpose |
| :--- | :--- | :--- |
| **VIN** | **3.3V** | Power (LDO/Battery) |
| **GND** | **GND** | Common Ground |
| **SCL** | **GPIO 9** | I2C Clock |
| **SDA** | **GPIO 8** | I2C Data |

### Unified Wiring Schematic
| Component | Signal Type | ESP32-S3 Pin | Purpose |
| :--- | :--- | :--- | :--- |
| **INMP441 Mic** | **I2S (Digital Audio)** | GPIO 14, 15, 16 | Captures vocal biomarkers. |
| **DRV2605L Driver** | **I2C (Control)** | GPIO 8, 9 | Controls haptic feedback. |
| **MCP1700 LDO** | **Power** | 3.3V Out | Regulates battery to steady 3.3V. |
| **TP4056 Module** | **Power** | LiPo & USB-C | Safely charges the 3.7V battery. |

### Critical Wiring Requirements
*   **Pull-up Resistors**: Connect **10kΩ resistors** between the SDA/SCL lines and 3.3V. Without these, the I2C bus will float.
*   **Voltage Consistency**: Ensure the DRV2605L is powered by the **3.3V LDO**, not raw battery voltage.
*   **Microphone Isolation**: Mount the INMP441 near the edge of the board, pointing toward the user's throat.
*   **Short Data Lines**: Keep I2S and I2C wiring as short as possible to prevent ambient noise interference.
Since I am an AI, I cannot provide a `.jpg` or `.png` file directly, but I can provide you with a **Mermaid.js diagram**. 


---
### 8. The Visual Diagram (Mermaid Code)



```mermaid
graph TD
    %% Power Section
    subgraph Power_System [Power Management]
        Battery[3.7V LiPo Battery] --> TP4056[TP4056 Charger / USB-C]
        TP4056 --> MCP1700[MCP1700 3.3V LDO]
        MCP1700 --> VCC_Rail[3.3V Power Rail]
        GND[Common Ground]
    end

    %% ESP32-S3 Connections
    subgraph MCU [ESP32-S3]
        GPIO14[GPIO 14 - SCK]
        GPIO15[GPIO 15 - WS]
        GPIO16[GPIO 16 - SD]
        GPIO8[GPIO 8 - SDA]
        GPIO9[GPIO 9 - SCL]
        MCU_VCC[3.3V / Vin]
        MCU_GND[GND]
    end

    %% Microphone Connections
    subgraph Audio_Input [INMP441 Microphone]
        MIC_SCK[SCK]
        MIC_WS[WS]
        MIC_SD[SD]
        MIC_L/R[L/R - GND]
        MIC_VCC[VDD - 3.3V]
    end

    %% Haptic Connections
    subgraph Haptic_Output [DRV2605L & Motor]
        DRV_SDA[SDA]
        DRV_SCL[SCL]
        DRV_VCC[VIN - 3.3V]
        Vib_Motor[10mm Pancake Motor]
    end

    %% Wiring Logic
    VCC_Rail --- MCU_VCC
    VCC_Rail --- MIC_VCC
    VCC_Rail --- DRV_VCC
    
    GND --- MCU_GND
    GND --- MIC_L/R
    
    %% Signal Wiring
    GPIO14 --- MIC_SCK
    GPIO15 --- MIC_WS
    GPIO16 --- MIC_SD
    
    GPIO8 --- DRV_SDA
    GPIO9 --- DRV_SCL
    
    %% Pull-up Resistors
    R1[10k Pull-up] --- GPIO8
    R1 --- VCC_Rail
    R2[10k Pull-up] --- GPIO9
    R2 --- VCC_Rail

    DRV_SDA --- Vib_Motor
```

---

### 9. Detailed Wiring Table (For Assembly)

If you are giving this to (Integration) for soldering, this table is the "Master Key":

| From Component | Pin | To Component | Pin | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Battery** | Positive (+) | **TP4056** | B+ | |
| **Battery** | Negative (-) | **TP4056** | B- | |
| **TP4056** | OUT+ | **MCP1700** | Vin | |
| **MCP1700** | Vout | **3.3V Rail** | -- | Powers ESP32, Mic, and Driver |
| **INMP441** | VDD | **3.3V Rail** | -- | |
| **INMP441** | GND / L/R | **Ground Rail** | -- | Connect L/R to GND for Left Channel |
| **INMP441** | SCK | **ESP32-S3** | GPIO 14 | I2S Clock |
| **INMP441** | WS | **ESP32-S3** | GPIO 15 | I2S Word Select |
| **INMP441** | SD | **ESP32-S3** | GPIO 16 | I2S Serial Data |
| **DRV2605L** | VIN | **3.3V Rail** | -- | |
| **DRV2605L** | GND | **Ground Rail** | -- | |
| **DRV2605L** | SDA | **ESP32-S3** | GPIO 8 | **Requires 10kΩ Pull-up to 3.3V** |
| **DRV2605L** | SCL | **ESP32-S3** | GPIO 9 | **Requires 10kΩ Pull-up to 3.3V** |
| **DRV2605L** | OUT+ / - | **Pancake Motor** | Red / Blue | |

---

### 10. Assembly Tips for the Team:

1.  **I2C Pull-ups (Critical):** Do not skip the **10kΩ resistors**. Connect one end of a resistor to **GPIO 8 (SDA)** and the other end to **3.3V**. Do the same for **GPIO 9 (SCL)**. Without these, the ESP32 will "hang" when trying to talk to the haptic motor.
2.  **Star Grounding:** Ensure all "GND" pins meet at a single point (the TP4056 OUT- or MCP1700 GND pin) to reduce electrical noise in the audio signal.
3.  **LDO Placement:** The **MCP1700** is sensitive to heat. Solder it last, and ensure it is not touching the battery or the ESP32-S3 (both of which get warm).
4.  **Wire Length:** Keep the 3 wires going to the **INMP441 Microphone** (SCK, WS, SD) as short as possible. I2S signals are high-speed and can pick up "hum" if the wires are too long.
