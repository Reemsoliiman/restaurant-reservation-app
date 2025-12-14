# Vendor App - Restaurant Reservation System

Flutter mobile application for restaurant owners to manage their restaurants and bookings.

## Features

- **Restaurant Management**: Create, edit, and manage restaurant listings with images
- **Category Management**: Organize restaurants by categories
- **Bookings Dashboard**: View all bookings with status filters
- **Real-time Notifications**: Receive instant alerts for new bookings via FCM
- **Image Upload**: Upload and update restaurant images to Firebase Storage
- **Multi-table Support**: Configure multiple tables per restaurant

## Architecture

- **State Management**: Cubit pattern with flutter_bloc (7 cubits)
- **Backend**: Firebase (Firestore, Storage, Cloud Messaging)
- **Services**: FirestoreService, FCMService, LocalUserService
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
├── cubits/              # State management (7 cubits)
├── models/              # Data models (restaurant, category, booking)
├── Screens/             # UI screens (7 screens)
├── services/            # Backend services (Firestore, FCM, LocalUser)
├── widgets/             # Reusable widgets
└── main.dart            # Entry point
```

For complete project documentation, see the main [README.md](../README.md) in the root directory.
