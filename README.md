<p align="center">
  <img src="Logo.png" alt="IntelliQ Logo" width="140"/>
</p>

<h1 align="center">IntelliQ — Smart Queue Prediction System</h1>

<p align="center">
  <b>Eliminate physical wait times with AI-powered queue management</b><br/>
  A full-stack platform for digital tokens, live queue tracking, appointment booking, and ML-powered wait-time prediction
</p>

<p align="center">
  <a href="https://smart-queue-frontend-ten.vercel.app/">
    <img src="https://img.shields.io/badge/🌐_Live_Web_App-IntelliQ-6C5CE7?style=for-the-badge"/>
  </a>
  <a href="https://appho.st/d/IVKj9TvD">
    <img src="https://img.shields.io/badge/📱_Android_App-Download-3DDC84?style=for-the-badge&logo=android&logoColor=white"/>
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/.NET_9-ASP.NET_Core-512BD4?style=for-the-badge&logo=dotnet&logoColor=white"/>
  <img src="https://img.shields.io/badge/Python-FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white"/>
  <img src="https://img.shields.io/badge/PostgreSQL-Neon-008BB9?style=for-the-badge&logo=postgresql&logoColor=white"/>
  <img src="https://img.shields.io/badge/ML-Scikit--learn-F7931E?style=for-the-badge&logo=scikitlearn&logoColor=white"/>
  <img src="https://img.shields.io/badge/Deployment-Vercel_|_Render-000000?style=for-the-badge"/>
</p>

---

## 📱 Try IntelliQ

### 🌐 Web Application

**Live Web App:**  
https://smart-queue-frontend-ten.vercel.app/

### 📲 Android Application

Scan the QR code below with an Android phone to download the IntelliQ app:

<p align="center">
  <img src="QR_Code.png" alt="IntelliQ Android App QR Code" width="280"/>
</p>

<p align="center">
  <b>Android Download:</b><br/>
  <a href="https://appho.st/d/IVKj9TvD">https://appho.st/d/IVKj9TvD</a>
</p>

> The QR code and download link point to the IntelliQ Android application distribution page.

---

## 📌 Table of Contents

