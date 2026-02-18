# Testing Guide — Notes App (Flutter)

## Testing Strategy Overview

```
┌─────────────────────────────────────────────┐
│              E2E / Integration               │  Few — critical user flows
│         (flutter_test + integration)         │
├─────────────────────────────────────────────┤
│              Widget Tests                    │  Medium — UI behavior
│       (flutter_test + WidgetTester)          │
├─────────────────────────────────────────────┤
│              Unit Tests                      │  Many — business logic
│          (flutter_test / mockito)            │
└─────────────────────────────────────────────┘
```

**Philosophy**: Test behavior, not implementation. Focus unit tests on domain/business logic, widget tests on UI interactions, and keep integration tests for critical flows only.

## Test Directory Structure

```
test/
├── unit/
│   ├── domain/
│   │   └── services/          # ThemeService, business logic
│   └── data/
│       ├── models/            # Note model serialization
│       └── repositories/      # Repository implementations
├── widget/
│   ├── screens/               # Screen-level widget tests
│   └── widgets/               # Reusable widget tests
├── integration/               # Multi-component integration tests
├── helpers/
│   ├── test_helpers.dart      # Shared utilities, pump helpers
│   └── mocks.dart             # Mockito mocks, fakes
└── fixtures/
    └── sample_notes.dart      # Test data factories
```

## Quick Start

### 1. Add dev dependencies

In `pubspec.yaml` under `dev_dependencies`:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.13
  integration_test:
    sdk: flutter
```

### 2. Generate mocks

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run tests

```bash
flutter test                              # All tests
flutter test --coverage                   # With coverage
flutter test test/unit/                   # Unit only
flutter test test/widget/                 # Widget only
```

## What to Test (by layer)

### Domain Layer (unit tests) — highest priority
| Target | What to test |
|--------|-------------|
| `ThemeService` | Theme mode toggling, persistence |
| `NotesRepository` interface | Contract compliance |
| Business logic | Note creation, validation, sorting |

### Data Layer (unit tests)
| Target | What to test |
|--------|-------------|
| `NotesRepositoryImpl` | CRUD operations (mock Isar) |
| Models | Serialization, fromJson/toJson, defaults |
| `IsarService` | Initialization, schema registration |

### Presentation Layer (widget tests)
| Target | What to test |
|--------|-------------|
| `HomeScreen` | Note list rendering, empty state, navigation |
| Editor widgets | Text input, toolbar interactions |
| Theme switching | Light/dark mode UI changes |

### Integration Tests
| Target | What to test |
|--------|-------------|
| Create note flow | Open editor → type → save → appears in list |
| Delete note flow | Select → delete → confirmation → removed |
| Theme toggle | Settings → toggle → UI updates |

## Example: Unit Test

```dart
// test/unit/domain/services/theme_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/domain/services/theme_service.dart';

void main() {
  group('ThemeService', () {
    late ThemeService service;

    setUp(() {
      service = ThemeService();
    });

    test('defaults to system theme mode', () {
      expect(service.themeMode, ThemeMode.system);
    });

    test('toggles between light and dark', () {
      service.setThemeMode(ThemeMode.dark);
      expect(service.themeMode, ThemeMode.dark);
    });
  });
}
```


## Example: Widget Test

```dart
// test/widget/screens/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/presentation/screens/home_screen.dart';
import 'package:notes_app/domain/repositories/notes_repository.dart';
import '../../helpers/mocks.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('shows empty state when no notes exist', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<NotesRepository>(create: (_) => MockNotesRepository()),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No notes yet'), findsOneWidget);
    });
  });
}
```

## Example: Integration Test

```dart
// integration_test/create_note_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:notes_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can create and save a note', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Tap create button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Type note content
    await tester.enterText(find.byType(TextField).first, 'My first note');
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify note appears in list
    expect(find.text('My first note'), findsOneWidget);
  });
}
```

## CI/CD with GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.4'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter pub run build_runner build --delete-conflicting-outputs
      - run: flutter test --coverage
      - run: flutter analyze
```

## Coverage Targets

| Layer | Target |
|-------|--------|
| Domain (services, logic) | 90%+ |
| Data (repositories, models) | 70%+ |
| Presentation (widgets) | 50%+ |
| Integration | Key flows covered |

## Next Steps

1. Set up `test/` directory structure
2. Add `mockito` to dev dependencies
3. Write unit tests for `ThemeService` and note models
4. Write widget tests for `HomeScreen`
5. Add GitHub Actions workflow
6. Add integration tests for create/delete note flows


## Example: Widget Test

```dart
// test/widget/screens/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/presentation/screens/home_screen.dart';
import 'package:notes_app/domain/repositories/notes_repository.dart';
import '../../helpers/mocks.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('shows empty state when no notes exist', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<NotesRepository>(create: (_) => MockNotesRepository()),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No notes yet'), findsOneWidget);
    });
  });
}
```

## Example: Integration Test

```dart
// integration_test/create_note_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:notes_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can create and save a note', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'My first note');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text('My first note'), findsOneWidget);
  });
}
```

## CI/CD with GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.4'
          channel: 'stable'
      - run: flutter pub get
      - run: flutter pub run build_runner build --delete-conflicting-outputs
      - run: flutter test --coverage
      - run: flutter analyze
```

## Coverage Targets

| Layer | Target |
|-------|--------|
| Domain (services, logic) | 90%+ |
| Data (repositories, models) | 70%+ |
| Presentation (widgets) | 50%+ |
| Integration | Key flows covered |

## Next Steps

1. Set up `test/` directory structure matching the layout above
2. Add `mockito` to dev dependencies
3. Write unit tests for `ThemeService` and note models
4. Write widget tests for `HomeScreen`
5. Add GitHub Actions workflow
6. Add integration tests for create/delete note flows
