# Flutter Country Explorer 🌍

**Mobile Application Development — Unit 4 Assignment**  
Addis Ababa University · School of IT & Engineering · Department of Software Engineering

---

## 1. Student Information

| Field | Details |
|-------|---------|
| **Name** | `[YOUR FULL NAME HERE]` |
| **Student ID** | `[YOUR STUDENT ID HERE]` |
| **Track** | Track A — Country Explorer App |

> ⚠️ **Fill in your name and student ID above before submitting.**

---

## 2. App Description

**Country Explorer** is a Flutter application that lets users browse and search every country in the world using the free [RestCountries v3.1 API](https://restcountries.com). The app demonstrates:

- Making HTTP GET requests with the `http` package
- Parsing JSON into typed Dart model classes
- Managing loading, error, and data UI states with `FutureBuilder`
- A clean, reusable API service layer completely separated from the UI

### Screens

| Screen | Description |
|--------|------------|
| **Home** | Scrollable list of ALL countries showing flag emoji, name, and region |
| **Search** | Search countries by name using the `/name/{name}` endpoint |
| **Detail** | Full details: capital, population, currencies, languages, area, timezones |

---

## 3. How to Run Locally

### Prerequisites
- Flutter SDK >= 3.0.0 installed and on your PATH
- An Android emulator or physical device connected

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/<YOUR_USERNAME>/flutter-country-explorer.git
cd flutter-country-explorer

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

> **Note:** This app uses the RestCountries API which is **completely free and requires no API key**. There is no `.env` file needed.

---

## 4. API Endpoints Used

| Method | Endpoint | Purpose |
|--------|---------|---------|
| `GET` | `https://restcountries.com/v3.1/all?fields=name,flag,region,population,cca3` | Fetch all countries for the home screen |
| `GET` | `https://restcountries.com/v3.1/name/{name}` | Search countries by name |
| `GET` | `https://restcountries.com/v3.1/alpha/{code}` | Fetch a single country's full details by ISO alpha-3 code |

---

## 5. Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   └── country.dart                   # Country model (fromJson, toJson, copyWith)
├── services/
│   ├── country_api_service.dart       # All HTTP logic (no HTTP calls in UI)
│   └── api_exception.dart             # Custom exception for non-200 responses
└── screens/
    ├── home_screen.dart               # Home - list of all countries
    ├── search_screen.dart             # Search - search by name
    └── detail_screen.dart             # Detail - full country information
```

---

## 6. Known Limitations & Bugs

- **Flag images**: The RestCountries v3 API provides a `flag` field with a flag emoji character. Some older Android versions may not render all emoji flags correctly — this is a platform limitation.
- **Search sensitivity**: The `/name/{name}` endpoint requires at least a partial match. Searching by abbreviations (e.g., "USA") may return no results; use "United States" instead.
- **No offline caching**: The app always fetches live data. If the device is offline, the error state is shown with a Retry button.
- **Large initial load**: Fetching all ~250 countries on the home screen may take 1–3 seconds on slow connections — a loading spinner is shown during this time.

---

## References

- [RestCountries API Documentation](https://restcountries.com)
- [Flutter HTTP Package](https://pub.dev/packages/http)
- [Flutter FutureBuilder Documentation](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html)
- Course lecture notes — Unit 4: Networking, REST APIs and Data Handling in Flutter

---

*Submitted for Mobile Application Development — Unit 4 Assignment, Addis Ababa University*
