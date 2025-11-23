// lib/screens/Customer/cart_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// FIXED IMPORT — The correct path with Capital "C"
import 'package:dropkart_app/screens/Customer/order_success_screen.dart';

class CartScreen extends StatelessWidget {
  final String userId;

  const CartScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final cartCollection = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("cart");

    return Scaffold(
      appBar: AppBar(title: const Text("Your Cart")),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartCollection.snapshots(),
        builder: (c, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!s.hasData || s.data!.docs.isEmpty) {
            return const Center(child: Text("Cart is empty"));
          }

          final cartDocs = s.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 120, top: 8),
            itemCount: cartDocs.length,
            itemBuilder: (ctx, index) {
              final doc = cartDocs[index];
              final d = (doc.data() ?? {}) as Map<String, dynamic>;

              final image = (d['image'] ?? '') as String;
              final name = (d['name'] ?? 'No Name') as String;
              final price = (d['price'] ?? 0).toDouble();
              final qty = (d['quantity'] ?? 1) as int;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: image.isNotEmpty
                        ? Image.network(
                      image,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text("₹${price.toStringAsFixed(2)}"),
                  trailing: SizedBox(
                    width: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // decrease
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () async {
                            final currentQty =
                            (d['quantity'] ?? 1) as int;
                            if (currentQty > 1) {
                              await doc.reference.update({
                                'quantity': FieldValue.increment(-1),
                                'updatedAt': Timestamp.now(),
                              });
                            } else {
                              await doc.reference.delete();
                            }
                          },
                        ),

                        Text("$qty"),

                        // increase
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () async {
                            await doc.reference.update({
                              'quantity': FieldValue.increment(1),
                              'updatedAt': Timestamp.now(),
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      // ----------------------- BOTTOM BAR TOTAL + BUY BUTTON -----------------------
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Total Price
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .doc(userId)
                      .collection("cart")
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData || snap.data!.docs.isEmpty) {
                      return const Text(
                        "Total: ₹0",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      );
                    }
                    double total = 0;
                    for (var d in snap.data!.docs) {
                      final m = (d.data() ?? {}) as Map<String, dynamic>;
                      final p = (m['price'] ?? 0).toDouble();
                      final q = (m['quantity'] ?? 1) as int;
                      total += p * q;
                    }
                    return Text(
                      "Total: ₹${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    );
                  },
                ),
              ),

              // Buy Now Button
              ElevatedButton(
                onPressed: () async {
                  final cartRef = FirebaseFirestore.instance
                      .collection("users")
                      .doc(userId)
                      .collection("cart");

                  final cartSnap = await cartRef.get();

                  if (cartSnap.docs.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Your cart is empty")));
                    return;
                  }

                  // Convert cart items
                  final orderItems = cartSnap.docs.map((d) {
                    final m = (d.data() ?? {}) as Map<String, dynamic>;
                    return {
                      'productId': m['productId'] ?? d.id,
                      'name': m['name'] ?? '',
                      'price': m['price'] ?? 0,
                      'quantity': m['quantity'] ?? 1,
                      'image': m['image'] ?? '',
                      'businessId': m['businessId'] ?? '',
                    };
                  }).toList();

                  double total = 0;
                  for (var it in orderItems) {
                    total += (it['price'] ?? 0) * (it['quantity'] ?? 1);
                  }

                  try {
                    // Store order in Firestore
                    final orderRef = await FirebaseFirestore.instance
                        .collection('orders')
                        .add({
                      'userId': userId,
                      'items': orderItems,
                      'status': 'Pending',
                      'createdAt': Timestamp.now(),
                      'total': total,
                      'paymentMethod': 'COD',
                    });

                    // Clear cart
                    final batch = FirebaseFirestore.instance.batch();
                    for (var d in cartSnap.docs) {
                      batch.delete(d.reference);
                    }
                    await batch.commit();

                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Order placed successfully")));

                    // FINAL FIX — Navigate to Success Page
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => OrderSuccessScreen(
                          orderId: orderRef.id,
                          amount: total, // MUST be double
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error placing order: $e")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Buy Now (COD)"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
