# 🌀 CrisisFlow
*The high-fidelity emergency coordination platform.*

CrisisFlow is an ultra-fast, premium Flutter Web SaaS application that bridges the gap between distressed guests and facility managers during critical emergencies. Built with a pristine minimal aesthetic, the platform replaces traditional login barriers with dynamic security protocols and real-time mapping dashboards.

---

## 🚀 Key Features

* **Anonymous Guest Scanning:** No app required. Guests scan venue QR codes to bypass authorization barriers and load directly into a secure reporting UI tied specifically to their coordinate zone.
* **Camera-Enforced Trust:** Natively forces live-camera snapshots for reporting to prevent fraudulent camera-roll uploads during active incidents.
* **Role-Based Access Control System:** Recommends phasing out standard email/password bottlenecks for active security personnel. Features a highly complex 8-character code-generation algorithm that assigns bypass tracking IDs based on the worker's unit.
* **AI-Validation Simulation Flow:** Built-in UI staging workflows simulating AI severity validation before triggering hard-coded evacuation/shelter protocols.
* **Tesla-Style Command Dashboard:** Advanced minimalist manager portals with native implementations of:
  * Simulated OR-Tools AI-powered dispatch route modeling grids.
  * Fully interactive Facility Map File Uploads.
  * Extensible "Resource Type" Taxonomy Generation to spin up new internal divisions dynamically.
* **Zero-Cost Scalability:** The application relies entirely on high-performance singleton classes to natively compile and mirror mock-database JSON arrays simultaneously globally. This drastically reduces read/write limits on cloud infrastructures, allowing the prototype to operate indefinitely payload-free.

---

## 🎨 UI/UX Design System
CrisisFlow utilizes a highly refined, premium "White & Light Blue" environment using strictly configured `DM Sans` Google Fonts. Every button stroke, border thickness, layout padding unit, and hover CSS effect operates off of a centralized design token file (`app_theme.dart`). 

---

## 💻 Tech Stack
* **Framework:** Flutter (3.22+)
* **Rendering Engine:** WebAssembly & CanvasKit Auto-Deploy
* **Language:** Dart
* **Architecture Rules:** MVCS (Models, Views, Controllers, Services)

---

## ⏱️ Quick Start

**Prerequisites:** 
- Flutter SDK 
- Chrome browser (or Chromium-based) for debugging.

1. **Clone the repository**
   ```bash
   git clone https://github.com/godofghost-007/crisisflow.git
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Run the local testing server**
   ```bash
   flutter run -d chrome
   ```
4. **Build for Web Production**
   ```bash
   flutter build web --release 
   ```
   *The output will be found in `build/web` and can be deployed directly to Vercel, Netlify, or Firebase Hosting.*
