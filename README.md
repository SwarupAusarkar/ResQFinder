# 🚨 ResQFinder – Emergency Resource Locator

ResQFinder is a **high-stakes emergency coordination platform** designed to bridge the gap between people in critical need and nearby medical resource providers such as **Hospitals, Blood Banks, and Pharmacies**.

Unlike traditional delivery or listing platforms, ResQFinder operates on a **Competitive Offer Lifecycle**, ensuring that emergency requests are fulfilled **fast, reliably, and with accountability**.

---

## 🧠 Problem Statement

During medical emergencies, patients and families often struggle to:

* Find nearby hospitals with available ICU beds or ventilators
* Locate blood banks with rare blood groups in real time
* Coordinate quickly under stress
* Avoid calling multiple hospitals manually

ResQFinder solves this by **broadcasting emergency needs**, **collecting competing offers**, and **locking verified resources** until the emergency is resolved.

---

## 🌟 Core Features

### 👤 For Requesters (Patients / Emergency Contacts)

* **Medical Emergency Passport**
  Securely store and instantly share:

  * Blood group
  * Allergies
  * Chronic conditions
  * Emergency notes

* **Smart Emergency Broadcast**
  Broadcast urgent requests (ICU beds, oxygen, blood units, medicines) to providers within a configurable radius (0.5 km – 10 km).

* **Offer Marketplace**
  Receive multiple offers from nearby providers and select the best one based on:

  * Distance
  * Resource availability
  * Capability

* **Emergency Contact Alerts**
  Automatically notify saved emergency contacts when a broadcast is initiated.

---

### 🏥 For Providers (Hospitals / Clinics / Blood Banks)

* **Real-time Emergency Dashboard**
  View incoming emergency requests in the immediate vicinity.

* **Live Inventory Management**
  Manage critical resources such as:

  * ICU / General Beds
  * Blood units (group-wise)
  * Oxygen cylinders

* **Reserve & Offer System**
  When a provider makes an offer, the requested inventory is **temporarily locked** to prevent overbooking.

---

## 🔄 Emergency Request Lifecycle (Core Architecture)

ResQFinder follows a **5-stage request lifecycle** optimized for speed, fairness, and consistency.

### 1️⃣ Broadcast (Pending)

* A requester broadcasts an emergency need (e.g., `2 units of O+ blood`).
* The request is sent to all providers within the selected radius.

---

### 2️⃣ Offer Phase

* Providers can view the request and choose to **Accept**.
* Accepting creates a unique **Offer Object** linked to the request.
* Provider inventory is **temporarily decremented (locked)**.

---

### 3️⃣ Handshake (Approval Window)

* The requester receives multiple offers.
* A **5-minute approval window** is provided to select one offer.

🔁 **Auto-Rollback Logic**:

* If the user selects a different provider or the window expires:

  * Inventory for rejected providers is automatically restored.

---

### 4️⃣ Verification (Confirmed)

* Upon approval, the system generates a **unique 6-digit OTP**.
* The OTP is shared with the requester and linked to the approved provider.

---

### 5️⃣ Completion (Resolved)

* On physical arrival or delivery:

  * The provider enters the OTP in their app.
  * The request is marked **Resolved**.
  * Inventory lock becomes a permanent deduction.

---

## 🛠 Tech Stack

### 📱 Frontend

* **Flutter (Dart)**
* State Management: **Provider + Streams**

### ☁ Backend

* **Firebase Authentication**
* **Cloud Firestore** (Real-time DB)
* **Firebase Cloud Functions** (Lifecycle logic & inventory locking)

### 📍 Geo-Location

* Geolocator API
* Google Maps Integration

### 📲 Local Services

* Flutter Contacts Service (Emergency contact alerts)

---

## 🧱 High-Level Architecture

* Requester App → Broadcasts emergency
* Firestore → Stores request & offer objects
* Providers → Compete by offering locked inventory
* Cloud Functions → Handle:

  * Offer expiry
  * Inventory rollback
  * OTP generation
  * Final confirmation

---

## 🚀 Getting Started

### ✅ Prerequisites

* Flutter SDK **3.x or higher**
* Firebase Project
* Android / iOS Emulator or Physical Device

---

### 📥 Installation

Clone the repository:

```bash
git clone https://github.com/SShreeC/ResQFinder.git
```

Navigate into the project:

```bash
cd ResQFinder
```

Install dependencies:

```bash
flutter pub get
```

---

### ▶ Run the App

```bash
flutter run
```

---

## 🧪 Future Enhancements

* AI-based offer ranking (ETA + capability)
* Ambulance integration
* Government hospital integration
* Offline SMS-based emergency fallback
* Multi-language support

---

