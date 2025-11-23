import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeliveryEarningsScreen extends StatelessWidget {
  final String partnerId;

  const DeliveryEarningsScreen({super.key, required this.partnerId});

  @override
  Widget build(BuildContext context) {
    final formatINR = NumberFormat.currency(locale: "en_IN", symbol: "₹");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Earnings"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("deliveryPartners")
            .doc(partnerId)
            .collection("deliveries")
            .where("status", isEqualTo: "delivered")
            .snapshots(),
        builder: (context, snapshot) {
          // --- Handle loading and error states --- //
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("An error occurred: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No deliveries completed yet.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // --- Calculate Earnings --- //
          final docs = snapshot.data!.docs;
          int today = 0, week = 0, month = 0, total = 0;
          final now = DateTime.now();

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;

            // Safely get earning and deliveredAt, skip if invalid
            if (data['earning'] is! num || data['deliveredAt'] is! Timestamp) {
              continue;
            }
            final earning = data['earning'] as int;
            final dt = (data['deliveredAt'] as Timestamp).toDate();

            if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
              today += earning;
            }
            if (dt.isAfter(now.subtract(const Duration(days: 7)))) {
              week += earning;
            }
            if (dt.year == now.year && dt.month == now.month) {
              month += earning;
            }
            total += earning;
          }

          // --- Build UI --- //
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "COD Earnings Summary",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    _earningCard("Today", formatINR.format(today), Colors.green),
                    const SizedBox(width: 15),
                    _earningCard("This Week", formatINR.format(week), Colors.blue),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _earningCard("This Month", formatINR.format(month), Colors.purple),
                    const SizedBox(width: 15),
                    _earningCard("Total", formatINR.format(total), Colors.orange),
                  ],
                ),
                const SizedBox(height: 35),
                _buildTotalDeliveries(docs.length),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _earningCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Use .withAlpha for modern Flutter
          color: color.withAlpha(23), // ~0.09 opacity
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)), // ~0.3 opacity
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(fontSize: 16, color: color.withAlpha(204)), // ~0.8 opacity
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalDeliveries(int totalCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withAlpha(25), // ~0.1 opacity
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withAlpha(77)), // ~0.3 opacity
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Deliveries Completed",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "$totalCount Deliveries",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}
