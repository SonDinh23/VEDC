# VEDC.dev

<div align="center">

<img src="resources\image\logoVitalx.png" alt="System diagram" width="350">

[![License](https://img.shields.io/badge/License-GPL%203.0-blue.svg)](https://opensource.org/license/gpl-3-0)
[![LinkedIn](https://img.shields.io/badge/connect-LinkedIn-blue?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/dinhsonn)

<p float="left">
<img src="resources\image\Product_Camera_Side1.png" alt="Product_Camera_Side1" width="49%" object-fit="cover"/>
<img src="resources\image\Product_Camera_Side2.png" alt="Product_Camera_Side2" width="49%" object-fit="cover"/>
</p>
<sub>
  Vedc v0.1 Front Top product (left), Front Bottom product (right)
</sub>


<p float="left">
<img src="resources\image\Product_Camera_Side4.png" alt="Product_Camera_Side4" width="49%" object-fit="cover"/>
<img src="resources\image\Product_Camera_Side3.png" alt="Product_Camera_Side3" width="49%" object-fit="cover"/>
</p>
<sub>
  Vedc v0.1 Back Top product (left), Back Bottom product (right)
</sub>
</div>

## Table of content

- [VEDC](#kwatch)
  - [Table of content](#table-of-content)
  - [About](#about)
  - [Features](#features)
    - [Hardware](#hardware)
    - [Firmware](#firmware)
    - [Software](#software)
  - [Environment, Compiling and running the code](#environment-compiling-and-running-the-code)
  - [Writing apps for the Application Manager](#writing-apps-for-the-application-manager)
  - [Licence GPL-3.0](#licence-gpl-30)
  - [Thanks](#thanks)

## Features

### Hardware
- ESP32-PICO-V3-02 ([ESP32-PICO-V3-02 Models](https://documentation.espressif.com/esp32-pico_series_datasheet_en.pdf))
  - Xtensa® dual-core 32-bit LX6 microprocessor, up to 240 MHz
  - 8 MB flash, 2 MB PSRAM
  - 802.11b/g/n, Bluetooth v4.2
  - Ethernet MAC, TWAI® (compatible with ISO 11898-1, i.e. CAN 2.0 Specifications)
- Torex Semiconductor [XC6220B331MR-G](https://www.farnell.com/datasheets/2012852.pdf) 1A, 3.3V low-noise LDO regulator with GreenOperation mode for efficient system 3V3 power rail
- Silicon Labs [CP2102N-A02-GQFN28](https://www.silabs.com/documents/public/data-sheets/cp2102n-datasheet.pdf) USB-to-UART bridge for programming, logging and debug over USB-C



- Bosch [BMP581](https://www.bosch-sensortec.com/products/environmental-sensors/pressure-sensors/bmp581/) High performance pressure sensor accuracy in units of ~20cm's
- IMU ST [LSM6DSLTR](https://www.st.com/content/ccc/resource/technical/document/datasheet/ee/23/a0/dc/1d/68/45/52/DM00237456.pdf/files/DM00237456.pdf/jcr:content/translations/en.DM00237456.pdf), with this one it's possible to do many fancy things such as navigation using gestures and the typical smartwatch wakeup by moving the arm so the display is viewable
- ST [LIS3MDLTR](https://www.st.com/content/ccc/resource/technical/document/datasheet/54/2a/85/76/e3/97/42/18/DM00075867.pdf/files/DM00075867.pdf/jcr:content/translations/en.DM00075867.pdf) Magnetometer
- Broadcom [APDS-9306-065](https://docs.broadcom.com/docs/AV02-4755EN) Light Sensor for automatic brightness control
- Knowles [SPK0641HT4H-1](https://www.knowles.com/docs/default-source/model-downloads/spk0641ht4h-1-rev-a.pdf) I2S microphone for audio recording
- Micro Crystal [RV-8263-C8](https://www.microcrystal.com/en/products/real-time-clock-rtc-modules/rv-8263-c8) RTC for time keeping and alarm functions
- Texas Instruments [ADS1115IRUGR](https://www.ti.com/lit/ds/symlink/ads1115.pdf) 16-bit, 4-channel I²C ADC for high-resolution sensor and battery voltage measurements
- Texas Instruments [DRV2603RUNT](https://www.ti.com/lit/gpn/drv2603) haptic driver for LRA/ERM vibration motor feedback
- Worldsemi [WS2812B](https://cdn-shop.adafruit.com/datasheets/WS2812B.pdf) individually-addressable RGB LED (integrated driver) for watch notification and status lighting
- Japan Display [LPM013M126A](https://international.switch-science.com/do/medialibrary/2016/08/LPM013M126A_specification_Ver01_20160720.pdf) 1.28" 176×176 Memory-in-Pixel TFT with custom LED backlight for the main watch display


### Firmware
    ⏳ Loading...

### Software
    ⏳ Loading...

## Environment, Compiling and running the code
    ⏳ Loading...

## Writing apps for the Application Manager
    ⏳ Loading...

## Licence GPL-3.0

This project is licensed under the GNU GPLv3.  
Compared to permissive licences like MIT, GPLv3 requires that if you modify this code and distribute your version (including in commercial products), you must also release your changes under the same GPLv3 licence and provide the corresponding source code.  

This way, everyone can benefit from improvements built on top of this project.  
If this licence causes issues for your intended use, feel free to contact me – I’m open to discussing alternatives.

## Thanks
    ⏳ Loading...