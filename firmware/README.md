# ⚙️ Firmware

Firmware for VEDC runs on an ESP32-PICO-V3-02 and is organised as a PlatformIO project under `firmware/Embedded`. The codebase orchestrates EMG/IMU, ECG and PPG sensing, manages power and charging, drives haptic/audio feedback, and exposes a BLE interface (NimBLE) for data streaming, control and OTA firmware updates.

## 📁 Directory layout

| Path | Description |
| --- | --- |
| `Embedded/platformio.ini` | PlatformIO environment (`env:mainVEDC`) configuring ESP32 board, PSRAM/flash, COM ports, build flags and third-party libraries. |
| `Embedded/src/MainVEDC.cpp` | Main application entry: hardware bring-up, FreeRTOS task creation, BLE orchestration, power management loop. |
| `Embedded/lib/Son_WearableSensor` | Sensor pipeline (EMG, ECG, PPG, IMU fusion), data encoding and buffer publication. |
| `Embedded/lib/Son_BLEPeripheral` | BLE stack (Information + Controller services), OTA handler, advertising helpers. |
| `Embedded/lib/Son_BLEServiceManager` | Helper template for registering NimBLE characteristics/read-write/notify callbacks. |
| `Embedded/lib/Son_BuzzerMusic` | LEDC-based buzzer driver with predefined alert tones. |
| `Embedded/lib/Son_LSM6DSL` | Driver and helpers for the ST LSM6DSL IMU (I²C/SPI). |
| `Embedded/lib/Son_Filter` | Utility macros (low-pass filters, half-float conversion, mapping helpers). |
| `Embedded/include/` | Place for project-wide headers (PlatformIO convention). |
| `.pio/`, `.vscode/`, `test/` | Build artifacts, VS Code configuration, and PlatformIO test scaffolding. |

## 🧩 System architecture

- **Hardware targets**: ESP32-PICO-V3-02 (`esp32dev` profile) with 8 MB flash, PSRAM enabled (`-DBOARD_HAS_PSRAM`, `-mfix-esp32-psram-cache-issue`). External peripherals include MCP3204 ADC (EMG/ECG), MAX30105 PPG sensor, LSM6DSL IMU, LIS3MDL magnetometer, LED driver, buzzer, and WS2812 NeoPixel indicator.
- **RTOS tasks** (created from `setup()`): dedicated FreeRTOS tasks for EMG/IMU, ECG, PPG, “all sensors”, BLE sync, and a Manager task. Tasks are coordinated via `isRunningTaskSystem[]` flags and suspended/resumed depending on the active sensing mode.
- **Modes**: `MODE_WEARABLE_EMG_IMU`, `MODE_WEARABLE_ECG`, `MODE_WEARABLE_PPG`, `MODE_WEARABLE_ALL`, selected through BLE Controller characteristic. Modes are persisted via `Preferences` so devices restart in last-used mode.
- **Feedback + power**: NeoPixel colour indicates current mode or status, buzzer plays cues (connect, warning, OTA, low battery). Power management monitors charger pins, battery sense, handles deep sleep, wake-up by button/GPIO, and triggers low-battery alarms.
- **Communication**: NimBLE-based GATT server exposes two services: Information (version/name/hardware + OTA) and Controller (mode selection + sensor/battery notifications). BLE MTU set to 517 bytes for efficient streaming.

## 🔄 Runtime flow

1. **Boot & init**: `setup()` configures GPIO, SPI, ADC, NeoPixel, buzzer and sensors, then starts BLE and waits for optional button-triggered wake. PSRAM and SPIFFS are initialised to cache calibration data.
2. **BLE connection window**: `BLEPeripheral::waitConnect()` advertises for up to 60 s while pulsing LEDs/buzzer. If no connection occurs, the device can enter sleep depending on button state.
3. **Sensor tasks**: Once running, tasks continuously sample their respective sensors. Manager task monitors BLE mode selection and resumes/suspends tasks, updates LED colour, and keeps a running battery estimate.
4. **Data path**: Sensor classes push processed samples into `bufferNotify*` arrays. `BLEPeripheral::notifyData()` calls the appropriate Controller notify function, which sends packets as half-floats/uint32 via GATT characteristics.
5. **Power supervision**: `onPower()` polls button, BLE state and charger lines. It enforces timeouts, restarts advertising if disconnected, alarms on low battery (<15 %) and forces sleep below 5 %.
6. **Sleep/OTA**: Button long-press toggles deep sleep via `onSleep()`/`deepSleep()`. OTA is handled entirely over BLE (see below).

## 🧪 Sensor pipelines & algorithms

### ⚡ EMG + IMU
- Sampling: MCP3204 channel read at ~1 kHz (`CYCLE = 1000 µs`).
- Filtering: High-pass (KickFiltersRT) followed by configurable Kalman filter; EMG stored as half-float. IMU orientation uses a quaternion-based fusion (Madgwick-style) combining LSM6DSL gyro/accel with LIS3MDL magnetometer (tilt-compensated heading + complementary filter on yaw).
- Output payload: EMG magnitude + roll, pitch, yaw + elapsed cycle time.

