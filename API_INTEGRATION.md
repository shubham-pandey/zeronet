# ZeroNet API Integration

This document details all the API integrations implemented in the ZeroNet project based on the API documentation.

## Overview

ZeroNet now supports full integration with the ZeroNet backend API. The project includes the following services and features:

### Implemented Features

#### 1. **Authentication & User Management**
- **Service**: `AuthService` (`lib/services/auth_service.dart`)
- **Features**:
  - Email/password login: `POST /v1/auth/login`
  - OTP request: `POST /v1/auth/login/otp/request`
  - OTP verification: `POST /v1/auth/login/otp/verify`
  - Organization registration: `POST /v1/auth/register/organization`
  - User registration: `POST /v1/auth/register/user`
- **Screen**: `LoginScreen` (`lib/screens/login_screen.dart`)

#### 2. **User Profiles**
- **Service**: `UserService` (`lib/services/user_service.dart`)
- **Features**:
  - Fetch user profile: `GET /v1/users/:id`
- **Models**: `User` and `Organization` in `lib/models/api_models.dart`

#### 3. **Incident Management**
- **Service**: `IncidentsService` (`lib/services/incidents_service.dart`)
- **Features**:
  - List incidents: `GET /v1/incidents`
  - Get incident details: `GET /v1/incidents/:id`
  - Update incident status: `PATCH /v1/incidents/:id/status`
  - Escalate incident: `PATCH /v1/incidents/:id/escalate`
  - Assign responder: `POST /v1/incidents/:id/assign`
  - Resolve incident: `POST /v1/incidents/:id/resolve`
- **Screen**: `IncidentHistoryScreen` (updated to fetch from API)
- **Models**: `ApiIncident`, `IncidentsListResponse` in `lib/models/api_response_models.dart`

#### 4. **Responders Management**
- **Service**: `RespondersService` (`lib/services/responders_service.dart`)
- **Features**:
  - List responders: `GET /v1/responders`
  - Support for filtering by status and organization
- **Screen**: `RespondersScreen` (`lib/screens/responders_manager_screen.dart`)
- **Models**: `Responder`, `RespondersListResponse` in `lib/models/api_response_models.dart`

#### 5. **Dashboard Statistics**
- **Service**: `DashboardService` (`lib/services/dashboard_service.dart`)
- **Features**:
  - Fetch dashboard stats: `GET /v1/dashboard/stats`
  - Displays:
    - Active SOS alerts
    - High priority incidents
    - Responders in field
    - Today resolved count
- **Screen**: `DashboardScreen` (`lib/screens/dashboard_screen.dart`)
- **Models**: `DashboardStatsResponse`, `StatMetric` in `lib/models/api_response_models.dart`

#### 6. **Broadcast System**
- **Service**: `BroadcastService` (`lib/services/broadcast_service.dart`)
- **Features**:
  - Send text broadcast: `POST /v1/broadcast/text`
  - Send voice broadcast: `POST /v1/broadcast/voice`
  - Trigger emergency broadcast: `POST /v1/broadcast/emergency`
  - Stop broadcast: `POST /v1/broadcast/stop`
- **Screen**: `BroadcastScreen` (`lib/screens/broadcast_screen.dart`)
- **Models**: `BroadcastResponse` in `lib/models/api_response_models.dart`

#### 7. **Heatmap Data**
- **Service**: `HeatmapService` (`lib/services/heatmap_service.dart`)
- **Features**:
  - Fetch heatmap data: `GET /v1/heatmap`
  - Support for time range filtering (day, week, month)
  - Support for incident type filtering
- **Screen**: `HeatmapScreen` (`lib/screens/heatmap_screen.dart`)
- **Models**: `HeatmapResponse`, `HeatmapPoint`, `HeatmapStats` in `lib/models/api_response_models.dart`

### Architecture

#### HTTP Client Service
- **File**: `lib/services/http_client_service.dart`
- **Features**:
  - Centralized HTTP client for all API calls
  - Automatic Bearer token management
  - Timeout handling with configurable durations
  - Standardized error handling
  - `ApiResponse<T>` wrapper for consistent response handling
- **Methods**:
  - `get<T>()` - GET requests
  - `post<T>()` - POST requests
  - `patch<T>()` - PATCH requests

#### API Configuration
- **File**: `lib/config/api_config.dart`
- **Configurable via environment variable**:
  - `ZERONET_API_BASE_URL` (default: `https://zeronet-ufoc.onrender.com/v1`)
  - `ZERONET_EMERGENCY_ENDPOINT` (for emergency dispatch)
  - `ZERONET_EMERGENCY_API_KEY` (for emergency dispatch)

#### Models
- **API Request/Response Models**: `lib/models/api_models.dart`
  - `AuthResponse`, `User`, `Organization`, `OtpResponse`
- **API Response Models**: `lib/models/api_response_models.dart`
  - All DTO (Data Transfer Object) models for API responses

### Integration with Existing Features

#### Emergency Dispatch
The project's existing emergency dispatch system now works alongside the API integration:
- Custom emergency dispatch endpoint: Configured via `EmergencyDispatchConfig`
- API backend integration: Configured via `ZeroNetApiConfig`
- Both systems can operate independently or together

#### Sensor & Detection Services
All existing sensor detection, incident detection, and BLE mesh networking continue to work as before and now integrate with:
- `IncidentsService` for API-based incident tracking
- `AlertRouter` for multi-tier dispatch including API calls

