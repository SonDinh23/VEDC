# 🔧 Hardware Reference

This directory contains the hardware documentation for the VEDC project: schematics, PCB layouts and production files, plus photographic documentation for inspection and review. Each board is described in a self-contained section with: Overview, Quick specs, Key files, Design & test notes, and a photographic gallery.

Navigation

- [EMGSensor](#emgsensor) — electromyography sensor module
- [MainPCB](#mainpcb) — system/mainboard
- [PPG_V1.0](#ppg_v10) — photoplethysmography sensor (prototype)

---

## EMGSensor

Overview

The EMGSensor board acquires surface EMG (electromyography) signals. It conditions microvolt-to-millivolt level signals using a low-noise front-end and band-pass filtering, and provides protection and level conditioning before passing analog outputs to the MainPCB or an external ADC.

Quick specs (typical)

- Signal type: EMG (differential surface electrodes)
- Signal level: microvolts → millivolts (front-end amplification)
- Typical bandwidth: application-dependent; front-end implements band-pass filtering
- Interface: analog outputs to `MainPCB` / ADC

Key files

- `EMGSensor/EMGSensor.kicad_sch` — schematic
- `EMGSensor/EMGSensor.kicad_pcb` — PCB layout
- `EMGSensor/production/` — BOM, placement and netlist files for manufacturing

Design & test notes

- Use short, shielded traces for electrode inputs and maintain a clear analog ground plane.
- Verify input protection and common-mode range before connecting electrodes to live systems.
- Tune filter corner frequencies according to the sampling rate and target EMG bandwidth.

Photographic gallery (EMGSensor)

Figures below use relative paths (from `hardware/README.md`) and include short captions for quick reference.

<div>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="EMGSensor/EMGSensorTop1.png" alt="EMGSensor Top 1" style="width:100%;" />
    <figcaption>Top — full module overview</figcaption>
  </figure>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="EMGSensor/EMGSensorTop2.png" alt="EMGSensor Top 2" style="width:100%;" />
    <figcaption>Top — amplifier/filter area</figcaption>
  </figure>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="EMGSensor/EMGSensorTop3.png" alt="EMGSensor Top 3" style="width:100%;" />
    <figcaption>Top — connector and mechanical features</figcaption>
  </figure>
  <br/>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="EMGSensor/EMGSensorBottom1.png" alt="EMGSensor Bottom 1" style="width:100%;" />
    <figcaption>Bottom — solder side</figcaption>
  </figure>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="EMGSensor/EMGSensorBottom2.png" alt="EMGSensor Bottom 2" style="width:100%;" />
    <figcaption>Bottom — ground pours and vias</figcaption>
  </figure>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="EMGSensor/EMGSensorBottom3.png" alt="EMGSensor Bottom 3" style="width:100%;" />
    <figcaption>Bottom — component placement</figcaption>
  </figure>
</div>

---

## MainPCB

Overview

MainPCB is the central system board. It supplies regulated power rails, hosts the main processing subsystem (MCU or system module), and provides routing and connectors for sensor modules (EMG, PPG), user interfaces and programming/debugging headers.

Quick specs (typical)

- Role: power distribution, processing, peripheral hub
- Power: battery charging, power-path management, regulated rails (3V3, etc.)
- Interfaces: USB/serial, SPI, I2C, ADC inputs, GPIOs, programming headers

Key files

- `MainPCB/MainPCB.kicad_sch` — schematic
- `MainPCB/MainPCB.kicad_pcb` — PCB layout
- `MainPCB/production/` — BOM, placement and netlist files

Design & test notes

- Review the `production/` BOM and placement files before assembly to confirm component variants and orientation.
- Confirm mechanical mounting and keep-out areas if an enclosure is used.
- Use test points for power rails and critical signals to simplify bring-up and debugging.

Photographic gallery (MainPCB)

<div>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="MainPCB/MainPCBtop1.png" alt="MainPCB top 1" style="width:100%;" />
    <figcaption>Top — board overview</figcaption>
  </figure>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="MainPCB/MainPCBtop2.png" alt="MainPCB top 2" style="width:100%;" />
    <figcaption>Top — MCU and connectors</figcaption>
  </figure>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="MainPCB/MainPCBtop3.png" alt="MainPCB top 3" style="width:100%;" />
    <figcaption>Top — power subsystem</figcaption>
  </figure>
  <br/>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="MainPCB/MainPCBbottom1.png" alt="MainPCB bottom 1" style="width:100%;" />
    <figcaption>Bottom — solder side</figcaption>
  </figure>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="MainPCB/MainPCBbottom2.png" alt="MainPCB bottom 2" style="width:100%;" />
    <figcaption>Bottom — ground pours & routing</figcaption>
  </figure>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="MainPCB/MainPCBbottom3.png" alt="MainPCB bottom 3" style="width:100%;" />
    <figcaption>Bottom — component placement</figcaption>
  </figure>
</div>

---

## PPG_V1.0

Overview

The PPG_V1.0 board implements a photoplethysmography sensor. It includes LED drive and a transimpedance amplifier (TIA) to convert the photodetector current to a voltage suitable for digitization.

Quick specs (typical)

- Role: optical heart-rate / blood-volume sensing
- Key blocks: LED driver, photodetector + TIA, analog conditioning
- Interface: analog outputs to `MainPCB` / ADC

Key files

- `PPG_V1.0/PPG_V1.0.kicad_sch` — schematic
- `PPG_V1.0/PPG_V1.0.kicad_pcb` — PCB layout
- `PPG_V1.0/production/` — BOM, placement and netlist files

Design & test notes

- Place LEDs and photodetector to minimize optical crosstalk and maximize contact with tissue.
- Tune LED current and TIA feedback for SNR vs power consumption trade-offs.

Photographic gallery (PPG_V1.0)

<div>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="PPG_V1.0/PPG_V1.0top1.png" alt="PPG top 1" style="width:100%;" />
    <figcaption>Top — overview</figcaption>
  </figure>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="PPG_V1.0/PPG_V1.0top2.png" alt="PPG top 2" style="width:100%;" />
    <figcaption>Top — LED / receiver area</figcaption>
  </figure>
  <br/>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="PPG_V1.0/PPG_V1.0bottom1.png" alt="PPG bottom 1" style="width:100%;" />
    <figcaption>Bottom — solder side</figcaption>
  </figure>
  <figure style="display:inline-block; width:30%; margin:6px; text-align:center;">
    <img src="PPG_V1.0/PPG_V1.0bottom2.png" alt="PPG bottom 2" style="width:100%;" />
    <figcaption>Bottom — placement view</figcaption>
  </figure>
</div>

---

## Notes on images and paths

- Always use forward slashes `/` in image paths; paths in this file are relative to `hardware/README.md`.
- Example: `![EMG front](EMGSensor/EMGSensorTop1.png)`
- If images do not display on GitHub, ensure the files are added, committed and pushed to the remote repository.

---

If you prefer additional formatting (one README per board, smaller thumbnails, or a printable table of BOM items), tell me which format you prefer and I'll update accordingly.
