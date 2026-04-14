# Indonesia Tourism - Vacation App

[Flutter](https://flutter.dev) • [Firebase](https://firebase.google.com) • [MIT License](https://opensource.org/licenses/MIT)

**Indonesia Tourism** is a modern mobile application built with Flutter, designed to provide a seamless and interactive experience for exploring travel destinations across Indonesia. The app leverages the Firebase ecosystem for real-time data management and secure user authentication.

---

## Developer

**Firman Christian Purba**  
Information Systems Student  
Focused on Mobile Development and UI/UX Design  

---

## Support

If you find this project useful:

- Star this repository  
- Fork it  
- Share it  

---

## Why This Project Matters

This project is not just an application — it demonstrates:

- Real-world Flutter development skills  
- Clean and scalable architecture  
- Strong UI/UX design principles  
- Firebase backend integration  
- Portfolio-ready production concept  

---

## User Flow

1. User opens the application  
2. Authenticates (Login/Register)  
3. Browses destinations  
4. Views detailed information  
5. Saves favorites  
6. Manages profile  

---

## Features

- **User Authentication**  
  Secure login and registration powered by Firebase Authentication  

- **Destination Discovery**  
  Explore curated travel destinations based on categories and popularity  

- **Detailed Information**  
  Descriptions, geographic locations, and image galleries  

- **Favorites System**  
  Save and manage preferred destinations  

- **Profile Management**  
  User profile customization with image upload support  

- **User Experience**  
  Smooth interaction with responsive layout and loading states  

---

## Tech Stack

### Core Framework
- Flutter  
- Dart  

### Backend Services (Firebase)
- `firebase_core` and `firebase_auth` for authentication  
- `cloud_firestore` for real-time database  
- `firebase_storage` for file storage  

### Local Storage
- `shared_preferences` for lightweight caching  

### UI Utilities
- `image_picker` for media handling  
- `url_launcher` for external navigation  
- `shimmer` for loading effects  

---

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.8.1)  
- Dart SDK  
- Firebase project configuration  

---

## Installation

```bash
git clone https://github.com/firmanchrstn/vacation-app1.git
cd vacation-app1
flutter pub get
flutter run

lib/
├── core/        # Theme, constants, reusable components
├── data/        # Models and repository layer
├── features/    # Feature modules (Auth, Home, Detail, Profile)
└── main.dart

---