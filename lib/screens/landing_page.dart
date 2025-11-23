// lib/screens/landing_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

// CUSTOMER SCREEN
import 'package:dropkart_app/screens/Customer/customer_screen.dart';

// BUSINESS OWNER SCREEN
import 'package:dropkart_app/screens/business_owner/dashboard.dart';

// USE THE REAL LOGIN SCREEN
// from lib/auth/login_screen.dart
import 'package:dropkart_app/auth/login_screen.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  Widget _roleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = const Color(0xFFFF6A00),
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dropkart"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Text(
              "Choose Your Role",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // CUSTOMER
            _roleCard(
              context: context,
              icon: Icons.shopping_bag_outlined,
              title: "Customer",
              subtitle: "Browse products, add to cart, place orders",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerScreen(),
                  ),
                );
              },
              color: const Color(0xFFFF6A00),
            ),

            const SizedBox(height: 12),

            // BUSINESS OWNER
            _roleCard(
              context: context,
              icon: Icons.storefront_outlined,
              title: "Business Owner",
              subtitle: "Manage products & view orders",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DashboardScreen(
                      businessId:
                      FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),
                  ),
                );
              },
              color: Colors.teal,
            ),

            const SizedBox(height: 12),

            // DELIVERY PARTNER
            _roleCard(
              context: context,
              icon: Icons.local_shipping_outlined,
              title: "Delivery Partner",
              subtitle: "View delivery tasks & update status",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AuthPage(), // CORRECT LOGIN
                  ),
                );
              },
              color: Colors.indigo,
            ),

            const Spacer(),
            Text(
              "Dropkart © 2025",
              style: GoogleFonts.inter(
                color: Colors.black45,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
