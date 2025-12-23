# 📋 Table of Contents

- About The Project
- Key Features
- Tech Stack
- Project Structure
- Getting Started
- Environment Setup
- Application Features
- PWA Capabilities
- Backend & Cloud Integration
- Team Contributions
- Development Workflow
- Deployment
- License
- Contact
- Acknowledgments

---

## 🎯 About The Project

The **Peer-to-Peer (P2P) Tutoring Application** is a student-centered academic support platform designed to connect learners who need help in specific courses with fellow students who can tutor them.

The system encourages **collaborative learning**, **knowledge sharing**, and **academic mentorship** within a university environment, using **Babcock University** as the case study.

### Core Objectives

- Improve students’ academic performance through peer tutoring
- Provide an accessible platform for booking and managing tutoring sessions
- Promote collaborative and supportive learning communities
- Digitize and streamline the tutoring process

### Key Highlights

📚 Course-based tutor matching

👥 Role-based users (Tutor, Tutee, Admin)

📅 Session scheduling and management

💬 In-app communication and feedback

📱 Mobile-first & cross-platform experience

🔐 Secure authentication and data protection

☁️ Cloud-hosted backend for scalability

---

## ✨ Key Features

### 🎓 User Management

- Student registration as **Tutor**, **Tutee**, or both
- Secure authentication and profile management
- Tutor verification and approval by admin

### 🔍 Tutor Discovery & Matching

- Search tutors by course or subject
- View tutor profiles, availability, and ratings
- Intelligent matching based on user preferences

### 📅 Session Scheduling

- Request, accept, or reject tutoring sessions
- Reschedule or cancel sessions
- View upcoming and completed sessions

### 💬 Communication & Feedback

- In-app messaging between tutors and tutees
- Session status notifications
- Post-session feedback and ratings

### 🛡️ Administration

- Admin dashboard for system oversight
- Manage users, tutors, and sessions
- Monitor platform usage and performance

---

## 🛠️ Tech Stack

### Frontend

- **Flutter** – Cross-platform UI framework
- **Dart** – Programming language
- **Material UI** – Responsive design components

### Backend & Cloud (AWS)

- **Amazon Cognito** – Authentication & authorization
- **AWS Lambda** – Serverless business logic
- **Amazon API Gateway** – RESTful APIs
- **Amazon RDS** – Relational database
- **Amazon CloudWatch** – Monitoring & logging

### Development Tools

- Git & GitHub – Version control
- Figma – UI/UX design
- Postman – API testing

---

## 📁 Project Structure

```
P2P_TUTORING_APP/
├── frontend/
│   ├── lib/
│   │   ├── screens/            # UI screens
│   │   ├── widgets/            # Reusable widgets
│   │   ├── models/             # Data models
│   │   ├── services/           # API & auth services
│   │   ├── providers/          # State management
│   │   └── utils/              # Helper utilities
│   └── main.dart
│
├── backend/
│   ├── auth/                   # Cognito setup
│   ├── lambdas/                # Lambda functions
│   ├── api/                    # API Gateway configs
│   └── database/               # RDS schemas
│
├── docs/                       # Diagrams & documentation
├── README.md

```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- AWS Account
- Git
- VS Code or Android Studio

### Installation

```bash
git clone https://github.com/your-repo/p2p-tutoring-app.git
cd p2p-tutoring-app
flutter pub get
flutter run

```

---

## 🔧 Environment Setup

### AWS Configuration

1. Create an AWS account
2. Set up Amazon Cognito User Pool
3. Create API Gateway endpoints
4. Deploy Lambda functions
5. Configure Amazon RDS database

### Environment Variables

```
AWS_REGION=us-east-1
COGNITO_USER_POOL_ID=xxxx
COGNITO_CLIENT_ID=xxxx
API_BASE_URL=https://api.example.com
DB_ENDPOINT=xxxx

```

---

## 🎯 Application Features

### 1. Authentication System

- Secure signup and login
- Role-based access control
- Persistent user sessions

### 2. Dashboard

- Personalized user dashboard
- Upcoming session overview
- Notifications and alerts

### 3. Tutor Profiles

- Course expertise listing
- Availability scheduling
- Ratings and reviews

### 4. Tutoring Sessions

- Session booking and approval
- Session history tracking
- Feedback after sessions

### 5. Administration

- Tutor approval management
- User moderation
- System monitoring

---

## 📱 PWA Capabilities

_(Optional extension for future scalability)_

- Installable on mobile and desktop
- Offline viewing of cached content
- App-like experience

---

## ☁️ Backend & Cloud Integration

### Authentication Flow

User Registration → Cognito Verification → Role Assignment → Dashboard

### Database Structure (RDS)

- **Users** (userId, role, profile data)
- **Tutors** (subjects, availability, ratings)
- **Sessions** (date, time, status, feedback)
- **Messages** (sender, receiver, timestamp)

### Security Highlights

- Role-based authorization
- Encrypted API communication
- Secure credential handling

---

## 👥 Team Contributions

This project was developed as a **group academic project (3 members)**.

### 🧑‍💻 Member 1 – Project Lead & Authentication

- Project coordination
- Authentication & authorization
- System architecture

### 👤 Member 2 – User Profiles & Roles

- Tutor and tutee profile management
- Role-based permissions

### 📋 Member 3 – Tutor Discovery & Matching

- Search and filtering system
- Tutor availability logic

### 📅 Member 1 – Session Scheduling

- Booking and rescheduling
- Session status management

### 💬 Member 2 – Communication & Feedback

- Messaging system
- Ratings and reviews

### 🛡️ Member 3 – Administration Module

- Admin dashboard
- User and tutor management

### 🎨 Member 1 – UI/UX Design

- Application layouts
- User experience optimization

### 🔧 Member 2 & 3 – Testing & Documentation

- System testing
- Documentation and diagrams

---

## 🔄 Development Workflow

- **Agile Scrum methodology**
- Sprint-based development
- Git feature-branch workflow

### Commit Convention

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code restructuring

---

## 🚀 Deployment

### Backend

- Deployed on **AWS Cloud**
- Lambda + API Gateway + RDS

### Frontend

- Built with Flutter
- Deployed on emulator, APK, or web

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](https://github.com/BU-SENG/foss-project-blue-rush/blob/main/LICENSE) file for details.

---

## 📞 Contact

**Project Lead**

…

📧 Email: …

🐙 GitHub: @|Authur|

**Repository**

🔗 Project Link: https://github.com/lAuthurl/p2p-tutoring-app.git

**Live Application**

🌐 Live Demo: …

---

## 🙏 Acknowledgments

- Flutter Documentation
- AWS Documentation
- Academic Supervisors
- Peer reviewers and testers

---
