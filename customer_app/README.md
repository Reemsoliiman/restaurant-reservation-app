# Customer App - Restaurant Reservation System

Flutter mobile application for customers to browse restaurants and make table reservations.

## Features

- **Authentication**: Email/password registration and login with Firebase Auth
- **Browse Restaurants**: Real-time list with search and category filtering
- **Restaurant Details**: View restaurant info, tables, and available time slots
- **Book Tables**: Select date/time and make reservations with race condition prevention
- **My Bookings**: View booking history and cancel reservations
- **Real-time Updates**: Instant slot availability updates across all devices

## Architecture

- **State Management**: Cubit pattern with flutter_bloc (5 cubits)
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **UI Pattern**: BlocBuilder/BlocConsumer for reactive UI

## Getting Started

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── cubits/              # State management (5 cubits)
├── Models/              # Data models (restaurant, table, booking)
├── Screens/             # UI screens (7 screens)
├── services/            # Firestore service
├── widgets/             # Reusable widgets
└── main.dart            # Entry point
```

For complete project documentation, see the main [README.md](../README.md) in the root directory.
