# DropKart – Flutter Firebase E-Commerce App

A full-stack e-commerce application built using **Flutter** and **Firebase**.  
Includes customer shopping UI, business owner dashboard, delivery partner module,  
cart management, orders, authentication, Firestore database integration,  
and responsive design for Android & Web.

---

## 🚀 Features

### 🛒 Customer Module
- Browse products  
- Product details  
- Add to cart  
- Wishlist  
- Checkout (COD)  
- Real-time cart & orders via Firebase  

### 🏪 Business Owner Dashboard
- Add / Upload products  
- Manage inventory  
- View and manage customer orders  
- Real-time Firestore updates  

### 🚚 Delivery Partner Module
- Accept delivery requests  
- Update delivery status (Picked → Out for Delivery → Delivered)  
- Track assigned orders  
- Delivery earning dashboard  

### 🔥 Firebase Integration
- Authentication (Email/Password)
- Firestore real-time database  
- Secure read/write rules  
- Storage for product images  

### 📱 Responsive UI
- Fully responsive for **Android**, **Tablets**, and **Web**  
- Modern UI using Material 3  

---

## 📁 Project Structure

lib/
├── main.dart
├── screens/
│ ├── Customer/
│ ├── business_owner/
│ ├── delivery/
│ └── landing_page.dart
├── auth/
│ └── login_screen.dart
└── firebase_options.dart

yaml
Copy code

---

## 🔧 Tech Stack
- **Flutter 3.x**
- **Dart**
- **Firebase Authentication**
- **Firestore**
- **Firebase Storage**
- **Material 3 UI**
- **State Management: Provider / SetState (as needed)**

---

## 🛠 Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/khushwanmaurya/DropKart-Flutter-Firebase-E-Commerce-App.git
Install dependencies:

sh
Copy code
flutter pub get
Run the app:

sh
Copy code
flutter run
🔥 Firebase Setup
Create a Firebase project

Enable Authentication (Email/Password)

Create Firestore database

Enable Firebase Storage

Download google-services.json and add it to:

bash
Copy code
android/app/
Run FlutterFire CLI:

sh
Copy code
flutterfire configure
👨‍💻 Developer
Khushwant Maurya
📧 khushwanmaurya@gmail.com
⭐ GitHub: khushwanmaurya

⭐ Show Your Support
If you like the project, give it a star ⭐ on GitHub!