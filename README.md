# my_app

UCS Collab: Space Booking Application

## Getting Started

Project Overview
UCS Collab is a comprehensive mobile application designed for University Centre Somerset that streamlines the process of booking study and work spaces across multiple campuses. Developed to address the challenges faced by students and staff in finding suitable workspaces, this application provides a centralized platform for viewing, filtering, and reserving various types of spaces based on specific requirements.
The application aims to enhance the independent study experience, encourage peer-led collaboration, and support commuting staff with a suitable work environment. UCS Collab focuses on accessibility, usability, and ethical data management to ensure it meets the diverse needs of the entire campus community.
Key Features
For Students and Staff

User authentication with secure email and password protection
Real-time space availability across all UCS campuses
Advanced filtering by location, capacity, equipment, and features
Detailed space information with photos and descriptions
Intuitive date and time selection for bookings
Personal booking management dashboard
Accessibility options including text size adjustment and dark mode

For Administrators

Comprehensive administrative dashboard with usage analytics
Space management (add, edit, remove spaces and their features)
Booking approval and management system
User account administration
System configuration and maintenance tools

Technical Specifications
Development Framework
UCS Collab is built using Flutter, providing a consistent experience across iOS and Android devices with a single codebase. The application follows a modular architecture with clear separation between presentation, business logic, and data layers.
Backend Infrastructure
Firebase services power the application backend:

Firebase Authentication for secure user management
Cloud Firestore for real-time data storage
Firebase Storage for image management
Cloud Functions for booking validation and business rules

Security and Data Protection
The application implements comprehensive security measures in accordance with UK data protection legislation:

Encrypted data storage and transmission
Role-based access control
Data minimization principles
Regular security audits
Compliance with GDPR requirements

Accessibility Features
UCS Collab prioritizes inclusivity through:

WCAG-compliant interface elements
Customizable text display options
Dark mode for reduced eye strain
Screen reader compatibility
Keyboard navigation support

Development Methodology
The application was developed using the Agile methodology with the Scrum framework, allowing for iterative development and continuous improvement. The design process followed the Double Diamond approach to ensure user needs remained central to all development decisions.
Installation Requirements
Prerequisites

Flutter SDK (version 3.0.0 or higher)
Dart (version 2.17.0 or higher)
Android Studio or VS Code with Flutter extensions
Firebase CLI for backend configuration

Setup Instructions

Clone the repository
Run flutter pub get to install dependencies
Configure Firebase project settings
Run flutter run to launch the application in development mode

Future Development
The current implementation serves as a prototype with potential for expansion. Future development plans include:

Integration with university timetabling systems
Advanced analytics for space utilization optimization
Push notifications for booking reminders
QR code check-in/check-out system
Integration with campus mapping services

Legal and Ethical Considerations
UCS Collab has been designed with ethical considerations at its core, including:

Data minimization and protection
Transparent user consent framework
Fair resource allocation
Inclusive design principles
Regular ethical reviews

Project Contributors
Developed by Sarunas Slekys as part of a university project for University Centre Somerset, incorporating guidance from academic staff and industry best practices.

This project is designed as an educational prototype and demonstration of mobile application development capabilities. Implementation in a production environment would require additional security reviews and integration with existing university systems.