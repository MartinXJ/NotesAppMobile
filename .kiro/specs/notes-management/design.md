# Design Document: Notes Management System

## Overview

This design document outlines the architecture and implementation approach for a cross-platform notes management application supporting Sermon notes and Journal entries. The application follows an offline-first architecture, ensuring full functionality without internet connectivity while providing seamless synchronization with Google Drive when online.

The system is built using Flutter as the cross-platform framework, providing native performance on both Android and iOS. Local data persistence uses Isar database for its superior performance and rich querying capabilities. The application implements a repository pattern to abstract data sources and enable clean separation between business logic and data access layers.

Key design principles:
- Offline-first: Local storage is the source of truth
- Cross-platform: Single codebase for Android and iOS
- User-centric: Intuitive UI with rich customization options
- Reliable sync: Conflict resolution with last-write-wins strategy
- Performance: Fast search and filtering with indexed queries

## Architecture

### High-Level Architecture

The application follows a layered architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (UI Widgets, Screens, Theme Management, State)         │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│                    Business Logic Layer                  │
│  (Use Cases, Validation, Search, Filter Logic)          │
└─────────────────────────────────────────────────────────┘
                          │
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                            │
│  (Repository Pattern, Data Models, Sync Engine)         │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┴─────────────────┐
        │                                   │
┌───────────────────┐            ┌──────────────────────┐
│  Local Storage    │            │  Cloud Storage       │
│  (Isar Database)  │◄──────────►│  (Firebase)          │
└───────────────────┘   Sync     │  - Firestore         │
                                 │  - Storage           │
                                 │  - Authentication    │
                                 └──────────────────────┘
```

### Technology Stack

**Framework**: Flutter 3.38+ (latest stable)
- Cross-platform support for Android (API 24+) and iOS (13+)
- Single Dart codebase with platform-specific adaptations
- Hot reload for rapid development
- Rich widget ecosystem
- Material Design 3 (Material You) for Android
- Cupertino design language for iOS

**UI Design Systems**:
- **Android**: Material Design 3 (Material You) with dynamic color theming, modern rounded corners, and elevated surfaces
- **iOS**: Cupertino widgets for native iOS look and feel where appropriate
- **Adaptive Widgets**: Platform-aware components that automatically adapt to the host platform
- **Consistent Branding**: Core app identity maintained across both platforms while respecting platform conventions

**Local Database**: Isar 3.x
- NoSQL database with excellent performance
- Rich query capabilities with indexes
- Support for complex filtering and sorting
- Built-in encryption support
- Cross-platform compatibility

**Cloud Backend**: Firebase
- **Firestore**: Cloud NoSQL database for note storage and sync
- **Firebase Authentication**: Simple Google sign-in and user management
- **Firebase Storage**: Media file storage (images, stickers)
- **Offline Persistence**: Built-in offline support with automatic sync
- **Real-time Sync**: Automatic synchronization across devices
- **Free Tier**: Generous limits suitable for personal use

**State Management**: Provider pattern
- Simple and scalable state management
- Easy integration with Flutter widgets
- Minimal boilerplate
- Good performance characteristics

**Rich Text Editor**: flutter_quill
- WYSIWYG editing experience
- Support for text formatting (bold, italic, underline)
- Support for lists (bullet points, numbered)
- Image and media embedding
- Delta format for content storage

**Image Handling**: 
- image_picker: Gallery and camera access
- image_editor_plus: Sticker and image editing capabilities

### Architecture Patterns

**Repository Pattern**: Abstracts data sources (local and remote) behind a unified interface, enabling easy testing and data source switching.

**Offline-First Pattern**: All operations write to local storage first, with background synchronization to remote storage when connectivity is available.

**Observer Pattern**: UI components observe data changes through Provider, automatically updating when underlying data changes.

## Components and Interfaces

### 1. Data Models

#### Note Model
```dart
@collection
class Note {
  Id id = Isar.autoIncrement;
  
  @enumerated
  late NoteType type; // sermon or journal
  
  late String title;
  late String content; // Quill Delta JSON format
  late String plainTextContent; // For search indexing
  
  @Index()
  late DateTime createdAt;
  
  @Index()
  late DateTime modifiedAt;
  
  late String colorHex; // Note color
  
