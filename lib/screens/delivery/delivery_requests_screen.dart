import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeliveryRequestsScreen extends StatelessWidget {
  final String partnerId;

  const DeliveryRequestsScreen({super.key, required this.partnerId});

  @override
  Widget build(BuildContext context) {
    final formatINR = NumberFormat.currency(symbol: "₹", locale: "en_IN");

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Delivery Requests"),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("deliveryPartners")
            .doc(partnerId)
            .collection("deliveries")
            .where("status", isEqualTo: "pending") // only new requests
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No new delivery requests.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              return requestTile(context, docs[i], formatINR);
            },
          );
        },
      ),
    );
  }

  // ----------------- REQUEST CARD -----------------
  Widget requestTile(
      BuildContext context, DocumentSnapshot doc, NumberFormat fmt) {
    final data = doc.data() as Map<String, dynamic>;

    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection("orders")
          .doc(data["orderId"])
          .get(),
      builder: (context, orderSnap) {

        if (!orderSnap.hasData) {
          return const SizedBox();
        }

        final order = orderSnap.data!.data() as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PRODUCT ROW
              Row(
                children: [
                  Container(
                    height: 65,
                    width: 65,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                      image: order["productImage"] != null
                          ? DecorationImage(
                        image: NetworkImage(order["productImage"]),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      order["productName"],
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    fmt.format(order["totalAmount"]),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // CUSTOMER DETAILS
              Text(
                order["customerName"],
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                order["customerAddress"],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),

              const SizedBox(height: 15),

              // BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Reject Button
                  TextButton(
                    onPressed: () {
                      rejectOrder(
                          partnerId: data["partnerId"],
                          deliveryId: data["deliveryId"]);
                    },
                    child: const Text(
                      "Reject",
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Accept Button
                  ElevatedButton(
                    onPressed: () {
                      acceptOrder(
                          partnerId: data["partnerId"],
                          deliveryId: data["deliveryId"],
                          orderId: data["orderId"]);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      "Accept",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // ----------------- REJECT ORDER -----------------
  Future<void> rejectOrder({
    required String partnerId,
    required String deliveryId,
  }) async {
    await FirebaseFirestore.instance
        .collection("deliveryPartners")
        .doc(partnerId)
        .collection("deliveries")
        .doc(deliveryId)
        .update({
      "status": "rejected",
      "rejectedAt": Timestamp.now(),
    });
  }

  // ----------------- ACCEPT ORDER -----------------
  Future<void> acceptOrder({
    required String partnerId,
    required String deliveryId,
    required String orderId,
  }) async {
    await FirebaseFirestore.instance
        .collection("deliveryPartners")
        .doc(partnerId)
        .collection("deliveries")
        .doc(deliveryId)
        .update({
      "status": "accepted",
      "acceptedAt": Timestamp.now(),
    });

    // Also update master order status
    await FirebaseFirestore.instance
        .collection("orders")
        .doc(orderId)
        .update({"orderStatus": "accepted"});
  }
}

