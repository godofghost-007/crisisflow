# CrisisFlow 🚨

CrisisFlow is a real-time, AI-powered system designed to manage and resolve incidents efficiently in large venues. It streamlines the process of reporting, verifying, and dispatching resources to handle various crises such as medical emergencies, security issues, and fire/smoke detection.

## Features

- **Anonymous Reporting:** Guests and staff can report incidents by scanning QR codes located in different zones. They can easily upload photos of the incident.
- **AI-Powered Incident Analysis:** When an incident is reported, Google Gemini AI analyzes the attached image to automatically categorize the incident type (fire, medical, security) and assess its severity.
- **Role-Based Workflows:**
  - **Staff:** View verified incidents, analyze AI findings, and resolve incidents.
  - **Manager (Command Center):** Full visibility into all active incidents, resource management, and dispatch operations. Managers can track the real-time status of their teams and respond using optimized dispatch plans.
- **Real-time Synchronization:** Built on top of Firebase Firestore to provide an instant, real-time feed of events as they occur.

## Tech Stack

- **Frontend:** Next.js (App Router), React, Tailwind CSS, Lucide React, Motion (Framer Motion)
- **Backend & Database:** Firebase (Authentication, Firestore, Storage)
- **AI:** Google GenAI SDK

## Getting Started

1. **Install Dependencies:**
   ```bash
   npm install
   ```

2. **Environment Variables:**
   Create a `.env.local` file in the root directory and add your Gemini API key:
   ```env
   NEXT_PUBLIC_GEMINI_API_KEY=your_gemini_api_key
   NEXT_PUBLIC_APP_URL=http://localhost:3000
   ```

3. **Firebase Setup:**
   Ensure your Firebase configuration in `firebase-applet-config.json` is correct and you have set up Firestore Rules.

4. **Run the Development Server:**
   ```bash
   npm run dev
   ```

## Exporting to GitHub

To push this codebase to your own GitHub repository securely:
1. Open the settings menu in Google AI Studio.
2. Select "Export to GitHub" or "Export as ZIP"
3. Connect your GitHub account and specify your repository to complete the export.
