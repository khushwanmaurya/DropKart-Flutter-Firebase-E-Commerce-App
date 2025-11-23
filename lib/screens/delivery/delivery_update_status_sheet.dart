import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeliveryUpdateStatusSheet extends StatelessWidget {
  final String partnerId;
  final String deliveryId;
  final String orderId;
  final String currentStatus;

  const DeliveryUpdateStatusSheet({
    super.key,
    required this.partnerId,
    required this.deliveryId,
    required this.orderId,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final statusFlow = [
      "accepted",
      "picked",
      "out_for_delivery",
      "delivered",
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Wrap(
        children: [
          Center(
            child: Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Center(
            child: Text(
              "Update Delivery Status",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold
              ),
            ),
          ),

          const SizedBox(height: 25),

          // Status Options
          for (var s in statusFlow)
            statusButton(
              context,
              label: labelOf(s),
              enabled: canUpdate(currentStatus, s),
              newStatus: s,
            ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ------------------------
  // Button Widget
  // ------------------------
  Widget statusButton(
      BuildContext context, {
        required String label,
        required bool enabled,
        required String newStatus,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: enabled ? () => updateStatus(context, newStatus) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? Colors.deepPurple : Colors.grey.shade400,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }

  // ------------------------
  // Label formatter
  // ------------------------
  String labelOf(String status) {
    switch (status) {
      case "picked":
        return "Picked Up";
      case "out_for_delivery":
        return "Out For Delivery";
      case "delivered":
        return "Delivered";
      case "accepted":
        return "Accept Order";
      default:
        return status;
    }
  }

  // ------------------------
  // Status Flow Logic
  // ------------------------
  bool canUpdate(String current, String target) {
    const flow = {
      "pending": ["accepted"],
      "accepted": ["picked"],
      "picked": ["out_for_delivery"],
      "out_for_delivery": ["delivered"],
      "delivered": [],
      "rejected": [],
    };

    return flow[current]?.contains(target) ?? false;
  }

  // ------------------------
  // Update Firestore
  // ------------------------
  Future<void> updateStatus(BuildContext context, String newStatus) async {
    final data = {
      "status": newStatus,
      if (newStatus == "delivered") "deliveredAt": Timestamp.now(),
      if (newStatus == "picked") "pickedAt": Timestamp.now(),
      if (newStatus == "out_for_delivery") "outForDeliveryAt": Timestamp.now(),
    };

    // Update delivery partner collection
    await FirebaseFirestore.instance
        .collection("deliveryPartners")
        .doc(partnerId)
        .collection("deliveries")
        .doc(deliveryId)
        .update(data);

    // Update master order record
    await FirebaseFirestore.instance
        .collection("orders")
        .doc(orderId)
        .update({"orderStatus": newStatus});

    Navigator.pop(context); // close sheet

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Status updated to '${labelOf(newStatus)}'"),
      ),
    );
  }
}
