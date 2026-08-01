# IntelliQ — PPT Content Guide (20 Slides)

---

## Slide 1: Title Slide

- **Title:** IntelliQ: Smart Queue Prediction System
- **Subtitle:** AI-Driven Digital Queue Management for Hospitals, Banks & Government Offices
- **Your Name, Roll No, Branch**
- **Guide Name & Designation**
- **College Name, Department, Academic Year (2025–26)**
- *(Place your IntelliQ logo)*

---

## Slide 2: Abstract

**Key Points:**
- IntelliQ is a full-stack intelligent queue management platform designed to **eliminate physical wait times** at service centers
- Combines **real-time queue tracking**, **digital tokens (QR-based)**, and **AI-driven time slot recommendations**
- Built with **Flutter (Dart)** for the mobile/web frontend and **.NET 8 (C#) ASP.NET Core** for the backend REST API
- Uses **SQL Server** with Entity Framework Core for data persistence
- Supports **4 user roles** — User, Admin, Staff, and Super Admin — each with role-specific dashboards
- Pre-seeded with real-world datasets of **1 lakh+ Indian service locations** (hospitals, banks, colleges, restaurants) — no dependency on paid map APIs

---

## Slide 3: Problem Statement

**Key Points:**
- People waste **hours standing in queues** at hospitals, banks, and government offices every day
- **No visibility** — customers don't know their position, estimated wait time, or how crowded a place is
- **Manual token systems** (paper slips) are error-prone, non-trackable, and offer zero remote tracking
- **Staff inefficiency** — no data-driven way to manage counter allocation, peak hours, or staffing
- **No smart scheduling** — users have no guidance on when to visit to avoid crowds
- **Post-COVID reality** — physical crowding creates health risks; digital-first solutions are essential

---

## Slide 4: Objectives

**Key Points:**
1. Develop a **cross-platform app** (Android, iOS, Web) for digital queue management
2. Implement **real-time queue tracking** so users can monitor their position remotely
3. Build an **AI-based time slot recommendation engine** that predicts crowd levels and suggests optimal visit times
4. Provide **QR-code digital tokens** for contactless, paperless check-in
5. Create **role-based dashboards** for users, staff, admins, and platform super admins
6. Use **pre-loaded datasets** of Indian service locations to enable smart search and discovery without third-party APIs
7. Ensure **secure authentication** using JWT tokens with BCrypt password hashing

---

## Slide 5: Literature Review (Part 1)

| # | Paper/System | Year | Key Idea | Limitation |
|---|-------------|------|----------|------------|
| 1 | **"Smart Queue Management System using IoT"** — Various IEEE authors | 2020 | Uses IoT sensors + LCD displays to show queue position at physical locations | Requires hardware installation; no mobile tracking; no AI prediction |
| 2 | **"Queue Management using Machine Learning"** — Research papers on ML-based crowd prediction | 2021 | Applies ML models (Random Forest, LSTM) to predict queue wait times from historical data | Complex model training required; no real-time app integration; academic prototypes only |
| 3 | **Google Reserve / Apple Business Chat** | 2019–present | Allows booking appointments at businesses via Google Maps / Apple Messages | Limited to partnered businesses; no live queue position; no AI slot suggestion |

---

## Slide 6: Literature Review (Part 2)

| # | Paper/System | Year | Key Idea | Limitation |
|---|-------------|------|----------|------------|
| 4 | **"Hospital Queue Management System"** — Android-based projects | 2022 | Android app for hospital OPD token booking and notifications | Single-domain (hospital only); no multi-role support; no web version |
| 5 | **"Digital Token System for Banks"** — Research on bank queue digitization | 2021 | Digital token generation and SMS-based position updates for bank branches | Bank-specific; no cross-domain solution; no AI; no staff-side counter management |

**Gap Identified:**
> No existing system provides a **unified, cross-domain** (hospital + bank + govt) platform with **AI-based slot prediction**, **live queue tracking**, **role-based dashboards**, and **QR-code digital tokens** — all in a single, production-ready app. IntelliQ fills this gap.

---

## Slide 7: Existing System vs Proposed System

| Aspect | Existing Systems | IntelliQ (Proposed) |
|--------|-----------------|-------------------|
| **Scope** | Single domain (hospital OR bank) | Multi-domain (Hospital, Bank, Govt, College, Restaurant) |
| **Queue Tracking** | Paper tokens / SMS updates | Real-time live tracking with position + ETA |
| **AI / Smart Scheduling** | None | AI-scored time slots with crowd prediction |
| **Digital Tokens** | Basic token numbers | QR-code based digital tokens |
| **Multi-Role** | User only | User, Staff, Admin, Super Admin |
| **Platform** | Android only | Cross-platform (Android, iOS, Web) via Flutter |
| **Counter Management** | Manual | Digital counter assignment with staff mapping |
| **Location Discovery** | Google Maps API (paid) | Pre-loaded dataset of 1L+ real Indian locations |
| **Authentication** | Basic login | JWT + BCrypt role-based secure auth |

---

## Slide 8: Technology Stack

| Layer | Technology | Why Chosen |
|-------|-----------|------------|
| **Frontend** | Flutter (Dart) | Single codebase → Android, iOS, Web |
| **Backend** | .NET 8 ASP.NET Core Web API | High-performance, industry-standard REST API framework |
| **Database** | SQL Server + EF Core | Relational integrity with code-first migrations |
| **Authentication** | JWT + BCrypt | Stateless, secure, role-based access control |
| **State Management** | Provider (ChangeNotifier) | Simple, reactive UI state in Flutter |
| **Routing** | GoRouter | Declarative URL-based navigation |
| **QR Generation** | qr_flutter | Generate scannable digital tokens |
| **Tunneling** | LocalTunnel | Expose localhost to physical devices during development |
| **API Documentation** | Scalar (OpenAPI) | Interactive API explorer for backend testing |

---

## Slide 9: System Architecture

**Key Points (describe with a diagram):**

```
┌─────────────────────────────────────────────────┐
│                FLUTTER APP                       │
│  (Android / iOS / Web)                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────────────┐│
│  │ User     │ │ Admin    │ │ Staff / SuperAdmin││
│  │ Screens  │ │ Screens  │ │ Screens          ││
│  └────┬─────┘ └────┬─────┘ └────┬─────────────┘│
│       └─────────┬──┘            │               │
│           ApiService (HTTP)     │               │
│           AuthProvider (State)  │               │
└───────────────┬─────────────────┘               │
                │  REST API (JSON over HTTPS)      │
                │  JWT Bearer Token in headers     │
                ▼                                  │
┌─────────────────────────────────────────────────┐
│            .NET 8 ASP.NET CORE API              │
│  ┌────────────┐ ┌────────────┐ ┌─────────────┐ │
│  │ Controllers│ │ Services   │ │ DTOs        │ │
│  │ (Auth,     │ │ (AuthSvc,  │ │ (Request/   │ │
│  │  Queue,    │→│  QueueSvc, │→│  Response   │ │
│  │  Provider) │ │  Dashboard)│ │  Objects)   │ │
│  └────────────┘ └─────┬──────┘ └─────────────┘ │
│                       │                          │
│              Entity Framework Core               │
│                       │                          │
└───────────────────────┼──────────────────────────┘
                        ▼
              ┌──────────────────┐
              │   SQL Server DB  │
              │   (IntelliQDb)   │
              │   9 Tables       │
              └──────────────────┘
```

**Flow:** Flutter App → HTTP + JWT → ASP.NET Controllers → Business Services → EF Core → SQL Server

---

## Slide 10: Database Design

**Key Points:**
- **9 tables** in the database: Users, ServiceProviders, Services, TimeSlots, Appointments, QueueTokens, ServiceCounters, Notifications, ActivityLogs
- **Entity Framework Core** Code-First approach — models defined in C#, migrations auto-generate SQL schema
- **Key relationships:**
  - `ServiceProvider` → has many `Services` → each has many `TimeSlots`
  - `User` → books `Appointments` → generates `QueueTokens`
  - `ServiceCounter` → assigned to a `Staff User` → serves one `QueueToken` at a time
  - `Notifications` → linked to `User` for in-app alerts
  - `ActivityLogs` → audit trail for staff/admin actions

*(Include the ER Diagram from the walkthrough artifact)*

---

## Slide 11: Module 1 — User Module

**Key Points:**
- **Registration & Login** — Email/mobile + password with BCrypt hashing
- **Smart Search** — Browse 1L+ real locations by category (Hospital/Bank/Govt), state, city, and keyword
- **Appointment Booking** — Select provider → pick service → choose date → view time slots → book
- **AI Smart Slots** — Time slots ranked by AI score; low crowd = high recommendation
- **Digital Token** — QR code generated with appointment details for contactless check-in
- **Live Queue Tracking** — Real-time position, estimated wait time, timeline progress (Booked → CheckedIn → Waiting → Serving → Completed)
- **Notification Center** — Booking confirmations, queue updates, AI suggestions, reminders
- **Profile Management** — Edit personal details, change password
- **Appointment History** — View all past visits with status

---

## Slide 12: Module 2 — Admin Module

**Key Points:**
- **Admin Dashboard** — Overview of today's visitors, active queues, completed visits, average wait time
- **Queue Management** — View live queue for their provider; see who's being served and who's waiting
- **Appointment Management** — View all appointments booked at their organization
- **Service Management** — Add new services, edit details (name, duration, cost), toggle active/inactive, delete
- **Staff & Counter Management** — Create staff accounts (auto-generates credentials), create physical counter entries, assign staff to counters
- **Analytics Dashboard** — Visitor trends, peak hour analysis, service-wise breakdown
- **AI Prediction Dashboard** — Crowd level forecasts, recommended number of counters to open
- **Role Management** — Promote users to Staff/Admin within their provider

---

## Slide 13: Module 3 — Staff Module

**Key Points:**
- **Staff Dashboard** — Shows assigned counter number, counter status (Active/On Break/Offline), today's customer count, currently serving token
- **Queue Operations:**
  - **Call Next** — Pulls the next `InQueue` token, assigns it to staff's counter, marks it as `Serving`
  - **Complete** — Marks current token as `Completed`, clears the counter, increments today's count
  - **Skip/Absent** — Marks no-show customer as `Cancelled`, clears counter
- After each operation, **all remaining queue positions are recalculated** automatically
- Every action is logged in `ActivityLogs` for audit

---

## Slide 14: Module 4 — Super Admin Module

**Key Points:**
- **Platform-wide oversight** — views all registered providers across the platform
- **Provider Onboarding** — Create new service providers (hospitals, banks, etc.) with auto-generated admin credentials
- **Provider Deletion** — Remove providers and all associated users, services, counters
- **Platform Analytics** — Total providers, total users, total appointments, active queues across the entire system
- Super Admin has **no ProviderId** — they are not tied to any specific organization

---

## Slide 15: LocalTunnel & Deployment Architecture

**Key Points:**
- **Problem:** .NET backend runs on `localhost:5164`; physical phones cannot reach `localhost`
- **Solution:** **LocalTunnel** creates a public HTTPS URL (e.g., `https://solid-waves-agree.loca.lt`) that tunnels to `localhost:5164`
- **How it works:**
  ```
  Physical Phone → loca.lt URL → Internet → Tunnel Server → localhost:5164
  ```
- **Smart URL switching** in the app:
  - Web browser → uses `localhost:5164` directly
  - Physical device → uses LocalTunnel URL
- **Bypass header:** `Bypass-Tunnel-Reminder: true` — skips LocalTunnel's interstitial warning page
- **Free** and requires **no cloud deployment** — perfect for development and demos

---

## Slide 16: AI-Based Smart Slot Recommendation

**Key Points:**
- **Goal:** Help users pick the **least crowded** time to visit
- **How it works:**
  - For each active service, **hourly time slots** are generated for the next 7 days (9 AM – 5 PM)
  - Each slot has a `CrowdLevel` (0.0–1.0) based on historical patterns:
    - Peak hours (10 AM–12 PM) → `0.8` (high crowd)
    - Moderate hours (2 PM–3 PM) → `0.6`
    - Off-peak hours → `0.3` (low crowd)
  - **AI Score = 1.0 − CrowdLevel** → higher score = better time to visit
  - Available slots decrease as more people book: `AvailableSlots = TotalSlots × (1 − CrowdLevel × 0.7)`
- **User experience:** Smart Slot screen sorts by AI score and visually highlights **recommended** (green) vs **avoid** (red) slots
- **Future scope:** Replace static patterns with ML models trained on real booking data

---

## Slide 17: Screenshots / Demo

**Key Points to show:**
- Splash Screen & Login
- Home Dashboard (active queues, stats cards)
- Service Selection (browse hospitals/banks with filters)
- Appointment Booking (service picker, date, time slots)
- Smart Slot Screen (AI-ranked slots with color coding)
- Digital Token with QR Code
- Live Queue Tracking (position, estimated wait, timeline)
- Admin Dashboard (stats overview)
- Staff Queue Screen (Call Next / Complete / Skip)
- Super Admin Dashboard (platform-wide view)

*(Use screenshots from your running app or the design mockups in `stitch_softqueue_ai_manager/` folder)*

---

## Slide 18: Testing & Results

**Testing Approaches:**
| Type | What Was Tested |
|------|----------------|
| **Unit Testing** | Service layer logic (token generation, queue position recalculation, BCrypt password verification) |
| **API Testing** | All 40+ REST endpoints tested via Scalar (OpenAPI) interactive documentation |
| **Integration Testing** | End-to-end flows: register → login → book appointment → join queue → staff call next → complete |
| **Cross-Platform Testing** | Tested on Android emulator, physical Android device (via LocalTunnel), and Web browser |
| **Role-Based Access Testing** | Verified JWT role claims restrict Staff, Admin, SuperAdmin endpoints correctly |

**Results:**
- Successfully handled **concurrent queue operations** without data inconsistency
- Token position recalculation works correctly after each call-next/complete/skip
- AI slot recommendations correctly rank least-crowded time slots
- QR code generation and display works across all platforms
- LocalTunnel-based testing successful on physical devices

---

## Slide 19: Advantages, Limitations & Future Scope

### ✅ Advantages
- **Zero physical waiting** — track queue remotely from anywhere
- **Cross-domain** — works for hospitals, banks, govt offices, colleges, restaurants
- **AI-powered** — smart slot recommendations reduce crowd exposure
- **Cross-platform** — single Flutter codebase for Android, iOS, and Web
- **No paid APIs** — uses pre-loaded datasets instead of Google Maps
- **Secure** — JWT + BCrypt industry-standard authentication
- **Scalable** — clean architecture with service layer separation

### ⚠️ Limitations
- AI prediction currently uses **static patterns** (not trained ML models)
- **LocalTunnel dependency** for physical device testing (not production-ready)
- **No push notifications** — currently only in-app notifications
- **No payment integration** — service costs shown but not collected
- **Single-server** — no horizontal scaling or load balancing

### 🚀 Future Scope
- Train **ML models** (LSTM/Random Forest) on real booking data for dynamic crowd prediction
- Add **push notifications** via Firebase Cloud Messaging
- Integrate **payment gateway** (Razorpay/Stripe) for service fees
- Deploy to **cloud** (Azure/AWS) with CI/CD pipeline
- Add **Google Maps integration** for directions to provider locations
- Implement **feedback/rating system** for completed visits
- Add **multi-language support** (Hindi, Telugu, etc.)

---

## Slide 20: Conclusion & References

### Conclusion
- IntelliQ successfully demonstrates a **complete, working smart queue management system** that addresses the real-world problem of physical waiting
- The system integrates **AI-based crowd prediction**, **live queue tracking**, **QR-code digital tokens**, and **multi-role dashboards** into a unified cross-platform application
- With **4 user roles**, **9 database tables**, **40+ API endpoints**, and **29 screens**, the project showcases end-to-end software engineering from database design to mobile UI
- The dataset-backed approach (1L+ locations) proves that **practical, cost-effective solutions** can be built without expensive third-party APIs

### References
1. Flutter Documentation — https://docs.flutter.dev
2. ASP.NET Core Documentation — https://learn.microsoft.com/aspnet/core
3. Entity Framework Core — https://learn.microsoft.com/ef/core
4. JWT Authentication — RFC 7519 (https://datatracker.ietf.org/doc/html/rfc7519)
5. BCrypt Password Hashing — https://en.wikipedia.org/wiki/Bcrypt
6. LocalTunnel — https://localtunnel.me
7. GoRouter for Flutter — https://pub.dev/packages/go_router
8. QR Flutter — https://pub.dev/packages/qr_flutter
9. Scalar API Documentation — https://scalar.com
10. IEEE papers on Smart Queue Management Systems (2020–2023)

---

> [!TIP]
> **Presentation Tips:**
> - Keep each slide **visual** — use diagrams, tables, and screenshots instead of paragraphs
> - For the Architecture slide, draw a proper layered diagram in PowerPoint
> - For the Database slide, use the ER diagram
> - For the Demo slide, embed actual screenshots or do a **live demo**
> - Time allocation: ~1.5 minutes per slide = **30 minutes total**
