<p align="center">
  <img src="AppLogo.png" alt="IntelliQ Logo" width="140"/>
</p>

<h1 align="center">IntelliQ — Smart Queue Prediction System</h1>

<p align="center">
  <b>Eliminate physical wait times with AI-powered queue management</b><br/>
  A full-stack platform for real-time digital tokens, live queue tracking, and ML-predicted slot recommendations
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/.NET_8-ASP.NET_Core-512BD4?style=for-the-badge&logo=dotnet&logoColor=white"/>
  <img src="https://img.shields.io/badge/Python-FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white"/>
  <img src="https://img.shields.io/badge/SQL_Server-EF_Core-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white"/>
  <img src="https://img.shields.io/badge/ML-Random_Forest-F7931E?style=for-the-badge&logo=scikitlearn&logoColor=white"/>
</p>

---

## 📌 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Tech Stack](#️-tech-stack)
- [Repository Structure](#-repository-structure)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
  - [Backend Setup](#1-backend-aspnet-core)
  - [ML API Setup](#2-ml-prediction-api-fastapi)
  - [Frontend Setup](#3-frontend-flutter)
- [Test Credentials](#-test-credentials)
- [API Overview](#-api-overview)
- [ML Model](#-ml-model)
- [Screenshots](#-screenshots)
- [Version History](#-version-history)
- [Contributing](#-contributing)

---

## 🧠 Overview

**IntelliQ** is an intelligent, full-stack queue management platform built to eliminate the frustration of physical waiting at high-traffic service locations — hospitals, banks, government offices, and restaurants.

Users can **book digital tokens**, **track their live position** in the queue, and receive **AI-powered slot recommendations** that predict the optimal time to arrive based on historical crowd patterns. Admins get powerful dashboards to manage services, staff, and counters — all in real time.

---

## 🌟 Key Features

### 👤 For Users
| Feature | Description |
|--------|-------------|
| 🔍 **Smart Search** | Discover nearby hospitals, banks, and government offices from a pre-seeded database |
| 🤖 **AI Smart Slots** | ML-predicted time slot recommendations based on wait time, crowd level & capacity |
| 📱 **Digital Tokens** | QR-code based tokens with appointment details for contactless check-in |
| 📍 **Live Queue Tracking** | Real-time position updates — know exactly when it's your turn |
| 📅 **Appointment Booking** | Book, view, and manage upcoming appointments from a unified dashboard |
| 🔔 **Notifications** | In-app alerts for token calls, status changes, and confirmations |
| 🌙 **Dark Mode** | Per-user dark/light mode preference, persisted across sessions |

### 🧑‍💼 For Staff
| Feature | Description |
|--------|-------------|
| 🖥️ **Counter Management** | Update active token, move queue forward in real time |
| 📋 **Live Queue View** | See full list of waiting, serving, and completed tokens |

### 🛡️ For Admins
| Feature | Description |
|--------|-------------|
| 📊 **Analytics Dashboard** | Service-level stats, daily token volume, and wait-time trends |
| 👥 **Role Management** | Assign Super Admin / Admin / Staff roles with granular access |
| 🏥 **Service Management** | Add, edit, and manage service types per provider |
| 🔢 **Counter Assignment** | Map staff members to specific service counters |
| 📆 **Appointment Management** | View and manage all appointments across the platform |

### 👑 For Super Admins
- Manage all service providers across the platform
- Approve/reject provider claim requests from organizations

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Mobile App** | Flutter 3.x (Dart) — cross-platform Android/iOS |
| **Backend API** | ASP.NET Core 8 (C#) — REST API with JWT Auth |
| **Database** | Microsoft SQL Server + Entity Framework Core |
| **ML Model** | Python · scikit-learn (Random Forest) |
| **ML Serving** | FastAPI + Uvicorn |
| **State Management** | Flutter `provider` package |
| **Navigation** | `go_router` (Flutter) |
| **UI Components** | Glassmorphism UI, custom floating nav bar, QR flutter |

---

## 📁 Repository Structure

This repository is organized into **4 branches** — each containing only its relevant code:

```
main          ← Full project overview (this branch)
├── Frontend  ← Flutter mobile application
├── Backend   ← ASP.NET Core REST API
└── ml-model  ← Python ML model + FastAPI prediction server
```

### Main branch directory layout:
```
Smart-Queue-Prediction/
│
├── Frontend/                    # Flutter App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/              # Dart data models (QueueToken, Appointment, etc.)
│   │   ├── screens/
│   │   │   ├── user/            # User-facing screens (home, booking, tracking, token)
│   │   │   ├── staff/           # Staff screens (dashboard, queue management)
│   │   │   ├── admin/           # Admin screens (analytics, roles, services, counters)
│   │   │   └── super_admin/     # Super admin dashboard
│   │   ├── services/
│   │   │   ├── api_service.dart # All HTTP calls to backend
│   │   │   └── auth_provider.dart # Auth + theme state management
│   │   ├── utils/
│   │   │   ├── router.dart      # go_router navigation config
│   │   │   └── theme.dart       # AppTheme with dark/light mode support
│   │   └── widgets/             # Reusable widgets (nav bar, search bar)
│   └── pubspec.yaml
│
├── backend/                     # ASP.NET Core API
│   └── Smart_Queue/
│       ├── Controllers/         # REST endpoints (Auth, Queue, Appointments, Staff...)
│       ├── Models/              # EF Core entity models
│       ├── DTOs/                # Data Transfer Objects
│       ├── Services/            # Business logic layer
│       ├── Data/                # DbContext + DbSeeder (pre-seeded providers)
│       ├── Migrations/          # EF Core database migrations
│       └── Program.cs           # App startup, DI, JWT config
│
├── ml/                          # ML Model & Prediction API
│   ├── train_model.py           # Train & serialize the Random Forest model
│   ├── api.py                   # FastAPI prediction endpoint
│   ├── api/app.py               # Extended API configuration
│   ├── models/
│   │   ├── linear_model.pkl     # Trained model artifact
│   │   └── metadata.pkl         # Feature names, encoders, scaler
│   ├── dataset/                 # Training datasets (CSV)
│   └── requirements.txt
│
├── Datasets_Clean/              # Cleaned source datasets by category
│   ├── Banks_Clean.csv
│   ├── Hospitals_Clean.csv
│   ├── Colleges_Clean.csv
│   └── Restaurants_Clean.csv
│
├── doc/                         # Project documentation & reports
├── AppLogo.png
└── Logo.png
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                 Flutter Mobile App                  │
│   (User / Staff / Admin / Super Admin screens)      │
└──────────────────────┬──────────────────────────────┘
                       │ REST API (HTTP/JSON + JWT)
                       ▼
┌─────────────────────────────────────────────────────┐
│           ASP.NET Core 8 Backend API                │
│                                                     │
│  Controllers → Services → EF Core → SQL Server      │
│                                                     │
│  Key Controllers:                                   │
│  • AuthController   (Login, Register, JWT)          │
│  • QueueController  (Tokens, live queue ops)        │
│  • AppointmentsController                           │
│  • ServicesController / CountersController          │
│  • StaffController / RolesController                │
│  • DashboardController (Analytics)                  │
└──────────────────────┬──────────────────────────────┘
                       │ HTTP POST /predict_wait_time
                       ▼
┌─────────────────────────────────────────────────────┐
│            FastAPI ML Prediction Server             │
│                                                     │
│  Random Forest model → Predicts wait time (mins)   │
│  Input: service_type, day, hour, queue_length, ...  │
│  Output: { estimated_wait_time_minutes: 12.5 }      │
└─────────────────────────────────────────────────────┘
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x stable)
- [.NET 8.0 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/8.0)
- [SQL Server](https://www.microsoft.com/en-us/sql-server/sql-server-downloads) (or SQL Server Express)
- [Python 3.10+](https://www.python.org/downloads/)

---

### 1. Backend (ASP.NET Core)

```bash
# Navigate to backend
cd backend/Smart_Queue
```

Update `appsettings.json` with your SQL Server connection string:
```json
"ConnectionStrings": {
  "DefaultConnection": "Server=YOUR_SERVER;Database=SmartQueueDb;Trusted_Connection=True;MultipleActiveResultSets=true;Encrypt=False"
}
```

Run migrations and start the server:
```bash
dotnet ef database update   # Creates schema + seeds initial provider data
dotnet run                  # Starts API at http://localhost:5126
```

> ✅ The `DbSeeder.cs` will automatically populate hospitals, banks, and government offices on first run.

---

### 2. ML Prediction API (FastAPI)

```bash
# Navigate to ml directory
cd ml

# Install dependencies
pip install -r requirements.txt

# Train the model (generates models/linear_model.pkl and models/metadata.pkl)
python train_model.py

# Start the prediction server
python api.py
# Runs at http://localhost:8000
```

Test it:
```bash
curl -X POST http://localhost:8000/predict_wait_time \
  -H "Content-Type: application/json" \
  -d '{"features": {"service_type": "Hospital", "hour_of_day": 10, "queue_length": 5}}'
```

---

### 3. Frontend (Flutter)

```bash
# Navigate to frontend
cd Frontend

# Install dependencies
flutter pub get
```

Update the API base URL in `lib/services/api_service.dart`:
```dart
// For Android Emulator
static const String baseUrl = 'http://10.0.2.2:5126/api';

// For physical device (use your machine's local IP)
static const String baseUrl = 'http://192.168.x.x:5126/api';

// For iOS Simulator / Web
static const String baseUrl = 'http://localhost:5126/api';
```

Run the app:
```bash
flutter run
```

---

## 🔑 Test Credentials

> Use these accounts to explore all roles in the app:

| Role | Email | Password |
|------|-------|----------|
| 👑 Super Admin | `superadmin@intelliq.com` | `SuperAdmin@123` |
| 🛡️ Admin | `admin@intelliq.com` | `Admin@123` |
| 🧑‍💼 Staff | `staff@intelliq.com` | `Staff@123` |
| 👤 User | `user@intelliq.com` | `User@123` |

---

## 📡 API Overview

Base URL: `http://localhost:5126/api`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/auth/register` | Register a new user |
| `POST` | `/auth/login` | Login and receive JWT token |
| `GET` | `/queue/{providerId}` | Get live queue for a provider |
| `POST` | `/queue/join` | Join a queue and get digital token |
| `POST` | `/queue/next/{counterId}` | Advance queue to next token (Staff) |
| `GET` | `/appointments` | Get user's appointments |
| `POST` | `/appointments` | Book a new appointment |
| `GET` | `/services/{providerId}` | List services for a provider |
| `GET` | `/dashboard/analytics` | Admin analytics data |
| `GET` | `/notifications` | Get user notifications |
| `GET` | `/places/search?q=hospital` | Search service providers |

> All protected routes require `Authorization: Bearer <JWT_TOKEN>` header.

---

## 🤖 ML Model

The AI slot prediction system uses a **Random Forest Regressor** trained on queue management data to predict estimated wait times.

**Features used:**
- Service type (Hospital / Bank / Government)
- Day of week & Hour of day
- Current queue length
- Provider capacity & average service duration
- Historical average wait time

**Output:** Estimated wait time in minutes — used by the app to recommend the best time slots.

**Files:**
- `ml/train_model.py` — Training pipeline with preprocessing, encoding, and model serialization
- `ml/api.py` — FastAPI endpoint that serves predictions in real-time
- `ml/dataset/` — Training dataset (CSV)
- `ml/models/` — Serialized model (`.pkl`) artifacts

---

## 📸 Screenshots

> App screenshots and demo videos available in the `doc/` directory.

---

## 📈 Version History

A timeline of the project's growth from a concept to a fully integrated system:

---

### `v0.1` — Project Foundation *(Sprint 1)*
> 🗓️ Initial setup & planning phase

- [x] Defined project scope, problem statement, and use cases
- [x] Designed database schema and ER diagram
- [x] Set up ASP.NET Core project structure with EF Core
- [x] Created initial SQL Server database with basic `User` and `ServiceProvider` models
- [x] Set up Flutter project with basic folder structure
- [x] Initial `README.md` and project documentation

---

### `v0.25` — Core Frontend & Backend *(Sprint 2)*
> 🗓️ Authentication, screens, and REST API foundation

- [x] **Backend:** JWT authentication system (`AuthController` — register, login, role-based tokens)
- [x] **Backend:** Core REST endpoints for Queue, Appointments, Services, Counters
- [x] **Backend:** Entity Framework migrations and `DbSeeder.cs` with pre-seeded Hospitals, Banks, Govt Offices
- [x] **Frontend:** Full Flutter navigation using `go_router` with role-based routing
- [x] **Frontend:** User screens — Login, Register, Home Dashboard, Service Selection, Appointment Booking
- [x] **Frontend:** Admin screens — Admin Login, Admin Dashboard, Service & Staff Management
- [x] **Frontend:** Staff screens — Staff Dashboard, Live Queue View
- [x] **Frontend:** Glassmorphism UI design system with custom floating capsule nav bar
- [x] **Frontend:** `api_service.dart` integration — all screens wired to live backend

---

### `v0.5` — Queue Intelligence & Digital Tokens *(Sprint 3)*
> 🗓️ Real-time queue tracking and QR token generation

- [x] **Backend:** `QueueController` — join queue, advance token, live position tracking
- [x] **Backend:** `NotificationsController` — in-app alert system
- [x] **Backend:** Role management with Super Admin provider claim flow
- [x] **Frontend:** Digital Token screen with QR code generation (`qr_flutter`)
- [x] **Frontend:** Live Queue Tracking screen with real-time position updates
- [x] **Frontend:** My Tokens screen — active, upcoming, and completed token history
- [x] **Frontend:** Notifications screen
- [x] **Frontend:** Booking Confirmation screen with token summary

---

### `v0.75` — ML Model & AI Slot Prediction *(Sprint 4)*
> 🗓️ Machine learning integration and analytics

- [x] **ML:** Collected and cleaned queue management datasets (Banks, Hospitals, Restaurants, Colleges)
- [x] **ML:** Trained Random Forest Regressor model for wait time prediction
- [x] **ML:** Built FastAPI prediction server (`api.py`) serving `/predict_wait_time` endpoint
- [x] **Backend:** `MlPredictionService.cs` — .NET service calling the Python ML API
- [x] **Frontend:** Smart Slot screen — AI-recommended time slots with predicted wait times
- [x] **Frontend:** AI Prediction screen (Admin) — visualize model insights
- [x] **Frontend:** Analytics Dashboard — token volume, service stats, daily trends
- [x] **Backend:** `DashboardController` + `DashboardService` for aggregated analytics

---

### `v1.0` — Polish, Dark Mode & Final Release *(Sprint 5)*
> 🗓️ Production-ready release with full feature completeness

- [x] **Frontend:** Dark Mode / Light Mode toggle with per-user persistence
- [x] **Frontend:** Dark mode preference saved per `userId` in `SharedPreferences` — survives logout/login
- [x] **Frontend:** Theme resets to Light on logout, restores user's saved preference on re-login
- [x] **Frontend:** `UserThemeWrapper` applied across all role screens (User, Staff, Admin)
- [x] **Frontend:** About screen, Help & Support screen, Profile screen
- [x] **Frontend:** Forgot Password flow
- [x] **Backend:** Public tunneling support for remote device testing
- [x] **Full:** GitHub structured into 4 branches (`main`, `Frontend`, `Backend`, `ml-model`)
- [x] **Full:** Comprehensive README with setup guide, API reference, and test credentials

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch from the appropriate branch (`Frontend`, `Backend`, or `ml-model`)
3. Commit your changes with a descriptive message
4. Push to your fork and open a Pull Request

---

## 📄 License

This project was developed as part of an academic capstone project. All rights reserved.

---

<p align="center">
  Built with ❤️ by the IntelliQ Team
</p>
