import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomerOrdersScreen extends StatelessWidget {
  final String userId;

  const CustomerOrdersScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final formatINR =
    NumberFormat.currency(locale: "en_IN", symbol: "₹");

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("userId", isEqualTo: userId)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No orders placed yet!",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final data = orders[i].data() as Map<String, dynamic>;
              final orderId = data["orderId"];
              final productId = data["productId"];
              final businessId = data["businessId"];
              final status = data["orderStatus"] ?? "Pending";
              final amount = data["totalAmount"];
              final date = (data["createdAt"] as Timestamp).toDate();

              return FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection("businesses")
                    .doc(businessId)
                    .collection("products")
                    .doc(productId)
                    .get(),
                builder: (context, productSnapshot) {

                  if (!productSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final product = productSnapshot.data!.data() as Map?;

                  if (product == null) return const SizedBox();

                  final name = product["name"];
                  final img = product["images"][0];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.white,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15),

                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          img,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                      ),

                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600),
                      ),

                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            "Order ID: ${orderId.substring(0, 8).toUpperCase()}",
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Status: $status",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: statusColor(status),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Placed on: ${date.day}/${date.month}/${date.year}",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),

                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            formatINR.format(amount),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                "/trackOrder",
                                arguments: {
                                  "orderId": orderId,
                                  "productId": productId,
                                  "businessId": businessId,
                                },
                              );
                            },
                            child: const Text(
                              "Track",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Color statusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange;
      case "Packed":
        return Colors.blue;
      case "Shipped":
        return Colors.teal;
      case "Delivered":
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}
