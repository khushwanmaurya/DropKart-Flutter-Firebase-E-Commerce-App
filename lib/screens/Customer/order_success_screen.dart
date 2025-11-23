// lib/screens/Customer/order_success_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  final double amount;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final formatINR = NumberFormat.currency(locale: "en_IN", symbol: "₹");

    final safeOrderId = orderId.isEmpty
        ? "N/A"
        : (orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool wide = constraints.maxWidth > 700;

            return Padding(
              padding: const EdgeInsets.all(25),
              child: SizedBox(
                width: wide ? 600 : double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Success Icon
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAFCEF),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(30),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 100,
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Order Placed Successfully!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      "Thank you for shopping with us.\nYour order has been confirmed.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Order Details box
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Order ID:", style: TextStyle(fontSize: 16)),
                              Text(
                                safeOrderId,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Amount Paid:", style: TextStyle(fontSize: 16)),
                              Text(
                                formatINR.format(amount),
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 35),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                      ),
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          "/customerHome",
                              (route) => false,
                        );
                      },
                      child: const Text(
                        "Back to Home",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