  List<String> tags = [];
  
  List<MediaAttachment> mediaAttachments = [];
  
  // Sync metadata
  late String deviceId;
  late int version; // For conflict resolution
  late bool isSynced;
  late bool isDeleted; // Soft delete flag
  DateTime? deletedAt;
  String? remoteId; // Google Drive file ID
}

enum NoteType {
  sermon,
  journal
}
```

#### MediaAttachment Model
```dart
@embedded
class MediaAttachment {
  late String localPath; // Local file path
  String? remotePath; // Google Drive file ID
  late MediaType type;
  late double positionX; // Position in note
  late double positionY;
  late double width;
  late double height;
}

enum MediaType {
  image,
  sticker
}
```

#### Settings Model
```dart
@collection
class AppSettings {
  Id id = 1; // Singleton
  
  @enumerated
  late ThemeMode themeMode; // light, dark, system
  
  late bool autoSync;
  late int syncIntervalMinutes;
  DateTime? lastSyncTime;
  
  late String defaultNoteColor;
  late double fontSize;
  
  String? googleAccountEmail;
  String? googleAccountId;
}
```

### 2. Repository Layer

#### NotesRepository Interface
```dart
abstract class NotesRepository {
  // CRUD operations
  Future<Note> createNote(Note note);
  Future<Note> updateNote(Note note);
  Future<void> deleteNote(String noteId);
  Future<Note?> getNoteById(String noteId);
  Future<List<Note>> getAllNotes();
  
  // Query operations
  Future<List<Note>> getNotesByType(NoteType type);
  Future<List<Note>> searchNotes(String query);
  Future<List<Note>> filterNotes(NoteFilter filter);
  Future<List<String>> getAllTags();
  
  // Trash operations
  Future<List<Note>> getDeletedNotes();
  Future<void> restoreNote(String noteId);
  Future<void> permanentlyDeleteNote(String noteId);
  
  // Sync operations
  Future<void> syncWithRemote();
  Stream<SyncStatus> get syncStatusStream;
}
```

#### NotesRepositoryImpl
```dart
class NotesRepositoryImpl implements NotesRepository {
  final IsarDatabase localDb;
  final GoogleDriveService remoteStorage;
  final ConnectivityService connectivity;
  
  // Implementation delegates to local storage for reads/writes
  // Background sync worker handles remote synchronization
}
```

### 3. Sync Engine

#### SyncService
```dart
class SyncService {
  final IsarDatabase localDb;
  final GoogleDriveService driveService;
  final ConnectivityService connectivity;
  
  // Sync workflow:
  // 1. Check connectivity
  // 2. Fetch remote changes since last sync
  // 3. Identify conflicts (same note modified locally and remotely)
  // 4. Resolve conflicts using last-write-wins
  // 5. Upload local changes to remote
  // 6. Update sync metadata
  
  Future<SyncResult> performSync();
  Future<void> resolveConflict(Note local, Note remote);
  Future<void> uploadNote(Note note);
  Future<void> downloadNote(String remoteId);
}
```

**Conflict Resolution Strategy**: Last-Write-Wins (LWW)
- Compare `modifiedAt` timestamps
- Keep the note with the most recent timestamp
- Discard the older version
- Simple and deterministic
- Suitable for single-user scenarios

**Sync Metadata**:
- Each note has a `version` counter incremented on each modification
- `deviceId` identifies which device made the last change
- `remoteId` links local note to Google Drive file
- `isSynced` flag indicates if local changes are uploaded

### 4. Search and Filter Engine

#### SearchService
```dart
class SearchService {
  final IsarDatabase db;
  
  Future<List<Note>> search(String query) {
    // Search across:
    // - Note titles (case-insensitive)
    // - Plain text content (case-insensitive)
    // - Tags (exact match)
    
    // Use Isar's full-text search capabilities
    // Return results sorted by relevance (title matches first)
  }
}
```

#### FilterService
```dart
class FilterService {
  final IsarDatabase db;
  
  Future<List<Note>> applyFilters(NoteFilter filter) {
    // Build Isar query based on filter criteria:
    // - Note type (sermon/journal)
    // - Tags (AND/OR logic)
    // - Color
    // - Date range (createdAt or modifiedAt)
    
    // Use Isar indexes for efficient filtering
    // Support multiple simultaneous filters
  }
}

