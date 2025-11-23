import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WishlistScreen extends StatelessWidget {
  final String userId;

  const WishlistScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wishlist")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .collection("wishlist")
            .snapshots(),
        builder: (c, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!s.hasData || s.data!.docs.isEmpty) {
            return const Center(child: Text("No items in wishlist"));
          }

          final items = s.data!.docs;

          return ListView(
            children: items.map((e) {
              final d = e.data();

              return ListTile(
                leading: d['image'] != null ? Image.network(d['image'], width: 50) : const Icon(Icons.image_not_supported),
                title: Text(d['name'] ?? 'No Name'),
                subtitle: Text("₹${d['price'] ?? 0}"),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
