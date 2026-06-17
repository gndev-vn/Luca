# Luca - Lunar Calendar iOS App

Luca is a modern iOS application designed to help users from lunar calendar-using countries (China, Vietnam, etc.) track and remember important lunar events and holidays.

## Features

- **Unified Calendar View**: Display lunar dates as primary with Gregorian dates as secondary overlay
- **Country-Specific Holidays**: Automatic marking of public holidays for selected countries
- **Custom Events**: Create and manage personal lunar calendar events
- **Smart Reminders**: iOS notifications that convert lunar dates to Gregorian calendar times
- **Cultural Information**: Display holiday significance and cultural context
- **Modern UI**: SwiftUI interface with accessibility support and theme adaptation

## Architecture

The app follows MVVM architecture with SwiftUI:

```
├── Models/
│   ├── LunarDate.swift          # Lunar calendar date representation
│   ├── Event.swift              # Event model with categories and reminders
│   └── Country.swift            # Country configuration with holidays
├── Services/
│   ├── LunarCalendarService.swift   # Date conversion and calculations
│   ├── NotificationManager.swift    # iOS notification management
│   └── DataManager.swift           # Core Data persistence
├── ViewModels/
│   ├── CalendarViewModel.swift      # Calendar state management
│   ├── EventViewModel.swift         # Event operations
│   └── SettingsViewModel.swift      # App settings and preferences
├── Views/
│   └── CalendarView.swift           # Main calendar interface
├── Data/
│   ├── CoreDataStack.swift          # Core Data configuration
│   └── LucaDataModel.xcdatamodeld/  # Core Data model
└── Tests/
    ├── LunarDateTests.swift         # Property-based tests
    └── TestHelpers/
        └── MockServices.swift       # Mock implementations
```

## Core Interfaces

### LunarCalendarService
Handles conversion between lunar and Gregorian calendars, lunar phase calculations, and holiday management.

### DataManager
Manages persistent storage of events using Core Data with async/await operations.

### NotificationManager
Integrates with iOS notification system to schedule reminders for lunar events.

## Testing

The project uses both unit testing and property-based testing with SwiftCheck:

- **Unit Tests**: Verify specific examples and edge cases
- **Property Tests**: Verify universal properties across random inputs
- **Mock Services**: Comprehensive mocking for isolated testing

### Property-Based Testing

Uses SwiftCheck library to verify correctness properties such as:
- Date conversion accuracy and consistency
- Calendar navigation behavior
- Event persistence round-trip properties
- UI interaction feedback

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Dependencies

- **SwiftCheck**: Property-based testing framework
- **Core Data**: Local data persistence
- **UserNotifications**: iOS notification system

## Setup

1. Clone the repository
2. Open `Luca.xcodeproj` in Xcode
3. Build and run the project

The project uses Swift Package Manager for dependency management. SwiftCheck will be automatically resolved when building.

## Core Data Model

### EventEntity
- Stores user events with lunar and Gregorian date information
- Supports categories, descriptions, and public holiday flags
- Relationships with reminder entities

### ReminderEntity
- Manages notification scheduling information
- Links to parent events with cascade deletion
- Tracks notification IDs and scheduling status

## Cultural Support

Currently supports:
- **Chinese Lunar Calendar**: Spring Festival, Mid-Autumn Festival, Lantern Festival
- **Vietnamese Lunar Calendar**: Tết Nguyên Đán, Tết Trung Thu, Tết Đoan Ngọ

Additional lunar calendar systems can be added through the Country configuration system.

## License

[License information to be added]