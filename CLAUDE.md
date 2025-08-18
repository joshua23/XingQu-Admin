# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

XingQu (星趣) is an AI-driven content creation platform built with Flutter and Supabase. It's a story sharing platform with AI character interaction, audio content, and creative tools. The app supports multiple user modes including guest access and full authentication.

## Development Commands

### Setup and Dependencies
```bash
# Install Flutter dependencies
flutter pub get

# Code generation (for JSON serialization)
flutter packages pub run build_runner build

# Clean and regenerate generated files
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Building
```bash
# Run in development
flutter run

# Run on specific platform
flutter run -d ios
flutter run -d android
flutter run -d chrome

# Build for release
flutter build apk --release
flutter build ios --release
flutter build web --release
```

### Testing
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/analytics_unit_test.dart

# Run performance tests (requires database setup)
./test/scripts/run_performance_tests.sh
```

### Linting and Analysis
```bash
# Analyze code for issues
flutter analyze

# Format code
flutter format .

# Check doctor status
flutter doctor
```

### Supabase Development
```bash
# Start local Supabase (requires Supabase CLI)
supabase start

# Deploy edge functions
./supabase/functions/deploy_all.sh

# Run migrations
supabase db push
```

## Architecture Overview

### Frontend (Flutter)
- **Entry Point**: `lib/main.dart` - App initialization with multi-provider setup
- **Navigation**: Route-based with `/home` as default (guest mode support)
- **State Management**: Provider pattern for auth, AI chat, subscriptions, recommendations, agents
- **Theme**: Custom dark theme with starry background and gold (#FFD700) accent

### Backend (Supabase)
- **Database**: PostgreSQL with 80+ tables including 9 API integration tables
- **Authentication**: OTP-based SMS auth, OAuth support
- **Real-time**: WebSocket subscriptions for live features
- **Storage**: File uploads for avatars, audio, thumbnails
- **Edge Functions**: Custom business logic in TypeScript

### Core Architecture Layers
```
┌─────────────────────────────────────────┐
│           Flutter App (UI Layer)        │
│  • MainPageRefactored (5 main pages)   │
│  • HomeRefactored (4 tabs)             │
│  • Discovery, Creation, Profile pages  │
├─────────────────────────────────────────┤
│        Business Logic Layer            │
│  • Services (API, Auth, Analytics)     │
│  • Providers (State Management)        │
│  • Utils (API Testing, Analytics)      │
├─────────────────────────────────────────┤
│           Data Layer                   │
│  • Models (AI Characters, Audio, etc.) │
│  • Supabase Client Integration         │
│  • Local Storage (SharedPreferences)   │
└─────────────────────────────────────────┘
```

## Key Files and Directories

### Core Application Files
- `lib/main.dart` - App entry point and routing configuration
- `lib/config/supabase_config.dart` - Database connection and table definitions
- `lib/theme/app_theme.dart` - UI theme and design system
- `lib/pages/main_page_refactored.dart` - Main app container with bottom navigation

### Feature Areas
- `lib/pages/home_tabs/` - 4 home tabs: Selection, Comprehensive, FM, Assistant
- `lib/pages/ai_chat_*` - AI conversation features
- `lib/pages/discovery_page.dart` - Content discovery and search
- `lib/services/` - Business logic and API integration
- `lib/widgets/` - Reusable UI components

### Backend Integration
- `supabase/functions/` - Edge functions for AI chat, analytics, recommendations
- `supabase/migrations/` - Database schema migrations
- Database schema files: `*_schema.sql`, `*_deployment.sql`

### Testing
- `test/widget_test.dart` - Main test file (currently skipped pending mock setup)
- `test/analytics_*` - Analytics system tests
- `test/api/` - API integration tests
- `test/performance/` - Performance benchmarks

## Common Development Tasks

### Running the App
The app supports guest mode, so it launches directly to the main interface without requiring authentication:
```bash
flutter run
# Default route: /home (MainPageRefactored)
```

### Adding New Features
1. Create model in `lib/models/` if needed
2. Add service logic in `lib/services/`
3. Create provider for state management in `lib/providers/`
4. Implement UI in `lib/pages/` or `lib/widgets/`
5. Add routes in `lib/main.dart` if needed

### Database Changes
1. Create migration in `supabase/migrations/`
2. Update `lib/config/supabase_config.dart` table constants
3. Modify relevant services in `lib/services/`
4. Run `supabase db push` to apply changes

### Testing Database Integration
Use the built-in test tools:
```dart
// Navigate to /test_database in the app
// Or use lib/utils/api_tester.dart programmatically
final results = await ApiTester.runFullValidation();
```

## Project-Specific Guidelines

### Authentication Flow
- Guest mode is default - no login required for basic features
- SMS OTP authentication for full features
- Check `AuthProvider` for current user state
- Use `AuthService` for login/logout operations

### AI Integration
- AI chat functionality integrated with external APIs (Volcano Engine)
- Cost tracking and quota management built-in
- Use `AiChatProvider` for conversation state
- Audio streaming with adaptive quality

### Content Safety
- Automatic content moderation system
- Risk scoring and confidence ratings
- Manual review workflow support

### State Management Patterns
```dart
// Provider pattern example
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    return authProvider.isLoggedIn 
      ? AuthenticatedWidget() 
      : GuestWidget();
  },
)
```

### API Testing
The project includes comprehensive API testing utilities:
- `lib/utils/api_tester.dart` - Database connection testing
- `test_connection.dart` - Standalone connection test
- Built-in analytics testing via `/analytics_test` route

### Design System
- Dark theme with starry background (`StarryBackground` widget)
- Gold accent color (#FFD700) throughout UI
- Material Design 3 components
- Custom card components: `CharacterCard`, `ChannelCard`, `AgentCard`

## Environment Configuration

### Development Setup
1. Ensure Flutter 3.8+ and Dart 3.0+ installed
2. Update `lib/config/supabase_config.dart` with your Supabase credentials
3. Run database setup scripts in order (see README.md)
4. Install dependencies: `flutter pub get`

### Production Deployment
- iOS/Android: Standard Flutter build process
- Web: `flutter build web --release`
- Backend: Deploy via Supabase CLI or dashboard

## Troubleshooting

### Common Issues
- **Network tests failing**: Tests are currently skipped due to network dependencies
- **Supabase connection**: Check credentials in `supabase_config.dart`
- **iOS build issues**: Ensure Xcode 16.4+ and CocoaPods 1.16.2+
- **Android setup**: Android SDK required for Android builds

### Debug Tools
- Analytics test page: Navigate to `/analytics_test`
- Database test page: Navigate to `/test_database`
- Enable debug prints with `EnvironmentConfig.isDebugMode`

This project uses a sophisticated architecture with real-time features, AI integration, and comprehensive analytics - take time to understand the data flow between Flutter frontend and Supabase backend before making changes.