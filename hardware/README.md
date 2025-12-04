# 🔧 Hardware Reference

Reference hub for every PCB in the VEDC stack. Each section collects the essential narrative (what the board does), quick specs, manufacturing artifacts, bring-up notes and a gallery that matches the files committed to this repo.

## 📌 At-a-glance

| Board | Functional role | Primary interfaces | Manufacturing kit |
| --- | --- | --- | --- |
| [EMGSensor](#emgsensor) | Surface EMG analog front-end with selectable filtering | Differential electrodes, analog output to MainPCB/ADC | `EMGSensor/*.kicad_*`, `EMGSensor/production/` |
| [MainPCB](#mainpcb) | System backplane: power, MCU, sensor connectors & user IO | USB-C, SPI, I2C, GPIO, battery charger, programming header | `MainPCB/*.kicad_*`, `MainPCB/production/` |
| [PPG_V1.0](#ppg_v10) | Optical heart-rate/SpO2 module (LED driver + TIA) | LED drive, photodiode TIA, analog output to MainPCB | `PPG_V1.0/*.kicad_*`, `PPG_V1.0/production/` |

---

## 🧠 EMGSensor

### Highlights
- Low-noise EMG front-end with band-pass filtering and input protection.
- Differential electrode inputs converted to a conditioned analog output for the main MCU/ADC.
- Designed to keep the analog ground plane quiet and isolated from digital switching noise.

### Quick specs

| Parameter | Detail |
| --- | --- |
| Signal type | Differential surface EMG |
| Input range | Microvolt → millivolt (depends on electrode placement) |
| Bandwidth | Application-configurable band-pass |
| Output | Analog to `MainPCB` or external ADC |

### Manufacturing files
- `EMGSensor/EMGSensor.kicad_sch`
- `EMGSensor/EMGSensor.kicad_pcb`
- `EMGSensor/production/` (BOM, placements, netlist, positions)

### Build & test checklist
- Keep electrode traces short/shielded and preserve the analog ground island.
- Verify input protection and supply rails before connecting electrodes to humans.
- Adjust filter corners so they align with sampling rate and targeted muscle group.

### Gallery

<table>
  <tr>
    <td align="center"><img src="EMGSensor/EMGSensorTop1.png" alt="EMGSensor Top 1" width="260"><br><small>Top — module overview</small></td>
    <td align="center"><img src="EMGSensor/EMGSensorTop2.png" alt="EMGSensor Top 2" width="260"><br><small>Top — amplifier/filter</small></td>
    <td align="center"><img src="EMGSensor/EMGSensorTop3.png" alt="EMGSensor Top 3" width="260"><br><small>Top — connectors</small></td>
  </tr>
  <tr>
    <td align="center"><img src="EMGSensor/EMGSensorBottom1.png" alt="EMGSensor Bottom 1" width="260"><br><small>Bottom — solder side</small></td>
    <td align="center"><img src="EMGSensor/EMGSensorBottom2.png" alt="EMGSensor Bottom 2" width="260"><br><small>Bottom — ground pours</small></td>
    <td align="center"><img src="EMGSensor/EMGSensorBottom3.png" alt="EMGSensor Bottom 3" width="260"><br><small>Bottom — component placement</small></td>
  </tr>
</table>

---

## 🧭 MainPCB

### Highlights
- Primary compute board with ESP32 module, battery charging/power-path management and sensor interconnects.
- Hosts debug/programming headers, USB-UART bridge, IMU/ADC expansion headers and NeoPixel/buzzer drivers.
- Provides regulated rails (3V3 etc.) and mounting keep-outs for future enclosures.

### Quick specs

| Parameter | Detail |
| --- | --- |
| Core function | Power distribution + embedded processing |
| Key rails | Battery, charger IC, 3V3 LDO, load switches |
| Interfaces | USB/serial, SPI, I2C, ADC, GPIO, programming header |

### Manufacturing files
- `MainPCB/MainPCB.kicad_sch`
- `MainPCB/MainPCB.kicad_pcb`
- `MainPCB/production/` (BOM, placements, netlist, positions)

### Build & test checklist
- Cross-check BOM vs placement before assembly to avoid variant mix-ups.
- Validate mechanical clearances/keep-outs when fitting into an enclosure.
- Probe test points for each rail during bring-up; confirm charger and LDO thermals.

### Gallery

<table>
  <tr>
    <td align="center"><img src="MainPCB/MainPCBtop1.png" alt="MainPCB top 1" width="260"><br><small>Top — overview</small></td>
    <td align="center"><img src="MainPCB/MainPCBtop2.png" alt="MainPCB top 2" width="260"><br><small>Top — MCU & IO</small></td>
    <td align="center"><img src="MainPCB/MainPCBtop3.png" alt="MainPCB top 3" width="260"><br><small>Top — power subsystem</small></td>
  </tr>
  <tr>
    <td align="center"><img src="MainPCB/MainPCBbottom1.png" alt="MainPCB bottom 1" width="260"><br><small>Bottom — solder side</small></td>
    <td align="center"><img src="MainPCB/MainPCBbottom2.png" alt="MainPCB bottom 2" width="260"><br><small>Bottom — pours & routing</small></td>
    <td align="center"><img src="MainPCB/MainPCBbottom3.png" alt="MainPCB bottom 3" width="260"><br><small>Bottom — placement</small></td>
  </tr>
</table>

---

## 💡 PPG_V1.0

### Highlights
- Dual-LED photoplethysmography front-end with transimpedance amplifier.
- Layout keeps LED/photodiode path compact to reduce crosstalk and improve tissue coupling.
- Analog output routes directly to MainPCB analog inputs or an external ADC.

### Quick specs

| Parameter | Detail |
| --- | --- |
| Role | Optical heart-rate / blood-volume sensing |
| Key blocks | LED driver, photodetector + TIA, post-filtering |
| Output | Analog to `MainPCB` / ADC |

### Manufacturing files
- `PPG_V1.0/PPG_V1.0.kicad_sch`
- `PPG_V1.0/PPG_V1.0.kicad_pcb`
- `PPG_V1.0/production/` (BOM, placements, netlist, positions)

### Build & test checklist
- Align LEDs and photodiode carefully; even small misalignments affect signal quality.
- Tune LED current and TIA feedback for the target SNR vs power budget.
- Shield the sensor head from ambient light during characterization.

### Gallery

<table>
  <tr>
    <td align="center"><img src="PPG_V1.0/PPG_V1.0top1.png" alt="PPG top 1" width="260"><br><small>Top — overview</small></td>
    <td align="center"><img src="PPG_V1.0/PPG_V1.0top2.png" alt="PPG top 2" width="260"><br><small>Top — LED/receiver zone</small></td>
  </tr>
  <tr>
    <td align="center"><img src="PPG_V1.0/PPG_V1.0bottom1.png" alt="PPG bottom 1" width="260"><br><small>Bottom — solder side</small></td>
    <td align="center"><img src="PPG_V1.0/PPG_V1.0bottom2.png" alt="PPG bottom 2" width="260"><br><small>Bottom — placement view</small></td>
  </tr>
</table>

---

## 🖼️ Image & path guidance

- Use forward slashes `/` in Markdown image paths; all current links are relative to this README.
- Example snippet: `![EMG front](EMGSensor/EMGSensorTop1.png)`.
- GitHub renders images only after the corresponding PNG/SVG files are committed and pushed.
- Need a different layout (per-board README, thumbnail sizes, PDF gallery)? Let me know and I can spin up that structure quickly.

---

_Last refreshed: see git history for author/date of the latest board update._
