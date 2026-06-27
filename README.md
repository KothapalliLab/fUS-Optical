# Seed-Based fUS–Optical Multimodal Trace Analysis

Code by **Shubham Mirg** — Kothapalli Lab

This repository contains a MATLAB analysis pipeline (`fus_optical.m`) for comparing a seed region's **functional ultrasound (fUS)** cerebral blood volume signal against concurrently recorded **optical** hemodynamic and calcium signals. It filters each modality, brings them onto a common time base, and quantifies their relationship through cross-correlation and time-varying coherence. The repo also includes **3D-printable imaging head hardware** for the fUS probes.

---

## Contents

| File | Description |
|------|-------------|
| `fus_optical.m` | Main analysis script. Loads, filters, interpolates, and visualizes the seed traces. |
| `seed_traces_raw.mat` | Input data: raw ROI-averaged seed traces for all modalities (see structure below). |
| `chronux-master/` | **Required dependency.** The [Chronux](http://chronux.org/) toolbox, used for the coherogram (`cohgramc`). Not bundled — download separately (see Requirements). |
| Imaging head STLs | 3D-printable probe imaging heads and lids — see [Imaging Head Hardware](#imaging-head-hardware). |

---

## Requirements

- **MATLAB** with the **Signal Processing Toolbox** (`butter`, `filtfilt`, `xcorr`, `interp1`).
- **[Chronux toolbox](http://chronux.org/)** — needed for Figure 4 (`cohgramc`). Download it and add it to the MATLAB path:
  ```matlab
  addpath(genpath('chronux-master'));
  ```
  > Note: the `chronux-master` folder was not included in this upload — grab it from the Chronux site or GitHub before running the coherogram section.
- For the hardware: a 3D printer capable of resolving the STL features (see [Imaging Head Hardware](#imaging-head-hardware)).

---

## Input Data: `seed_traces_raw.mat`

Loading the file produces a single struct, `seedTrace`, holding the rawest ROI-mean seed traces (no filtering, no interpolation applied). The recording is ~200 s long.

> *Embedded note:* "Rawest ROI-mean seed traces (no filter, no interp). Hb in µM, fUS = dPDI (CBV), Ca = a.u."

### Signal fields

| Field | Length | Sampling | Units | Meaning |
|-------|--------|----------|-------|---------|
| `fus` | 443 | fUS rate | a.u. (dPDI) | Functional ultrasound — cerebral blood volume (CBV) |
| `hbo` | 1328 | optical rate | µM | Oxygenated hemoglobin |
| `hbr` | 1328 | optical rate | µM | Deoxygenated hemoglobin |
| `hbt` | 1328 | optical rate | µM | Total hemoglobin |
| `ca`  | 1328 | optical rate | a.u. | Calcium (Ca²⁺) |

### Time bases

| Field | Length | Description |
|-------|--------|-------------|
| `t_fus` | 443 | Time vector for the fUS signal (~1.06 → 200.06 s) |
| `t_opt` | 1328 | Time vector for the optical signals (~0.90 → 199.95 s) |

### `params` sub-struct

| Field | Value | Description |
|-------|-------|-------------|
| `frameRate_fus` | ≈ 2.22 Hz | fUS frame/sampling rate |
| `frameRate_opt` | ≈ 6.67 Hz | Optical frame/sampling rate |
| `fuswin` | 443 | fUS analysis window indices |
| `optwin` | 1328 | Optical analysis window indices |
| `twin` | 200 | Time window |

Plus `roi` (the seed ROI index, = 6) and `info` (the description string above).

---

## Processing Pipeline

The script runs top to bottom and produces four figures.

### 1. Filtering
- **fUS and optical hemodynamics** (`hbo`, `hbr`, `hbt`): 4th-order Butterworth **bandpass**, 0.02–0.5 Hz, applied with zero-phase `filtfilt`.
- **Calcium**: 4th-order Butterworth **high-pass** at 0.02 Hz.
- Bandpass cutoffs are normalized to each modality's own Nyquist frequency (fUS vs. optical filters built separately).

### 2. Resampling
Filtered optical signals are interpolated from the optical time base (`t_opt`) onto the fUS time base (`t_fus`) using linear `interp1` with extrapolation, so all signals share the fUS sampling grid for cross-modal comparison.

### 3. Visualization / Analysis

| Figure | Content |
|--------|---------|
| **Figure 1** | Raw, non-normalized traces — one stacked subplot per modality (fUS, HbO, HbR, HbT, Ca²⁺). |
| **Figure 2** | The same traces after filtering. |
| **Figure 3** | Seed-based **cross-correlation** of fUS against each interpolated optical signal (normalized, ±20-sample lag window), plotted in seconds of lag. |
| **Figure 4** | **Coherogram** (time–frequency coherence) of fUS vs. each optical signal via Chronux `cohgramc`, shown as a 2×2 panel of `imagesc` maps. |

#### Key analysis parameters

| Parameter | Value | Used for |
|-----------|-------|----------|
| `f_low` / `f_high` | 0.02 / 0.5 Hz | Hemodynamic bandpass |
| `f_lowc` | 0.02 Hz | Calcium high-pass |
| `wincorr` | 20 samples | Cross-correlation lag window |
| `cparams.tapers` | `[5 9]` | Chronux multitaper setting |
| `cparams.fpass` | `[0 1]` Hz | Coherogram frequency range |
| `movingwin` | `[30 2]` s | Coherogram window / step |

For the coherogram, optical signals are low-pass filtered (cutoff at the fUS frame rate) before interpolation, the raw fUS trace is used directly, and each signal is linearly detrended and mean-subtracted prior to `cohgramc`.

---

## How to Run

1. Place `fus_optical.m`, `seed_traces_raw.mat`, and the `chronux-master` folder in the same directory (or otherwise on the MATLAB path).
2. Add Chronux to the path:
   ```matlab
   addpath(genpath('chronux-master'));
   ```
3. Run the script:
   ```matlab
   fus_optical
   ```
4. Four figures will be generated as described above.

> The script expects `seed_traces_raw.mat` in the current working directory (`load('seed_traces_raw.mat')`).

---

## Imaging Head Hardware

3D-printable (STL) imaging head enclosures and lids for mounting the fUS probes during recording. Each design holds the transducer in place and the matching lid closes the housing.

| Part | Probe | Format | Status |
|------|-------|--------|--------|
| Vermont probe imaging head + lid | Vermont probe | STL | Released |
| L22-14v imaging head + lid | L22-14v | STL | ⚠️ **In testing** — design not yet finalized |

> **L22-14v note:** This imaging head and lid are **currently being tested** and may change. Treat the STL as a working revision rather than a finalized part; verify fit before committing to a print run.

### Printing / fabrication notes
- Files are **STL**, ready to slice and print.
- Print the **head and its matching lid together** so tolerances and fit stay consistent — they are designed as a pair per probe.
- Use the imaging head that matches your probe (Vermont vs. L22-14v); the two are **not interchangeable**.

---

## Notes

- Plots use a 10-color **colorblind-friendly** palette (Okabe–Ito style) defined inline as `cb10`.
- Filtering is zero-phase (`filtfilt`), so no phase delay is introduced by the filters themselves.
- Because each modality is filtered against its own Nyquist frequency, the fUS bandpass and optical bandpass are constructed as separate filter pairs.
