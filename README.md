# DropKart-Flutter-Firebase-E-Commerce-App
A full-stack e-commerce application built using Flutter and Firebase. Includes customer shopping UI, business owner dashboard, delivery partner module, cart management, orders, authentication, Firestore database integration, and responsive design for Android &amp; Web.

📦 DropKart – Flutter Firebase E-Commerce App

A full-stack multi-role e-commerce application built using Flutter and Firebase, supporting:

Customers – browse products, add to cart, place orders

Business Owners – manage products & view orders

Delivery Partners – view assigned deliveries & update delivery status

This project supports Android + Web and uses Firebase Firestore as the primary backend.

🚀 Features
👤 Customer Module

Browse products

Search bar

Add / remove items from cart

Address management

Checkout (COD)

Order tracking

Order success screen

🏪 Business Owner Module

Upload products

View, edit, delete products

View all customer orders

Business dashboard

🚚 Delivery Partner Module

Login for delivery partner

View delivery requests

Update order delivery status (Picked → Out for Delivery → Delivered)

Daily earnings overview

🔥 Firebase Integration

Firebase Authentication

Cloud Firestore

Realtime updates

Firebase Storage (product images)

📁 Project Structure
lib/
 ├── auth/
 │   └── login_screen.dart
 ├── screens/
 │   ├── Customer/
 │   │     ├── customer_screen.dart
 │   │     ├── cart_screen.dart
 │   │     ├── checkout_screen.dart
 │   │     ├── order_success_screen.dart
 │   │     └── wishlist_screen.dart
 │   ├── business_owner/
 │   │     ├── dashboard.dart
 │   │     ├── product_screen.dart
 │   │     ├── product_upload.dart
 │   │     └── order_screen.dart
 │   ├── delivery/
 │   │     ├── delivery_dashboard.dart
 │   │     ├── delivery_active_screen.dart
 │   │     ├── delivery_requests_screen.dart
 │   │     └── delivery_update_status_sheet.dart
 │   └── landing_page.dart
 ├── widgets/
 ├── models/
 ├── main.dart

🛠️ Tech Stack

Flutter 3.x

Dart

Firebase Authentication

Cloud Firestore

Firebase Storage

Provider / StreamBuilder

Material 3 UI

📲 How to Run the Project
1️⃣ Clone the repository
git clone https://github.com/YOUR-USERNAME/dropkart.git
cd dropkart

2️⃣ Install dependencies
flutter pub get

3️⃣ Add Firebase to your project

Follow the official Firebase setup:

🔗 https://firebase.google.com/docs/flutter/setup

Make sure you add:

google-services.json → android/app/

firebase_options.dart generated via FlutterFire

4️⃣ Run the app
flutter run

📸 Screenshots 
![Customer Home]()
![Cart Screen]()
![Business Dashboard]()
![Delivery Dashboard]()

⭐ Future Enhancements

Online payments (Razorpay / Stripe)

Notifications (Firebase Cloud Messaging)

Order history page

Reviews & Ratings

Analytics dashboard

🤝 Contributions

Contributions, issues, and feature requests are welcome!
Feel free to open a PR or report a bug.

📄 License

This project is open-source and available under the MIT License.
