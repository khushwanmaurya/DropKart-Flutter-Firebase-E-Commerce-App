import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  final String businessId;

  const OrdersScreen({super.key, required this.businessId});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String giveRupees(num val) {
    final format = NumberFormat.currency(locale: "en_IN", symbol: "₹");
    return format.format(val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Order Tracking",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text("Monitor all your orders and delivery status",
                style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 24),
            _buildStatsRow(),

            const SizedBox(height: 24),
            Expanded(child: _buildOrderList())
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("businesses")
          .doc(widget.businessId)
          .collection("orders")
          .snapshots(),
      builder: (context, snap) {
        int total = 0;
        int processing = 0;
        int delivered = 0;

        if (snap.hasData) {
          total = snap.data!.docs.length;

          for (var doc in snap.data!.docs) {
            var order = doc.data() as Map<String, dynamic>;
            if (order["status"] == "Processing") processing++;
            if (order["status"] == "Delivered") delivered++;
          }
        }

        return Row(
          children: [
            _statCard(total.toString(), "Total Orders", Colors.blue.shade50),
            _statCard(processing.toString(), "Processing", Colors.yellow.shade50),
            _statCard(delivered.toString(), "Delivered", Colors.green.shade50),
          ],
        );
      },
    );
  }

  Widget _statCard(String count, String title, Color bg) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(count,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(color: Colors.grey[700]))
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("businesses")
          .doc(widget.businessId)
          .collection("orders")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const CircularProgressIndicator();
        if (snap.data!.docs.isEmpty) {
          return const Center(child: Text("No Orders Found"));
        }

        return ListView(
          padding: EdgeInsets.zero,
          children: snap.data!.docs.map((doc) {
            var order = doc.data() as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order["orderId"],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("${order["customerName"]} • ${order["productName"]}",
                          style: const TextStyle(color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(
                        (order["createdAt"] as Timestamp)
                            .toDate()
                            .toString()
                            .substring(0, 10),
                        style: const TextStyle(color: Colors.grey),
                      )
                    ],
                  ),

                  Text(
                    giveRupees(order["amount"] ?? 0),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
