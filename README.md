# 🥗 AI-Powered Personalized Nutrition Mobile App (Flutter, Dart, TensorFlow Lite)

## Overview
This is a cross-platform (iOS/Android) mobile application focused on driving positive dietary change through **real-time computer vision** and a sophisticated recommendation engine. The app utilizes the Flutter framework for a unified experience and integrates a custom **TensorFlow Lite (TFLite)** model for highly efficient, on-device ingredient recognition.

## ✨ Key Technical Features

### 1. On-Device Machine Learning (TensorFlow Lite)
* **Real-Time Ingredient Recognition:** Integrates a custom TFLite model for real-time, low-latency classification of 36+ food categories directly from the mobile camera feed.
* **Model Optimization:** Managed the conversion and optimization of the TensorFlow model to the TFLite format, ensuring minimal app size and high performance on diverse mobile hardware.
* **Image Processing Pipeline:** Implemented the full image acquisition and pre-processing pipeline necessary to feed the camera output reliably into the TFLite model.

### 2. Behavioral Recommendation Engine
* **Multi-Dimensional Personalization:** Utilizes a dynamic algorithm that weighs user input across multiple factors: specific diet goals, cooking skill level, cuisine preference, and allergy restrictions.
* **History Tracking:** Built a 20-point user history system that tracks engagement (likes/skips), modifying the recommendation scores to ensure highly accurate, relevant recipe suggestions over time.
* **Content Delivery:** Designed the Flutter front-end to deliver personalized content quickly, including gesture recognition for easy recipe saving and a clean display of detailed nutritional information.

### 3. Scalable Backend & Architecture
* **Cross-Platform Sync:** Architected a scalable backend using Google Firebase for real-time synchronization of user profiles, recipe data, and behavioral logs across all user devices.
* **Authentication and Data Security:** Implemented secure user authentication and ensured data privacy standards for all stored user information and logs.

## 🛠️ Technologies Used
* **Mobile Framework:** Dart / Flutter
* **Machine Learning:** TensorFlow Lite (Custom Image Recognition Model)
* **Backend:** Google Firebase (Authentication, Real-time Database, Storage)
* **Languages:** Dart

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (Latest Stable Version)
* A physical device (iOS/Android) or simulator/emulator.
* A Firebase Project configured with Authentication and Real-time Database enabled.

### Installation and Run
1.  Clone the repository:
    ```bash
    git clone [https://github.com/Moatsem981/FinalYearPeoject.git]
    cd [FinalYearPeoject]
    ```
2.  Install all required packages:
    ```bash
    flutter pub get
    ```
3.  Configure the Firebase connection files (`google-services.json` for Android and `GoogleService-Info.plist` for iOS) within the project structure.
4.  Run the application:
    ```bash
    flutter run
    ```
---

This template should perfectly showcase your Flutter and TFLite skills! Do you have any other questions about integrating your GitHub profile or updating your CV summary?
