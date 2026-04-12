# Hardware Wiring Diagram & Pinout
**Project:** Voice-Based Stress Analysis Wearable
**Hardware:** ESP32-S3, INMP441 Mic, DRV2605L Haptic Driver

## 1. Unified Wiring Diagram
This diagram shows the connection between the power system, the ESP32-S3 microcontroller, the audio input, and the haptic output.

```mermaid
graph TD
    subgraph Power_System [Power Management]
        Battery[3.7V LiPo Battery] --> TP4056[TP4056 Charger / USB-C]
        TP4056 --> MCP1700[MCP1700 3.3V LDO]
        MCP1700 --> VCC_Rail[3.3V Power Rail]
        GND[Common Ground]
    end

    subgraph MCU [ESP32-S3]
        GPIO14[GPIO 14 - SCK]
        GPIO15[GPIO 15 - WS]
        GPIO16[GPIO 16 - SD]
        GPIO8[GPIO 8 - SDA]
        GPIO9[GPIO 9 - SCL]
        MCU_VCC[3.3V / Vin]
        MCU_GND[GND]
    end

    subgraph Audio_Input [INMP441 Microphone]
        MIC_SCK[SCK]
        MIC_WS[WS]
        MIC_SD[SD]
        MIC_L/R[L/R - GND]
        MIC_VCC[VDD - 3.3V]
    end

    subgraph Haptic_Output [DRV2605L & Motor]
        DRV_SDA[SDA]
        DRV_SCL[SCL]
        DRV_VCC[VIN - 3.3V]
        Vib_Motor[10mm Pancake Motor]
    end

    VCC_Rail --- MCU_VCC
    VCC_Rail --- MIC_VCC
    VCC_Rail --- DRV_VCC
    
    GND --- MCU_GND
    GND --- MIC_L/R
    
    GPIO14 --- MIC_SCK
    GPIO15 --- MIC_WS
    GPIO16 --- MIC_SD
    
    GPIO8 --- DRV_SDA
    GPIO9 --- DRV_SCL
    
    R1[10k Pull-up] --- GPIO8
    R1 --- VCC_Rail
    R2[10k Pull-up] --- GPIO9
    R2 --- VCC_Rail

    DRV_SDA --- Vib_Motor
