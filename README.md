# Seasonal Prep Cook

A production-ready Flutter personal mobile application built to generate weekly meal prep packs with high fresh ingredient overlap, targeting South African seasons, with a local SQLite database, dotenv-based Gemini API integration, and a premium visual design.

## Features
1. **Dashboard View**: Displays the current calendar month and active South African season context (based on Southern Hemisphere mapping). Includes a "Generate Weekly Meal Pack" button and historical saved packs.
2. **Meal Pack Details View**: Displays the 3 generated recipes side-by-side inside scrollable tabs with clear step-by-step instructions.
3. **Smart Shopping List**: Aggregates all overlapping fresh ingredients across the 3 recipes into a single combined quantity to eliminate food waste, separate from a checkbox list of "Store Cupboard Staples".
4. **Local SQLite Persistence**: Persists all historical packs, recipes, ingredients, and checkbox states locally using `sqflite`.

---

## Setup Instructions

### 1. Configure API Credentials
Create a `.env` file in the root of the project (if not already done) and configure your Gemini API credentials:
```env
GEMINI_API_KEY=your_google_gemini_api_key
GEMINI_MODEL=gemini-1.5-flash
```

### 2. Fetch Dependencies
Install the required packages declared in `pubspec.yaml`:
```bash
flutter pub get
```

### 3. Run or Compile the Application
Ensure you have an active emulator or side-loaded Android device connected.

* To run the application in **debug mode**:
  ```bash
  flutter run
  ```

* To compile the application into a **production-ready release APK**:
  ```bash
  flutter build apk --release
  ```

The final release APK will be compiled and located at:
`build/app/outputs/flutter-apk/app-release.apk`