### State Management

All services use `ChangeNotifier` for state management and are provided via `Provider`:

```dart
// Services are initialized in main.dart
AuthService().initialize();
IncidentsService().initialize();
// ... etc

// Registered with Provider
MultiProvider(
  providers: [
    ChangeNotifierProvider<AuthService>(...),
    ChangeNotifierProvider<IncidentsService>(...),
    // ... etc
  ],
)
```

Services can be accessed throughout the app via:
```dart
final service = context.read<AuthService>();
// or for reactive updates:
context.watch<AuthService>()
```

### Authentication Flow

1. User opens app → `LoginScreen` displayed if not authenticated
2. User enters credentials → `AuthService.login()` called
3. API returns token → Token stored in `AuthService` and set in `HttpClientService`
4. User navigated to `AppShell` (main app)
5. All subsequent API calls automatically include Bearer token
6. On logout → Token cleared, user returned to login screen

### Error Handling

All services include comprehensive error handling:
- Network timeouts
- Socket exceptions
- API error responses
- Invalid JSON parsing

Errors are stored in `service.error` property and can be monitored via:
```dart
context.watch<Service>().error
```

### Configuration for Development/Production

Set environment variables for API configuration:

```bash
# Development
flutter run --dart-define=ZERONET_API_BASE_URL=http://localhost:3000/v1

# Production
flutter run --dart-define=ZERONET_API_BASE_URL=https://zeronet-ufoc.onrender.com/v1
```

## API Endpoints Summary

| Endpoint | Method | Service | Status |
|----------|--------|---------|--------|
| `/auth/login` | POST | AuthService | ✅ Implemented |
| `/auth/login/otp/request` | POST | AuthService | ✅ Implemented |
| `/auth/login/otp/verify` | POST | AuthService | ✅ Implemented |
| `/auth/register/organization` | POST | AuthService | ✅ Implemented |
| `/auth/register/user` | POST | AuthService | ✅ Implemented |
| `/users/:id` | GET | UserService | ✅ Implemented |
| `/dashboard/stats` | GET | DashboardService | ✅ Implemented |
| `/incidents` | GET | IncidentsService | ✅ Implemented |
| `/incidents/:id` | GET | IncidentsService | ✅ Implemented |
| `/incidents/:id/status` | PATCH | IncidentsService | ✅ Implemented |
| `/incidents/:id/escalate` | PATCH | IncidentsService | ✅ Implemented |
| `/incidents/:id/assign` | POST | IncidentsService | ✅ Implemented |
| `/incidents/:id/resolve` | POST | IncidentsService | ✅ Implemented |
| `/responders` | GET | RespondersService | ✅ Implemented |
| `/heatmap` | GET | HeatmapService | ✅ Implemented |
| `/broadcast/text` | POST | BroadcastService | ✅ Implemented |
| `/broadcast/voice` | POST | BroadcastService | ✅ Implemented |
| `/broadcast/emergency` | POST | BroadcastService | ✅ Implemented |
| `/broadcast/stop` | POST | BroadcastService | ✅ Implemented |

## Files Added/Modified

### New Files
- `lib/config/api_config.dart` - API configuration
- `lib/services/http_client_service.dart` - HTTP client
- `lib/services/auth_service.dart` - Authentication
- `lib/services/user_service.dart` - User profiles
- `lib/services/incidents_service.dart` - Incidents management
- `lib/services/responders_service.dart` - Responders management
- `lib/services/dashboard_service.dart` - Dashboard stats
- `lib/services/broadcast_service.dart` - Broadcast system
- `lib/services/heatmap_service.dart` - Heatmap data
- `lib/models/api_models.dart` - Auth and user models
- `lib/models/api_response_models.dart` - API response models
- `lib/screens/login_screen.dart` - Login UI
- `lib/screens/dashboard_screen.dart` - Dashboard UI
- `lib/screens/responders_manager_screen.dart` - Responders UI
- `lib/screens/broadcast_screen.dart` - Broadcast UI
- `lib/screens/heatmap_screen.dart` - Heatmap UI

### Modified Files
- `lib/main.dart` - Added service initialization and provider setup
- `lib/screens/incident_history_screen.dart` - Updated to fetch from API

## Usage Examples

### Login
```dart
final authService = context.read<AuthService>();
final success = await authService.login(
  email: 'user@example.com',
  password: 'password123',
);
```

### Fetch Incidents
```dart
final incidents = context.read<IncidentsService>();
await incidents.getIncidents(status: 'reported', limit: 20);
```

### Send Broadcast
```dart
final broadcast = context.read<BroadcastService>();
await broadcast.sendTextBroadcast(
  organizationId: '123',
  message: 'Routine drill at 10:00 AM',
);
```

### Get Heatmap Data
```dart
final heatmap = context.read<HeatmapService>();
await heatmap.getHeatmapData(timeRange: 'week', type: 'critical');
```

## Testing

All services are ready for testing with the actual API backend. To test:

1. Set the correct API base URL for your backend
2. Login with valid credentials
3. Services will automatically handle authentication and make API calls

## Future Enhancements

- [ ] Implement multipart form data for voice broadcast uploads
- [ ] Add WebSocket support for real-time updates
- [ ] Implement caching strategy for API responses
- [ ] Add offline support with local caching
- [ ] Implement pagination for list endpoints
- [ ] Add request retry logic with exponential backoff
- [ ] Implement rate limiting
- [ ] Add request/response logging for debugging
