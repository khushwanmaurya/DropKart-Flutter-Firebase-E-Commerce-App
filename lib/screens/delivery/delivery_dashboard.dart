import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeliveryDashboard extends StatelessWidget {
  final String partnerId;

  const DeliveryDashboard({super.key, required this.partnerId});

  @override
  Widget build(BuildContext context) {
    final formatINR = NumberFormat.currency(locale: "en_IN", symbol: "₹");

    return Scaffold(
      body: Row(
        children: [
          // =======================
          // LEFT SIDEBAR
          // =======================
          Container(
            width: 230,
            color: const Color(0xFFf5f7fb),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.delivery_dining,
                    size: 60, color: Colors.deepPurple),
                const SizedBox(height: 10),
                const Text(
                  "Delivery Partner",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                sidebarItem(context, Icons.dashboard, "Dashboard", 0),
                sidebarItem(context, Icons.inbox, "Requests", 1),
                sidebarItem(context, Icons.local_shipping, "Active", 2),
                sidebarItem(context, Icons.currency_rupee, "Earnings", 3),
                sidebarItem(context, Icons.history, "History", 4),
                sidebarItem(context, Icons.settings, "Settings", 5),
                const Spacer(),
                // Logout
                sidebarItem(context, Icons.logout, "Logout", 99),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // =======================
          // MAIN DASHBOARD CONTENT
          // =======================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("deliveryPartners")
                    .doc(partnerId)
                    .collection("deliveries")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("An error occurred: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No delivery data found."));
                  }

                  final docs = snapshot.data!.docs;

                  // totals
                  int todayEarnings = 0;
                  int activeDeliveries = 0;
                  int completedDeliveries = 0;
                  final todayDate = DateTime.now();

                  for (var d in docs) {
                    final data = d.data();

                    // Earnings (today only)
                    if (data["status"] == "delivered") {
                      final ts = data["deliveredAt"];
                      if (ts is Timestamp) {
                        final dt = ts.toDate();
                        if (dt.day == todayDate.day &&
                            dt.month == todayDate.month &&
                            dt.year == todayDate.year) {
                          // Corrected: Safely handle the numeric type from Firestore
                          final earning = data["earning"];
                          if (earning is num) {
                            todayEarnings += earning.toInt();
                          }
                        }
                      }
                    }

                    // Active Count
                    final status = data["status"];
                    if (status == "accepted" ||
                        status == "picked" ||
                        status == "out_for_delivery") {
                      activeDeliveries++;
                    }

                    // Completed
                    if (status == "delivered") {
                      completedDeliveries++;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Dashboard",
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // ------------------- STATS CARDS -----------------------
                      Row(
                        children: [
                          statCard("Today's Earnings",
                              formatINR.format(todayEarnings), Colors.green),
                          const SizedBox(width: 20),
                          statCard("Active Deliveries", "$activeDeliveries",
                              Colors.blue),
                          const SizedBox(width: 20),
                          statCard("Completed", "$completedDeliveries",
                              Colors.deepPurple),
                        ],
                      ),

                      const SizedBox(height: 40),

                      const Text(
                        "Active Deliveries",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // ------------------- ACTIVE DELIVERIES LIST -----------------------
                      Expanded(
                        child: ListView(
                          children: docs
                              .where((d) =>
                                  d["status"] != "delivered" &&
                                  d["status"] != "rejected")
                              .map((d) => activeDeliveryTile(d))
                              .toList(),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =======================
  // SIDEBAR ITEM WIDGET
  // =======================
  Widget sidebarItem(
      BuildContext context, IconData icon, String label, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: () {
        // Navigation Logic
        switch (index) {
          case 0:
            break; // Already on dashboard
          case 1:
            Navigator.pushNamed(context, "/deliveryRequests",
                arguments: partnerId);
            break;
          case 2:
            Navigator.pushNamed(context, "/deliveryActive", arguments: partnerId);
            break;
          case 3:
            Navigator.pushNamed(context, "/deliveryEarnings",
                arguments: partnerId);
            break;
          case 4:
            Navigator.pushNamed(context, "/deliveryHistory", arguments: partnerId);
            break;
          case 5:
            Navigator.pushNamed(context, "/deliverySettings",
                arguments: partnerId);
            break;
          case 99:
            Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
            break;
        }
      },
    );
  }

  // =======================
  // STAT CARD WIDGET
  // =======================
  Widget statCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // Corrected: Use withAlpha for modern Flutter
          color: color.withAlpha(26), // ~10% opacity
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(102)), // ~40% opacity
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 6),
            Text(title,
                style: TextStyle(
                  fontSize: 16,
                  // Corrected: Use withAlpha for modern Flutter
                  color: color.withAlpha(204), // ~80% opacity
                )),
          ],
        ),
      ),
    );
  }

  // =======================
  // ACTIVE DELIVERY TILE
  // =======================
  Widget activeDeliveryTile(DocumentSnapshot doc) {
    // Safely cast data to a map
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return const ListTile(title: Text("Invalid delivery data"));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade200,
              image: data["productImage"] != null
                  ? DecorationImage(
                      image: NetworkImage(data["productImage"]),
                      fit: BoxFit.cover)
                  : null,
            ),
          ),
          const SizedBox(width: 15),

          // Main Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data["customerName"] ?? "Unknown",
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(data["customerAddress"] ?? "",
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          Text(
            (data["status"] as String? ?? "").toUpperCase(),
            style: const TextStyle(
                fontSize: 14,
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }
}
