# IntelliQ: Smart Queue Prediction System 🚀

![IntelliQ Banner](Logo.png) <!-- Update banner path if necessary -->

IntelliQ is a full-stack, intelligent queue management platform designed to eliminate physical wait times at hospitals, banks, and government offices. By leveraging real-time tracking, digital tokens, and AI-driven slot recommendations, IntelliQ allows users to seamlessly book, track, and manage their appointments from anywhere.

## 🌟 Key Features

### For Users
* **Smart Search & Booking:** Find nearby service providers (Hospitals, Banks, Govt Offices) using a pre-configured database of service locations.
* **AI-Recommended Slots:** Get intelligent time slot recommendations to optimize your visit based on crowd levels, provider capacity, and historical wait times.
* **Live Queue Tracking:** Track your exact position in the queue in real-time. No need to wait in crowded waiting rooms!
* **Digital Tokens:** Instant QR-code based digital tokens containing your appointment details for fast, contactless check-ins at the counter.
* **Unified Dashboard:** View your active queues, upcoming appointments, and historical statistics right from the homepage.

### For Staff & Providers
* **Live Counter Management:** Staff members have dedicated screens to instantly update the current active token and seamlessly transition between customers.
* **Queue & Service Control:** Manage daily incoming queue tokens and service durations effortlessly.

### For Admins
* **Comprehensive Dashboards:** Role-based dashboards (Admin & Super Admin) with analytics and reporting.
* **Role & Staff Management:** Easily assign roles and assign staff to specific service counters.
* **Service Management:** Add and modify the types of services each provider offers.

---

## 🛠️ Technology Stack

### Frontend (Mobile App)
* **Framework:** Flutter (Dart)
* **Routing:** `go_router` for seamless and scalable navigation.
* **State Management:** `provider`
* **Features:** QR code generation (`qr_flutter`), modern Glassmorphism UI, cross-platform support.

### Backend (REST API)
* **Framework:** .NET 8 (C#) ASP.NET Core Web API
* **Database:** Microsoft SQL Server with Entity Framework Core
* **Authentication:** Secure JWT (JSON Web Tokens) role-based authentication.
* **Mock Datasets:** Pre-seeded datasets (`DbSeeder.cs`) to simulate real-world service providers, bypassing the need for external third-party maps or APIs.

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable)
* [.NET 8.0 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/8.0)
* SQL Server Management Studio (SSMS) or Azure Data Studio

### 1. Setting up the Backend
1. Navigate to the backend directory:
   ```bash
   cd Backend/Smart_Queue
   ```
2. Update your `appsettings.json` with your SQL Server connection string:
   ```json
   "ConnectionStrings": {
     "DefaultConnection": "Server=YOUR_SERVER;Database=SmartQueueDb;Trusted_Connection=True;MultipleActiveResultSets=true;Encrypt=False"
   }
   ```
3. Run the Entity Framework migrations to build your database schema:
   ```bash
   dotnet ef database update
   ```
4. Start the backend server (this will also automatically seed the initial provider datasets):
   ```bash
   dotnet run
   ```

### 2. Setting up the Frontend
1. Navigate to the frontend directory:
   ```bash
   cd Frontend
   ```
2. Install all Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Ensure the API base URL in `lib/services/api_service.dart` points to your running backend (e.g., `http://10.0.2.2:5126/api` for Android Emulator or `http://localhost:5126/api` for iOS/Web).
4. Run the app on your preferred device/emulator:
   ```bash
   flutter run
   ```

---

## 🏗️ Project Architecture Overview

* **`Frontend/lib/screens/`**: Contains UI divided perfectly by roles (`user`, `staff`, `admin`, `super_admin`).
* **`Frontend/lib/models/`**: Dart definitions mirroring backend DTOs (e.g., `QueueToken`, `Appointment`).
* **`Frontend/lib/services/`**: Handles authentication and backend integration (`api_service.dart`, `auth_provider.dart`).
* **`Backend/Smart_Queue/Controllers/`**: Houses all RESTful endpoints (`QueueController`, `AppointmentsController`, `AuthController`).
* **`Backend/Smart_Queue/Services/`**: Core business logic.
* **`Backend/Smart_Queue/Data/`**: Database context and `DbSeeder.cs` which populates the initial dataset of Hospitals, Banks, and Govt Offices.
