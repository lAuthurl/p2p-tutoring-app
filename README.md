# 🎓 Peer-to-Peer (P2P) Tutoring Application

> A cross-platform academic support platform that connects students with peer tutors for collaborative learning.

---

## 📋 Table of Contents

* 🎯 About The Project
* ✨ Key Features
* 🛠️ Tech Stack
* 📁 Project Structure
* 🚀 Getting Started
* 🔧 Environment Setup
* 🎯 Application Features
* 📱 PWA Capabilities
* ☁️ Backend & Cloud Integration
* 👥 Team Contributions
* 🔄 Development Workflow
* 🚀 Deployment
* 📄 License
* 📞 Contact
* 🙏 Acknowledgments

---

## 🎯 About The Project

The **Peer-to-Peer (P2P) Tutoring Application** is designed to connect students who need help in specific courses with peers who can tutor them.

It promotes:

* 🤝 Collaborative learning
* 📚 Knowledge sharing
* 🎯 Academic improvement

Built with a **mobile-first approach**, the app delivers a seamless experience across devices.

---

## ✨ Key Features

### 🎓 User Management

* Register as both **Tutor** and **Tutee**
* Secure authentication
* Profile management

### 🔍 Tutor Discovery

* Search by course or subject
* View tutor profiles and ratings

### 📅 Session Booking

* Book, or cancel bookings
* Track upcoming sessions

### 💬 Communication

* In-app messaging
* Notifications
* Feedback & ratings

### 💳 Payments

* Integrated with **Paystack**

---

## 🛠️ Tech Stack

### 📱 Frontend

* Flutter (Dart)
* Material UI

### ☁️ Backend & Cloud

* AWS Amplify
* Amazon Cognito
* AWS Lambda
* API Gateway
* Amazon RDS
* CloudWatch

### 🧰 Tools

* Git & GitHub
* VS Code / Android Studio
* Postman

---

## 📁 Project Structure

<details>
<summary>📂 Click to expand</summary>

```
p2p_tutoring_app/
├── android/
├── ios/
├── web/
├── macos/
├── windows/
├── linux/
├── lib/
│   ├── Feautures/
│   │   ├── booking/
│   │   ├── chat/
│   │   ├── checkout/
│   │   ├── dashboard/
│   │   ├── favourites/
│   │   ├── sessions/
│   │   └── Tutor/
│   ├── common/
│   ├── widgets/
│   ├── models/
│   ├── services/
│   ├── bindings/
│   ├── data/
│   ├── personalization/
│   ├── routes/
│   ├── authentication/
│   ├── utils/
│   ├── app.dart
│   ├── main.dart
│   └── amplifyconfiguration.dart
├── backend/
│   ├── auth/
│   ├── lambdas/
│   ├── api/
│   └── database/
├── docs/
├── pubspec.yaml
├── README.md
```

</details>

---

## 🚀 Getting Started

### ✅ Prerequisites

* Flutter SDK
* Dart SDK
* Git
* AWS Account
* VS Code / Android Studio

### ⚙️ Installation

```bash
git clone https://github.com/lAuthurl/p2p-tutoring-app.git
cd p2p-tutoring-app
flutter pub get
flutter run
```

---

## 🔧 Environment Setup

### ☁️ AWS Configuration

* Configure Amplify
* Set up Cognito
* Configure API Gateway & Lambda
* Set up database

### 🔑 Environment Variables

```
AWS_REGION=us-east-1
COGNITO_USER_POOL_ID=xxxx
COGNITO_CLIENT_ID=xxxx
API_BASE_URL=https://api.example.com
DB_ENDPOINT=xxxx
```

---

## 🎯 Application Features

The application provides a robust set of features to support peer-to-peer tutoring, powered by a **mobile-first interface** and a **schema-driven backend**:

* 🔐 **Authentication & User Roles** – Secure signup/login and profile management
* 📊 **Session Tracking Dashboard** – View upcoming and completed sessions, track bookings, and session status
* 👤 **Tutor Profiles** – Detailed tutor information including skills, bio, availability, and ratings
* 📅 **Booking System** – Book tutoring sessions with flexible time slots and session attributes
* 💬 **In-App Messaging** – Communicate in real-time with tutors or tutees for coordination and support
* ⭐ **Ratings & Feedback** – Submit reviews after sessions to ensure quality and build tutor reputation
* 💳 **Payments & Transactions** – Manage payments via Paystack and track session payment history

---

## 📱 App Capabilities

* 🔄 **Live Data Synchronization** – Instant updates for chats, bookings, and tutor availability
* 🌐 **Online-First Architecture** – Designed for continuous connectivity to maintain data accuracy
* ⚡ **Scalable Cloud Performance** – Powered by AWS for reliability, speed, and growth

---

## ☁️ Backend & Cloud Integration

### 🔐 Authentication Flow