class NoteFilter {
  NoteType? type;
  List<String>? tags;
  String? color;
  DateTime? startDate;
  DateTime? endDate;
  DateFilterType? dateFilterType; // created or modified
}
```

### 5. Authentication Service

#### GoogleAuthService
```dart
class GoogleAuthService {
  final GoogleSignIn _googleSignIn;
  
  Future<GoogleSignInAccount?> signIn();
  Future<void> signOut();
  Future<GoogleSignInAccount?> getCurrentUser();
  Future<String> getAccessToken();
  Future<void> refreshToken();
  
  // OAuth 2.0 scopes required:
  // - https://www.googleapis.com/auth/drive.file
  // - https://www.googleapis.com/auth/drive.appdata
}
```

### 6. Google Drive Service

#### GoogleDriveService
```dart
class GoogleDriveService {
  final GoogleAuthService auth;
  final http.Client httpClient;
  
  // File operations
  Future<String> uploadFile(String fileName, Uint8List data, String mimeType);
  Future<Uint8List> downloadFile(String fileId);
  Future<void> updateFile(String fileId, Uint8List data);
  Future<void> deleteFile(String fileId);
  
  // Folder operations
  Future<String> createAppFolder();
  Future<List<DriveFile>> listFiles(String folderId);
  
  // Sync operations
  Future<List<DriveFile>> getFilesSince(DateTime timestamp);
  Future<DriveFile> getFileMetadata(String fileId);
}
```

**Storage Structure in Google Drive**:
```
/Notes App/
  /notes/
    note_<uuid>.json
    note_<uuid>.json
  /media/
    media_<uuid>.jpg
    media_<uuid>.png
  /metadata/
    sync_metadata.json
```

### 7. Media Service

#### MediaService
```dart
class MediaService {
  final ImagePicker _picker;
  
  Future<File?> pickImageFromGallery();
  Future<File?> pickImageFromCamera();
  Future<File> saveMediaLocally(File file);
  Future<void> deleteMedia(String localPath);
  
  // Sticker support
  Future<List<Sticker>> getWhatsAppStickers();
  Future<List<Sticker>> getLineStickers();
  Future<File> saveStickerLocally(Sticker sticker);
}
```

### 8. Theme Service

#### ThemeService
```dart
class ThemeService {
  final SharedPreferences prefs;
  
  ThemeMode getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
  
  ThemeData getLightTheme();
  ThemeData getDarkTheme();
  