- [Try IntelliQ](#-try-intelliq)
- [Overview](#-overview)
- [Live Services](#-live-services)
- [Key Features](#-key-features)
- [User Roles](#-user-roles)
- [Tech Stack](#️-tech-stack)
- [Production Architecture](#-production-architecture)
- [Repository Structure](#-repository-structure)
- [Deployment](#-deployment)
- [Database & Data](#-database--data)
- [Getting Started](#-getting-started)
  - [Backend Setup](#1-backend-aspnet-core)
  - [ML API Setup](#2-ml-prediction-api-fastapi)
  - [Frontend Setup](#3-frontend-flutter)
- [Production Environment](#-production-environment)
- [API Overview](#-api-overview)
- [ML Model](#-ml-model)
- [Security & Authentication](#-security--authentication)
- [Important Production Improvements](#-important-production-improvements)
- [Version History](#-version-history)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🧠 Overview

**IntelliQ** is an intelligent, full-stack queue management platform designed to reduce physical waiting at high-traffic service locations such as hospitals, banks, colleges, restaurants, and other organizations.

Users can **search organizations, book appointments, receive digital queue tokens, track their live queue position, and get ML-powered wait-time recommendations**. Staff can operate service counters and advance queues, while Admins manage services, staff, counters, appointments, and provider-level analytics. Super Admins manage organizations and platform-level users.

The system is built as a multi-service application:

```text
Flutter Web / Android
        │
        ▼
Vercel — Flutter Web
        │
        ▼
Render — ASP.NET Core 9 API
        │
        ├──────────────► Neon PostgreSQL
        │
        └──────────────► Render — FastAPI ML API
```

---

## 🌐 Live Services

| Service | Platform | URL |
|---------|----------|-----|
| 🖥️ **Frontend Web App** | Vercel Hobby | https://smart-queue-frontend-ten.vercel.app/ |
| ⚙️ **Backend API** | Render Free | https://smart-queue-prediction.onrender.com |
| 🤖 **ML Prediction API** | Render Free | https://smart-queue-prediction-1.onrender.com |
| 🗄️ **PostgreSQL Database** | Neon Free | Managed through Neon |
| 📱 **Android App** | App distribution link | https://appho.st/d/IVKj9TvD |
| 💻 **Source Code** | GitHub | https://github.com/Charan-Dasari/Smart-Queue-Prediction |

### Backend API

Production API base URL:

```text
https://smart-queue-prediction.onrender.com/api
```

### ML API

Production ML service:

```text
https://smart-queue-prediction-1.onrender.com
```

FastAPI documentation:

```text
https://smart-queue-prediction-1.onrender.com/docs
```

> Note: Render Free services may take some time to wake up after a period of inactivity.

---

## 🌟 Key Features

### 👤 For Users

| Feature | Description |
|--------|-------------|
| 🔍 **Smart Search** | Search organizations across hospitals, banks, colleges, restaurants, and other supported categories |
| 🤖 **AI Smart Slots** | ML-powered wait-time predictions used to recommend suitable appointment slots |
| 📱 **Digital Tokens** | Digital queue tokens with QR-code based passes |
| 📍 **Live Queue Tracking** | Track queue position and current queue status |
| 📅 **Appointment Booking** | Book, view, and manage appointments |
| ⚡ **Instant Queue** | Join a live queue without making a scheduled appointment |
| 🔔 **Notifications** | Receive token, appointment, and queue-related notifications |
| 📊 **User Statistics** | View booking and visit-related statistics |
| 🧠 **AI Analysis** | View queue-related AI insights and recommendations |
| 🌙 **Dark / Light Mode** | User-specific theme preference |
| 🗑️ **Account Deletion** | Request account deletion through the application |

### 🧑‍💼 For Staff

| Feature | Description |
|--------|-------------|
| 🖥️ **Counter Management** | Manage assigned counters and active tokens |
| 📋 **Live Queue View** | View waiting, serving, completed, and skipped tokens |
| ⏭️ **Call Next** | Advance the queue to the next token |
| 📊 **Staff Dashboard** | View staff-related queue statistics and activity |

### 🛡️ For Admins

| Feature | Description |
|--------|-------------|
| 📊 **Analytics Dashboard** | Provider-level queue and appointment analytics |
| 🤖 **AI Predictions** | View ML-related prediction information |
| 👥 **Staff Management** | Create and manage staff accounts |
| 🏥 **Service Management** | Add and manage services offered by an organization |
| 🔢 **Counter Management** | Create, assign, update, and manage service counters |
| 📆 **Appointment Management** | View and manage appointments for the organization |
| 📋 **Queue Management** | Monitor active queues |
| 🔐 **Role Management** | Manage permitted provider-level roles |

### 👑 For Super Admins

| Feature | Description |
|--------|-------------|
| 🏢 **Provider Management** | Manage organizations registered on the platform |
| 🆕 **Manual Organization Onboarding** | Create organizations that are not present in the public directory dataset |
| 🔎 **Case-Insensitive Directory Search** | Search the organization directory without case-sensitive matching |
| 👥 **Admin Creation** | Automatically create organization Admin credentials during onboarding |
| ✅ **Claim Approval** | Handle organization claim requests |
| 👤 **User Management** | Manage platform users and account deletion requests |
| 📊 **Platform Dashboard** | View platform-level statistics |

---

## 🧑‍💻 User Role Structure

```text
                    Super Admin
                        │
          ┌─────────────┴─────────────┐
          ▼                           ▼
   Organization A              Organization B
       Admin                       Admin
         │                           │
      ┌──┴──┐                     ┌──┴──┐
      ▼     ▼                     ▼     ▼
    Staff  Staff                 Staff  Staff

                 User
                  │
        Register / Login / Book
        Queue / Appointment
```

### Organization Onboarding

Super Admins can create organizations in two ways:

1. **Search Directory**
   - Search the 294,030-record Places dataset.
   - Search is case-insensitive.
   - Select an existing place and create its provider.

2. **New Organization**
   - Enter organization name, category, state, city, and address.
   - A new organization record is created directly in PostgreSQL.
   - An Admin account is automatically generated for the organization.

Admin credentials follow the application's generated credential convention and are displayed to the Super Admin after successful onboarding.

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter / Dart |
| **Web Hosting** | Vercel Hobby |
| **Backend API** | ASP.NET Core 9 / C# |
| **ORM** | Entity Framework Core 9 |
| **Database** | PostgreSQL |
| **Database Hosting** | Neon Free |
| **ML** | Python / scikit-learn |
| **ML API** | FastAPI / Uvicorn |
| **Authentication** | JWT + BCrypt password hashing |
| **State Management** | Flutter Provider |
| **Navigation** | Flutter `go_router` |
| **QR Codes** | `qr_flutter` |
| **Maps / Location** | Flutter geolocation-related packages |
| **Backend Hosting** | Render Free |
| **ML Hosting** | Render Free |
| **Source Control** | GitHub |
| **Deployment** | GitHub-connected Vercel + Render |
| **Architecture** | Separate frontend, backend, database, and ML services |

---

## 🏗️ Production Architecture

![System Architecture](System_Arc.png)

### Request Flow

```text
                         ┌──────────────────────┐
                         │   Flutter Web App    │
                         │       Vercel         │
                         └──────────┬───────────┘
                                    │ HTTPS
                                    ▼
                         ┌──────────────────────┐
                         │   ASP.NET Core 9     │
                         │      Render          │
                         └───────┬───────┬──────┘
                                 │       │
                       EF Core   │       │ HTTP
                                 │       │
                                 ▼       ▼
                    ┌──────────────┐   ┌────────────────┐
                    │    Neon      │   │   FastAPI ML   │
                    │ PostgreSQL   │   │     Render     │
                    └──────────────┘   └────────────────┘
```

### Production Services

- **Vercel** serves the Flutter Web application.
- **Render** hosts the ASP.NET Core 9 REST API.
- **Neon** provides the production PostgreSQL database.
- **Render** hosts the FastAPI machine-learning service.
- **GitHub** stores the source code and is connected to the deployment platforms.
- Secrets such as database credentials and JWT keys are stored as environment variables / deployment secrets and are not committed to the repository.

---

## 📁 Repository Structure

```text
Smart-Queue-Prediction/
│
├── Frontend/                         # Flutter Web + Android application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/                  # Application data models
│   │   ├── screens/
│   │   │   ├── user/                # User screens
│   │   │   ├── staff/               # Staff screens
│   │   │   ├── admin/               # Admin screens
│   │   │   └── super_admin/         # Super Admin screens
│   │   ├── services/
│   │   │   ├── api_service.dart     # Backend API integration
│   │   │   └── auth_provider.dart   # Authentication and app state
│   │   ├── utils/
│   │   │   ├── router.dart
│   │   │   └── theme.dart
│   │   └── widgets/
│   ├── build.sh                     # Vercel Flutter build script
│   ├── vercel.json                  # Vercel configuration
│   └── pubspec.yaml
│
├── backend/
│   └── Smart_Queue/
│       ├── Controllers/             # REST API controllers
│       ├── Models/                  # Entity models
│       ├── DTOs/                    # Data transfer objects
│       ├── Services/                # Application/business services
│       ├── Data/                    # DbContext and data access
│       ├── Migrations/              # Active PostgreSQL EF migration
│       ├── Migrations_SqlServer/    # Preserved SQL Server migrations
│       ├── Dockerfile               # Render container deployment
│       └── Program.cs               # Startup, DI, JWT, CORS, DB setup
│
├── ml/
│   ├── api.py                       # FastAPI prediction API
│   ├── models/
│   │   ├── random_forest_model.pkl  # Trained Random Forest model
│   │   ├── linear_model.pkl         # Trained Linear Regression model
│   │   └── metadata.pkl             # Model metadata
│   ├── requirements.txt
│   ├── dataset/                     # Training data
│   └── notebook/                    # ML experimentation
│
├── Datasets_Clean/                  # Cleaned source datasets
│   ├── Banks_Clean.csv
│   ├── Hospitals_Clean.csv
│   ├── Colleges_Clean.csv
│   └── Restaurants_Clean.csv
│
├── doc/                              # Project documentation
├── AppLogo.png
├── Logo.png
├── System_Arc.png
└── IntelliQ_QR_Code.png              # Android app QR code
```

---

## ☁️ Deployment

IntelliQ was originally developed with an Azure deployment architecture. The production deployment was later migrated to an all-free hosting architecture using **Vercel, Render, Neon, and GitHub**.

### Current Production Deployment

| Component | Platform | Configuration |
|-----------|----------|---------------|
| **Flutter Web** | Vercel Hobby | Root directory: `Frontend` |
| **ASP.NET Core 9 API** | Render Free | Docker deployment |
| **FastAPI ML API** | Render Free | Python service |
| **PostgreSQL** | Neon Free | `IntelliQ` project / `production` branch |
| **Source Code** | GitHub | `Charan-Dasari/Smart-Queue-Prediction` |

### Frontend Deployment

The Flutter Web application is deployed on Vercel.

Important configuration:

```text
Framework Preset: Other
Root Directory: Frontend
Build Command: bash build.sh
Output Directory: build/web
```

`Frontend/build.sh` installs Flutter on the Vercel build environment and runs:

```bash
flutter pub get
flutter build web --release
```

The Flutter application uses `Frontend/vercel.json` for SPA routing and cache configuration.

### Backend Deployment

The ASP.NET Core 9 backend is deployed to Render using Docker.

Production environment variables include:

```text
ConnectionStrings__DefaultConnection
Jwt__Key
PORT
MlApi__BaseUrl
```

The backend connects to Neon PostgreSQL through Npgsql and communicates with the FastAPI ML service over HTTPS.

### ML Deployment

The FastAPI ML service is deployed separately on Render.

Start command:

```bash
uvicorn api:app --host 0.0.0.0 --port $PORT
```

The prediction endpoint is:

```text
POST /predict_wait_time
```

### Database Deployment

The production database uses **Neon PostgreSQL**.

The SQL Server implementation was migrated to PostgreSQL using Entity Framework Core and Npgsql.

The production schema contains entities including:

```text
Places
ServiceProviders
Services
Users
TimeSlots
Appointments
QueueTokens
ServiceCounters
Notifications
ActivityLogs
ClaimRequests
AccountDeletionRequests
```

---

## 🗄️ Database & Data

### Places Dataset

The application uses a large directory dataset containing:

| Category | Records |
|----------|--------:|
| Banks | 182,523 |
| Colleges | 53,578 |
| Hospitals | 30,273 |
| Restaurants | 27,656 |
| **Total** | **294,030** |

The dataset was imported into Neon PostgreSQL using a one-time bulk import.

### Important Data Design

The 294,030 Places records are **not imported every time the backend starts**.

The production application does not automatically re-seed the entire directory dataset during startup.

This prevents unnecessary startup work and avoids repeatedly loading a large dataset into the production service.

### Case-Insensitive Search

Organization directory searches use PostgreSQL case-insensitive matching.

Examples:

```text
Apollo
apollo
APOLLO
ApOlLo
```

can match the same organization records.

Category, state, city, and general text searches also support case-insensitive matching where applicable.

---

## 🚀 Getting Started

> The production application is already deployed. These instructions are for local development.

### Prerequisites

- Flutter SDK 3.x stable
- .NET 9 SDK
- Python 3.10+
- PostgreSQL / Neon account for a database
- Git
- Android Studio if building the Android application

---

### 1. Backend (ASP.NET Core 9)

```bash
cd backend/Smart_Queue
```

Configure the database and JWT settings using local configuration or user secrets.

Example PostgreSQL connection string format:

```text
Host=YOUR_HOST;
Database=neondb;
Username=YOUR_USERNAME;
Password=YOUR_PASSWORD;
SSL Mode=Require;
Channel Binding=Require
```

Run:

```bash
dotnet restore
dotnet build
dotnet run
```

The API will start on the configured local development port.

> The production directory dataset is already stored in Neon. Do not run a full 294,030-record import during normal application startup.

---

### 2. ML Prediction API (FastAPI)

```bash
cd ml
pip install -r requirements.txt
```

Start the API:

```bash
uvicorn api:app --host 0.0.0.0 --port 8000
```

API documentation:

```text
http://localhost:8000/docs
```

Prediction endpoint:

```text
POST http://localhost:8000/predict_wait_time
```

---

### 3. Frontend (Flutter)

```bash
cd Frontend
flutter pub get
```

For local development, configure the backend API URL in:

```text
lib/services/api_service.dart
```

Production:

```text
https://smart-queue-prediction.onrender.com/api
```

Local:

```text
http://localhost:<YOUR_BACKEND_PORT>/api
```

Run the web application:

```bash
flutter run -d chrome
```

Run on a connected Android device:

```bash
flutter run
```

Build Flutter Web:

```bash
flutter build web --release
```

---

## 🔑 Test Credentials

A basic user test account can be used where available:

| Role | Email | Password |
|------|-------|----------|
| 👤 User | `user@intelliq.com` | `User@123` |

### Admin & Staff Accounts

Organization Admin and Staff credentials are generated by the application during onboarding.

Super Admins can create an organization from:

```text
Super Admin → Provider Management → New Organization
```

The application then creates the organization Admin account and displays the generated credentials.

> For security, production secrets and database credentials are not stored in this README.

---

## 📡 API Overview

**Production Base URL:**

```text
https://smart-queue-prediction.onrender.com/api
```

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/auth/register` | Register a user |
| `POST` | `/auth/login` | Authenticate and receive JWT |
| `GET` | `/queue/{providerId}` | Get provider queue |
| `POST` | `/queue/join` | Join an instant queue |
| `GET` | `/queue/my-tokens` | Get user's active queue tokens |
| `POST` | `/queue/next/{counterId}` | Call the next queue token |
| `GET` | `/appointments` | Get user appointments |
| `POST` | `/appointments` | Book an appointment |
| `GET` | `/services/{providerId}` | Get provider services |
| `GET` | `/dashboard/user` | User dashboard |
| `GET` | `/dashboard/admin` | Admin dashboard |
| `GET` | `/dashboard/staff` | Staff dashboard |
| `GET` | `/dashboard/superadmin` | Super Admin dashboard |
| `GET` | `/notifications` | Get notifications |
| `GET` | `/places` | Search/list directory places |
| `GET` | `/account/profile` | Get user profile |
| `PUT` | `/account/profile` | Update user profile |
| `POST` | `/account/deletion-request` | Request account deletion |
| `GET` | `/claims` | Get provider claim requests |
| `POST` | `/providers` | Create provider from directory |
| `POST` | `/providers/manual` | Create a manual organization |
| `POST` | `/staff` | Create organization staff |

> Protected routes use JWT authentication through the `Authorization: Bearer <JWT_TOKEN>` header.

---

## 🤖 ML Model

The IntelliQ AI component predicts estimated queue waiting time.

### Current Model

The production FastAPI service loads the trained Random Forest model:

```text
ml/models/random_forest_model.pkl
```

Supporting model artifacts include:

```text
ml/models/linear_model.pkl
ml/models/metadata.pkl
```

### Prediction Features

The model uses queue/service-related features such as:

- Service type
- Day of week
- Hour of day
- Current queue length
- Queue position
- Provider capacity
- Average service duration
- Historical average wait time
- Active staff
- Service counters
- Priority/customer information
- Peak-hour information
- Holiday-related information

### Prediction Flow

```text
Flutter App
    │
    ▼
ASP.NET Core API
    │
    ▼
FastAPI ML Service
    │
    ▼
Random Forest Model
    │
    ▼
Predicted Wait Time
    │
    ▼
Smart Slot Recommendation
```

---

## 🔐 Security & Authentication

### Authentication

IntelliQ uses:

- JWT authentication
- Role-based authorization
- BCrypt password hashing
- Provider-scoped authorization
- JWT `ProviderId` claim for organization isolation

### Roles

```text
SuperAdmin
    │
    └── Admin
          │
          └── Staff

User
```

### Organization Isolation

Provider-level resources are protected so that Admins, Staff, counters, services, queues, and related records are scoped to the appropriate organization.

Cross-organization ownership checks were added to sensitive provider management operations.

### Session Handling

The Flutter client has centralized handling for expired JWT sessions in core authenticated flows.

For web users, JWT session duration was adjusted to reduce unnecessary logouts during normal usage.

---

## 🛠️ Important Production Improvements

The final production migration included several important fixes and improvements.

### 1. SQL Server → PostgreSQL Migration

The backend was migrated from SQL Server to PostgreSQL.

Changes included:

- Npgsql EF Core provider
- PostgreSQL connection configuration
- New PostgreSQL EF migration
- UTC-compatible DateTime handling
- Removal of SQL Server-specific query functions where required
- Preserved legacy SQL Server migrations separately

### 2. Production Database Optimization

The large Places directory is stored in Neon and is queried directly by PostgreSQL.

The backend does not load all 294,030 records into memory for every search.

### 3. Time Slot Fixes

Appointment and time-slot operations were updated to use UTC-compatible date ranges for PostgreSQL.

### 4. Appointment DateTime Fix

Appointment creation now handles UTC timestamps correctly so PostgreSQL `timestamptz` values are stored consistently.

### 5. Session Expiration Handling

Expired JWT sessions are centrally detected for the major authenticated user flows and users are redirected to login instead of seeing misleading empty/failed screens.

### 6. Active Token Loading

The My Tokens screen now uses the dedicated active-token endpoint instead of the appointments endpoint.

### 7. Independent Dashboard Loading

Dashboard sections load independently so that failure of one service does not unnecessarily blank unrelated dashboard sections.

### 8. Manual Organization Onboarding

Super Admins can create organizations that are not present in the 294,030-record directory.

The process creates:

```text
Organization
      +
Admin User
```

inside an atomic database transaction.

### 9. Case-Insensitive Search

PostgreSQL `ILIKE` is used for directory searches so users can search organization names, categories, states, and cities without worrying about capitalization.

### 10. Deployment Cost

The current architecture was designed around free-tier services:

```text
Vercel Hobby
+
Render Free
+
Render Free
+
Neon Free
+
GitHub
=
₹0 hosting cost on the selected free tiers
```

Free-tier limits and provider policies may change over time.

---

## 📈 Version History

### `v0.1` — Project Foundation

- [x] Defined project scope and use cases
- [x] Designed database schema and ER diagram
- [x] Set up ASP.NET Core + Entity Framework Core
- [x] Created initial SQL Server implementation
- [x] Set up Flutter project
- [x] Initial project documentation

---

### `v0.25` — Core Frontend & Backend

- [x] JWT authentication
- [x] User registration and login
- [x] Queue, appointment, service, and counter APIs
- [x] Flutter role-based navigation
- [x] User, Admin, and Staff screens
- [x] Glassmorphism UI
- [x] Backend API integration

---

### `v0.5` — Queue Intelligence & Digital Tokens

- [x] Digital queue tokens
- [x] QR-code token generation
- [x] Live queue tracking
- [x] Queue advancement
- [x] Notifications
- [x] Super Admin functionality
- [x] Provider claim workflow

---

### `v0.75` — ML & AI Slot Prediction

- [x] Dataset collection and cleaning
- [x] Linear Regression model
- [x] Random Forest model development
- [x] FastAPI ML service
- [x] .NET → ML API integration
- [x] Smart Slot recommendations
- [x] Admin AI prediction dashboard
- [x] Analytics dashboard

---

### `v0.9` — Initial Azure Deployment

- [x] Initial cloud deployment architecture
- [x] Azure Static Web Apps frontend
- [x] Azure App Service backend
- [x] Azure ML API hosting
- [x] GitHub Actions CI/CD
- [x] Dark / Light Mode
- [x] Profile, About, and Help & Support screens

> Azure was used during an earlier deployment phase. The production architecture was subsequently migrated to the current free-tier Vercel + Render + Neon architecture.

---

### `v1.0` — Production Migration & Final Release

- [x] Migrated production database from SQL Server to PostgreSQL
- [x] Migrated backend to Npgsql / PostgreSQL
- [x] Created fresh Neon production database
- [x] Imported 294,030 Places records into Neon
- [x] Disabled automatic large dataset seeding on application startup
- [x] Deployed ASP.NET Core 9 backend to Render
- [x] Deployed FastAPI ML API to Render
- [x] Deployed Flutter Web application to Vercel
- [x] Connected production deployment to GitHub
- [x] Added Docker-based backend deployment
- [x] Added production environment configuration
- [x] Fixed PostgreSQL UTC DateTime handling
- [x] Fixed production time-slot loading
- [x] Improved JWT/session expiration handling
- [x] Fixed active-token loading
- [x] Improved dashboard independent loading
- [x] Added organization ownership/security checks
- [x] Added manual organization onboarding
- [x] Added automatic organization Admin creation
- [x] Added case-insensitive organization directory search
- [x] Added Android application download QR code
- [x] Updated production web and API endpoints
- [x] Finalized production deployment documentation

---

## 🔄 Current Production Workflow

```text
Developer
   │
   ▼
GitHub — main branch
   │
   ├──────────────► Vercel
   │                  │
   │                  ▼
   │             Flutter Web
   │
   ├──────────────► Render
   │                  │
   │                  ▼
   │            ASP.NET Core API
   │                  │
   │          ┌───────┴────────┐
   │          ▼                ▼
   │       Neon DB        Render ML API
   │                           │
   │                           ▼
   │                     FastAPI + Model
   │
   └──────────────► Source Control
```

Changes pushed to the GitHub repository can trigger deployments through the connected hosting platforms.

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch:

```bash
git checkout -b feature/amazing-feature
```

3. Commit your changes:

```bash
git commit -m "Add amazing feature"
```

4. Push to your fork:

```bash
git push origin feature/amazing-feature
```

5. Open a Pull Request

---

## 📄 License

This project was developed as part of an academic capstone project. All rights reserved.

---

<div align="center">
  <h3>Built by the IntelliQ Team</h3>
  <br/>
  <table>
    <tr>
      <td align="center">
        <b>Devicharan Dasari</b><br>Backend Manager
      </td>
      <td align="center">
        <b>Adityraj Chuadasama</b><br>Frontend Manager
      </td>
      <td align="center">
        <b>Smit Rudakiya</b><br>AI & ML Model Manager
      </td>
    </tr>
  </table>
</div>