`Register → Verify → Role Assignment → Access App`

---

## 🗄️ Database Structure

The application uses a **relational, model-driven schema (AWS Amplify GraphQL)** with the following core entities:

### 👤 User

* Stores user profile and authentication-related data
* Supports roles (Tutor / Tutee)
* Linked to bookings, reviews, and activity

### 🎓 Tutor

* Represents tutor-specific profile data
* Contains skills, bio, and teaching information
* Linked to sessions and reviews

### 📚 Subject

* Defines available courses or subjects
* Connected to tutoring sessions

### 🧑‍🏫 TutoringSession

* Core entity for tutoring services
* Linked to tutor and subject
* Contains pricing, availability, and session details
* Tracks enrollment and reviews

### 📅 Booking

* Represents a user’s session booking
* Stores total price, status, and selected options
* Linked to user and session

### 🧾 BookingItem

* Detailed breakdown of each booking
* Includes time slot, pricing, tutor/session info
* Supports flexible session configurations

### ⚙️ SessionAttribute

* Custom attributes for sessions (e.g., duration, format)
* Enhances session flexibility

### ⭐ Review

* Stores ratings and feedback
* Linked to user, tutor, and session

### 💬 ChatMessage

* Handles in-app messaging
* Supports text and voice messages
* Organized per session

### ❤️ UserFavorite

* Allows users to save/bookmark sessions

### 💳 UserSessionPayment

* Tracks payment status for sessions
* Stores transaction details (amount, reference, date)

---

### 🔗 Relationship Overview

* A **User** can create multiple **Bookings**, **Reviews**, and **Favorites**
* A **Tutor** can have multiple **TutoringSessions** and **Reviews**
* A **TutoringSession** belongs to a **Tutor** and a **Subject**
* A **Booking** contains multiple **BookingItems**
* A **Review** connects **User + Tutor + Session**
* A **ChatMessage** is tied to a specific **Session**

---

### 🔒 Security

* Role-based access
* Encrypted communication
* Secure credentials

---

## 👥 Team Contributions

* **Member 1 – Project Lead & Authentication:** coordination, system architecture, auth
* **Member 2 – User Profiles & Roles:** tutor/tutee management, permissions
* **Member 3 – Tutor Discovery & Matching:** search/filter, availability logic
* **Member 1 – Session booking:** booking
* **Member 2 – Communication & Feedback:** messaging, ratings
* **Member 1 – UI/UX Design:** layouts, experience optimization
* **Member 2 & 3 – Testing & Documentation:** testing, diagrams

---

## 🔄 Development Workflow

The project follows a **structured, feature-focused workflow** to ensure smooth development and consistency across the application.

### ⚙️ Workflow Process

* 🧩 **Feature Breakdown** – Tasks are divided into core features such as booking, messaging, and payments
* 🎨 **Implementation** – UI and logic are developed using Flutter components (screens, controllers, widgets)
* 🔗 **Integration** – Features are connected to backend services and existing data models
* 🧪 **Testing** – Each feature is tested to ensure proper functionality and data accuracy

### 🌿 Version Control

* Work is organized using feature branches:

  ```bash
  git checkout -b feature/your-feature
  ```
* Changes are committed using standard conventions (see below)

### 🚀 Delivery Flow

* Completed features are reviewed and merged into the main branch
* Updates are deployed to keep the application in sync

---

### 📝 Commit Convention

```
feat: New feature
fix: Bug fix
docs: Documentation
refactor: Code improvement
```

---

## 🚀 Deployment

### ☁️ Backend (AWS Amplify)

```bash
npm install -g @aws-amplify/cli
amplify configure
amplify init
```

```bash
amplify add auth
amplify add storage
amplify add api
```

```bash
amplify push
```

---

### 🌐 Frontend (GitHub)

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/lAuthurl/p2p-tutoring-app.git
git branch -M main
git push -u origin main
```

---

## 📄 License

MIT License

---

## 📞 Contact

**Project Lead**
📧 Email: …
🐙 GitHub: @Authur

🔗 Repository:
[https://github.com/lAuthurl/p2p-tutoring-app.git](https://github.com/lAuthurl/p2p-tutoring-app.git)

---

## 🙏 Acknowledgments

We gratefully acknowledge the following contributions and resources that made this project possible:

* **Flutter Documentation** – for guiding the cross-platform UI and widget design
* **AWS Documentation** – for support with Amplify, Cognito, Lambda, API Gateway, and RDS integration
* **Academic Supervisors** – for mentorship, feedback, and guidance throughout the project
* **Peer Testers and Contributors** – for rigorous testing, suggestions, and helping refine the user experience
* **Open-Source Libraries & Community** – including Paystack, `qr_flutter`, and other Dart/Flutter packages that accelerated development
* **Schema & Architecture Inspiration** – conceptual frameworks and best practices that informed our relational model design and workflow

---