### ❤️ ECG
- Hardware: MCP3204 differential inputs with lead-off detection pins (`PIN_LO_POSITIVE_ECG`, `PIN_LO_NEGATIVE_ECG`).
- Processing chain: high-pass filter (1st order), derivative, squaring, moving window integral (Pan–Tompkins inspired). Adaptive thresholds track signal/noise peaks; RR intervals filtered via EMA to compute heart rate.
- Output payload: lead status bits, filtered analog sample, heart rate half-float.

### 💡 PPG (MAX30105)
- Acquisition: Red/IR LEDs, 100 sps sample rate, decimated by factor 4 for bandwidth reduction. Buffer length 100 samples (~4 s) with recomputation stride 25 samples.
- Algorithms: Maxim `maxim_heart_rate_and_oxygen_saturation()` for HR / SpO₂; EMA smoothing for HR; logistic regression (`logistic_model`) fuses HR + SpO₂ to estimate SmO₂.
- Output payload: raw Red/IR (32-bit), filtered HR/SpO₂/SmO₂ half-floats.

### 🔋 Battery & charging
- `getBattery()` converts ADC millivolts (voltage divider) into percentage with clamping between `BATTERY_MIN` (3.2 V) and `BATTERY_MAX` (4.15 V). Thresholds trigger blink/beep alarms and enforced sleeps; charging detection resets CPU if charger inserted while running (in non-debug builds).

## 📡 BLE stack & OTA

- **Information service** (`WEARABLE_INFORMATION_SERVICE_UUID`)
	- Characteristics: OTA (`OTA_CHAR_UUID`), Device Name, Hardware Name.
	- OTA process: client writes `START_OTA`, streams binary chunks, writes `END_OTA`. ESP32 writes to next OTA partition via `esp_ota_begin/esp_ota_write/esp_ota_end` and reboots when complete.
	- Device name/hardware stored in NVS (`Preferences`) and mirrored to advertisement data.

- **Controller service** (`WEARABLE_CONTROLLER_SERVICE_UUID`)
	- Characteristics: Mode select, EMG/IMU notify, ECG notify, PPG notify, All-sensor (reserved), Battery notify.
	- Notifications use MTU 517 for efficient 20+ byte packets. Mode writes accept ASCII digits representing `mode_wearable_sensor_t` enum.

## 🛠️ Building & flashing

Requirements: PlatformIO CLI or VS Code extension, ESP32 toolchain, USB connection recognised as `COM3` (adjust as needed).

	# 1. Install deps (once)
	pip install platformio

	# 2. Build
	cd firmware/Embedded
	pio run -e mainVEDC

	# 3. Flash firmware (ensure board on COM3)
	pio run -e mainVEDC -t upload

	# 4. Open serial monitor at 115200 baud
	pio device monitor -p COM3 -b 115200

Key build settings (`platformio.ini`):
- `platform = espressif32 @ 6.11.0`, `framework = arduino`, `board = esp32dev`.
- PSRAM/flash config via `board_build.*` options (8 MB QIO, custom partitions `default_8MB.csv`).
- External libraries: MCP320x, SparkFun MAX3010x, SimpleKalmanFilter, KickMath/KickFiltersRT, ESP32Time, NimBLE-Arduino, ArduinoJson, Adafruit NeoPixel + LIS3MDL.

## ⚠️ Operational notes & cautions

- **Task watchdog**: `esp_task_wdt` is fed in sensor loops and OTA handler—avoid adding blocking code without feeding WDT.
- **PSRAM**: Build flags enable PSRAM cache workaround; ensure board definition matches hardware (otherwise random crashes may occur).
- **Sensor grounding**: EMG/ECG inputs are high-impedance and sensitive—maintain shielding and protect against ESD when connecting electrodes.
- **Battery thresholds**: `BATTERY_MIN/BATTERY_MAX` are calibrated for single-cell Li-ion. Adjust if using different chemistry.
- **BLE OTA**: Client must honour START/END messages and send chunks quickly; abort resets OTA session. Ensure adequate battery before OTA.
- **Button handling**: Long press toggles sleep; double-check `PIN_BUTTON` wiring before changing logic to avoid stuck-sleep states.

## 🚀 Extending the firmware

- Add new sensors by extending `WearableSensor` (new mode, buffer, encoder) and exposing a characteristic via `BLEController`.
- To adjust sampling or filtering, modify constants (`FS`, `CYCLE`, Kalman gains, logistic coefficients) inside `Son_WearableSensor` and reflash.
- For additional UI cues, update `BuzzerMusic` or NeoPixel colours inside `ManagerOP` when entering modes.

For questions or contributions, open an issue or pull request in this repository. When contributing code, run `pio run -e mainVEDC` before submitting to ensure the firmware compiles.