# Hardware Pin Mapping & Connections
**Project:** Voice-Based Stress Analysis Wearable  
**MCU:** ESP32-S3 (Default Hardware Pins)

## 1. Master Pin Mapping Table
This table defines all connections between the ESP32-S3 and the peripheral modules.

| Peripheral | Component Pin | ESP32-S3 Pin | Signal Type | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **INMP441 Mic** | SCK | **GPIO 14** | I2S Clock | Audio Sampling Timing |
| **INMP441 Mic** | WS | **GPIO 15** | I2S Word Select | Left/Right Channel Select |
| **INMP441 Mic** | SD | **GPIO 16** | I2S Serial Data | Raw Digital Audio Data |
| **INMP441 Mic** | L/R | **GND** | Configuration | Set to GND for Left Channel |
| **DRV2605L** | SDA | **GPIO 8** | I2C Data | Haptic Pattern Commands |
| **DRV2605L** | SCL | **GPIO 9** | I2C Clock | Haptic Bus Timing |
| **DRV2605L** | VIN | **3.3V Out** | Power | Regulated Logic Power |
| **MCP1700 LDO** | Vout | **3.3V / Vin** | Power | System-wide 3.3V Rail |
| **Pancake Motor** | (+) / (-) | **DRV OUT+ / -** | Actuation | Physical Vibration Output |

## 2. Critical Wiring Requirements
To ensure the hardware works correctly, the following details must be handled during assembly:

### I2C Pull-up Resistors (Mandatory)
The ESP32-S3 requires external pull-up resistors for the I2C bus to function correctly:
*   Connect a **10kΩ resistor** between **GPIO 8 (SDA)** and **3.3V**.
*   Connect a **10kΩ resistor** between **GPIO 9 (SCL)** and **3.3V**.

### Power Distribution (Safety)
*   **Voltage Regulation:** The DRV2605L and INMP441 **must** be powered by the **3.3V output** of the MCP1700 LDO. Connecting them directly to the LiPo battery (which can reach 4.2V) may damage the sensitive digital logic pins.
*   **Charging:** The **TP4056 Module** manages the 3.7V LiPo battery. Ensure the battery is disconnected from the circuit while charging via USB-C to prevent voltage spikes.

## 3. Physical Placement Notes
*   **Microphone Isolation:** Mount the INMP441 at the very edge of the perfboard, pointing toward the user's throat for optimal vocal signal capture.
*   **Motor Mounting:** Secure the 10mm Pancake Motor to the housing wall that will be in contact with the skin for immediate haptic alerts.
