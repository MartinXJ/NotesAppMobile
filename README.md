# Notes App

Cross-platform notes app for journaling with offline-first functionality. Built with Flutter, using Isar for local storage and Google Drive for cloud sync.

## Architecture

```
lib/
├── core/           # Theme, utilities, constants
├── data/           # Database, models, repository implementations
├── domain/         # Repository interfaces, services, business logic
└── presentation/   # Screens, widgets, UI layer
```

The app follows clean architecture with a clear separation between domain logic and data/presentation layers. State management uses Provider.

## Getting Started

### Prerequisites
- Flutter SDK ^3.10.4
- Android Studio or Xcode (for platform builds)

### Setup
```bash
git clone <repo-url>
cd notes_app
flutter pub get
flutter pub run build_runner build   # Generate Isar schemas
flutter run
```

## Features

- Rich text editing (flutter_quill)
- Offline-first with Isar local database
- Google Sign-In authentication
- Google Drive cloud sync
- Platform-adaptive UI (Material on Android, Cupertino on iOS)
- Light/dark theme support

## Testing

See [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md) for the full testing strategy and setup instructions.

```bash
flutter test                        # Run all unit/widget tests
flutter test --coverage             # With coverage report
flutter test test/unit/             # Unit tests only
flutter test test/widget/           # Widget tests only
```

## Roadmap

- [ ] Complete notes CRUD with rich text
- [ ] Google Drive sync implementation
- [ ] Offline queue and conflict resolution
- [ ] Search and filtering
- [ ] Tags and categories
- [ ] Export (PDF, plain text)
- [ ] Integration and E2E test suite
- [ ] CI/CD with GitHub Actions

## License

Private — not published.
