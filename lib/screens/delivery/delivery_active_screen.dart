import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeliveryActiveScreen extends StatelessWidget {
  final String partnerId;

  const DeliveryActiveScreen({super.key, required this.partnerId});

  @override
  Widget build(BuildContext context) {
    final formatINR = NumberFormat.currency(locale: "en_IN", symbol: "₹");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Active Deliveries"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("deliveryPartners")
            .doc(partnerId)
            .collection("deliveries")
            .where("status", whereNotIn: ["delivered", "rejected"])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No Active Deliveries",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              return activeTile(context, docs[i], formatINR);
            },
          );
        },
      ),
    );
  }

  // ------------------- ACTIVE DELIVERY TILE UI -------------------
  Widget activeTile(BuildContext context, DocumentSnapshot doc, NumberFormat fmt) {
    final data = doc.data() as Map<String, dynamic>;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          "/deliveryOrderDetail",
          arguments: {
            "deliveryId": data["deliveryId"],
            "orderId": data["orderId"],
            "partnerId": data["partnerId"],
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
          color: Colors.white,
        ),

        child: Row(
          children: [
            // Product Image
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
                image: data["productImage"] != null
                    ? DecorationImage(
                  image: NetworkImage(data["productImage"]),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
            ),

            const SizedBox(width: 15),

            // Details Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data["customerName"] ?? "Customer",
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data["customerAddress"] ?? "Address not available",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fmt.format(data["amount"]),
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Status Badge
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.deepPurple),
              ),
              child: Text(
                data["status"].toString().toUpperCase(),
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