  // Material 3 color schemes
  ColorScheme getLightColorScheme();
  ColorScheme getDarkColorScheme();
}
```

## Data Models

### Note Content Format

Notes use Quill Delta format for rich text content:
```json
{
  "ops": [
    {"insert": "Sermon Title\n", "attributes": {"header": 1}},
    {"insert": "Main points:\n"},
    {"insert": "Point 1", "attributes": {"bold": true}},
    {"insert": "\n"},
    {"insert": {"image": "local://path/to/image.jpg"}},
    {"insert": "\n"}
  ]
}
```

### Sync Metadata Format

Stored in Google Drive for tracking sync state:
```json
{
  "lastSyncTimestamp": "2026-01-06T10:30:00Z",
  "deviceId": "device-uuid",
  "notesManifest": [
    {
      "noteId": "note-uuid",
      "remoteId": "drive-file-id",
      "version": 5,
      "modifiedAt": "2026-01-06T10:25:00Z"
    }
  ]
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Note Creation Persistence
*For any* valid note with title and content, when the note is created, retrieving the note by its ID should return a note with equivalent title and content.
**Validates: Requirements 13.1**

### Property 2: Note Type Immutability
*For any* note, once created with a specific type (Sermon or Journal), the type should remain unchanged throughout the note's lifecycle.
**Validates: Requirements 1.2**

### Property 3: Offline Operation Completeness
*For any* note operation (create, update, delete) performed without internet connectivity, the operation should complete successfully and the changes should be persisted locally.
**Validates: Requirements 4.2, 4.3**

### Property 4: Search Result Accuracy
*For any* search query string, all returned notes should contain the query string in either the title, content, or tags (case-insensitive).
**Validates: Requirements 7.2**

### Property 5: Tag Association Persistence
*For any* note and any set of tags, when tags are added to the note, retrieving the note should return all the added tags.
**Validates: Requirements 6.3**

### Property 6: Color Assignment Persistence
*For any* note and any valid color, when a color is assigned to the note, retrieving the note should return the assigned color.
**Validates: Requirements 5.3, 5.5**

### Property 7: Filter Correctness - Type
*For any* note type filter (Sermon or Journal), all returned notes should have the specified type.
**Validates: Requirements 8.1**

### Property 8: Filter Correctness - Tags
*For any* set of tag filters, all returned notes should contain all the specified tags.
**Validates: Requirements 8.2**

### Property 9: Filter Correctness - Date Range
*For any* date range filter with start and end dates, all returned notes should have creation or modification dates within the specified range (inclusive).
**Validates: Requirements 9.2**

### Property 10: Media Attachment Persistence
*For any* note and any media item, when a media item is added to the note with position and size, retrieving the note should return the media item with the same position and size.
**Validates: Requirements 10.4, 10.6**

### Property 11: Soft Delete Preservation
*For any* deleted note, the note should remain retrievable from the trash for 30 days before permanent deletion.
**Validates: Requirements 13.7**

### Property 12: Theme Persistence
*For any* theme mode selection (light, dark, or system), when the app is restarted, the theme mode should remain as selected.
**Validates: Requirements 11.7**

### Property 13: Sync Idempotence
*For any* note, performing synchronization multiple times without local or remote changes should result in the same note state.
**Validates: Requirements 12.6**

### Property 14: Conflict Resolution Determinism
*For any* two conflicting versions of the same note, the conflict resolution should always select the version with the most recent modification timestamp.
**Validates: Requirements 12.5**

### Property 15: Auto-save Reliability
*For any* note being edited, if changes are made and sufficient time passes, the changes should be persisted to local storage without explicit user save action.
**Validates: Requirements 13.4**

### Property 16: Search Real-time Update
*For any* search query, when the query is modified, the search results should update to reflect the new query.
**Validates: Requirements 7.5**

### Property 17: Multiple Filter Conjunction
*For any* combination of filters (type, tags, color, date), all returned notes should satisfy all applied filters simultaneously.
**Validates: Requirements 8.5**

### Property 18: Tag Suggestion Accuracy
*For any* partial tag input, all suggested tags should start with or contain the input string.
**Validates: Requirements 6.2**

### Property 19: Sync Queue Ordering
*For any* sequence of offline note modifications, when synchronization occurs, the modifications should be uploaded in the order they were made locally.
**Validates: Requirements 12.2, 12.3**

### Property 20: Media Local Storage
*For any* media item added to a note, the media should be stored locally and accessible without internet connectivity.
**Validates: Requirements 10.6**

## Error Handling

### Local Storage Errors
- **Database corruption**: Implement database integrity checks on app startup
- **Insufficient storage**: Check available storage before large operations, notify user
- **Write failures**: Retry with exponential backoff, notify user if persistent

### Network Errors
- **No connectivity**: Queue operations for later sync, inform user of offline mode
- **Timeout**: Retry with exponential backoff (max 3 attempts)
- **Rate limiting**: Implement exponential backoff with jitter
- **Authentication failure**: Prompt user to re-authenticate

### Sync Errors
- **Conflict resolution failure**: Log error, keep both versions, notify user
- **Upload failure**: Keep in sync queue, retry on next sync cycle
- **Download failure**: Skip file, continue with other files, retry later

### Media Errors
- **File not found**: Display placeholder, remove broken reference
- **Unsupported format**: Notify user, reject upload
- **Size limit exceeded**: Notify user, suggest compression

### User Input Errors
- **Empty note title**: Allow but warn user
- **Invalid color**: Fall back to default color
- **Invalid date range**: Show error message, prevent filter application

### Error Logging
- Use Flutter's error reporting mechanisms
- Log errors locally for debugging
- Avoid logging sensitive user data
- Provide user-friendly error messages

## Testing Strategy

### Unit Testing
Unit tests verify specific examples, edge cases, and error conditions for individual components:

- **Data Models**: Test serialization/deserialization, validation
- **Repository**: Test CRUD operations with mock database
- **Search Service**: Test query parsing, result ranking
- **Filter Service**: Test filter combinations, edge cases
- **Sync Service**: Test conflict resolution logic
- **Authentication**: Test token refresh, error handling

### Property-Based Testing
Property tests verify universal properties across all inputs using randomized test data. Each property test should run a minimum of 100 iterations to ensure comprehensive coverage.

**Testing Framework**: Use `test` package with custom property testing utilities or `dart_check` package for property-based testing.

**Property Test Implementation**:
- Generate random notes with varying content, types, tags, colors
- Generate random search queries and filter combinations
- Generate random sync scenarios with conflicts
- Verify correctness properties hold for all generated inputs

**Test Tagging**: Each property test must include a comment referencing the design property:
```dart
// Feature: notes-management, Property 1: Note Creation Persistence
test('note creation persistence property', () {
  // Test implementation
});
```

### Integration Testing
- Test complete user flows (create note → add media → sync)
- Test offline-to-online transitions
- Test multi-device sync scenarios
- Test theme switching across app

### Widget Testing
- Test UI components render correctly
- Test user interactions (taps, swipes, text input)
- Test theme application
- Test responsive layouts

### End-to-End Testing
- Test complete app workflows on real devices
- Test Google authentication flow
- Test actual Google Drive sync
- Test performance with large datasets

### Testing Balance
- Focus property tests on core business logic and data operations
- Use unit tests for specific examples and edge cases
- Avoid over-testing UI components with unit tests
- Property tests handle comprehensive input coverage
- Unit tests validate specific scenarios and integration points

## Performance Considerations

### Database Optimization
- Use Isar indexes on frequently queried fields (createdAt, modifiedAt, tags)
- Implement pagination for large note lists
- Use lazy loading for note content
- Cache frequently accessed data

### Search Optimization
- Index plain text content for full-text search
- Implement debouncing for search input (300ms delay)
- Limit search results to reasonable number (e.g., 100)
- Use background isolates for heavy search operations

### Sync Optimization
- Implement incremental sync (only changed notes)
- Batch upload/download operations
- Compress data before upload
- Use delta sync for large notes

### UI Performance
- Use Flutter's performance best practices
- Implement list view recycling
- Lazy load images and media
- Optimize widget rebuilds with const constructors

### Memory Management
- Dispose controllers and streams properly
- Clear image caches periodically
- Limit in-memory note cache size
- Use weak references where appropriate

## Security Considerations

### Data Encryption
- Use Isar's built-in encryption for local database
- Encrypt sensitive data before Google Drive upload
- Use secure storage for authentication tokens

### Authentication
- Implement OAuth 2.0 best practices
- Store tokens securely using flutter_secure_storage
- Implement token refresh before expiration
- Clear tokens on sign out

### Data Privacy
- Request minimal Google Drive permissions
- Store data in app-specific folder
- Implement data export functionality
- Provide data deletion capability

### Input Validation
- Sanitize user input to prevent injection
- Validate file types for media uploads
- Limit file sizes to prevent abuse
- Validate note content length

## Deployment Considerations

### Android
- Minimum SDK: API 24 (Android 7.0)
- Target SDK: Latest stable
- Required permissions: Internet, Storage, Camera (optional)
- ProGuard rules for release builds

### iOS
- Minimum version: iOS 13.0
- Required capabilities: Internet, Photo Library, Camera (optional)
- App Transport Security configuration
- Privacy descriptions in Info.plist

### Google Cloud Console Setup
- Create OAuth 2.0 credentials for Android and iOS
- Enable Google Drive API
- Configure OAuth consent screen
- Set up API quotas and monitoring

### App Store Requirements
- Privacy policy URL
- Data handling disclosure
- Screenshot requirements
- App description and keywords

## Future Enhancements

### Phase 2 Features
- Collaborative notes (shared with other users)
- Voice notes and audio recordings
- Handwriting support with stylus
- Export to PDF
- Note templates for sermons

### Phase 3 Features
- Web version using Flutter Web
- Desktop apps (Windows, macOS, Linux)
- Advanced search with filters
- Note linking and backlinks
- Markdown support

### Technical Improvements
- Implement CRDT for better conflict resolution
- Add end-to-end encryption
- Implement offline-capable full-text search
- Add analytics and crash reporting
- Implement A/B testing framework
