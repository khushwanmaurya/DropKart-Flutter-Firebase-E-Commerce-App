// lib/screens/Customer/customer_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropkart_app/screens/Customer/cart_screen.dart';
import 'package:dropkart_app/screens/Customer/product_detail_screen.dart';
import 'package:dropkart_app/screens/Customer/wishlist_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool gridView = true;

  // For local client-side search filtering
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildTopBar(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          // Use collectionGroup to fetch 'products' from all business subcollections
          stream: FirebaseFirestore.instance.collectionGroup('products').snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return const Center(child: Text("No products available right now."));
            }

            // Optionally filter client-side by search query
            final allProducts = snap.data!.docs;
            final products = _searchQuery.isEmpty
                ? allProducts
                : allProducts.where((d) {
              final m = (d.data() as Map<String, dynamic>?) ?? {};
              final name = (m['name'] ?? '').toString().toLowerCase();
              final desc = (m['description'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery) || desc.contains(_searchQuery);
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${products.length} product${products.length == 1 ? '' : 's'} found",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 14),
                Expanded(
                  child: gridView ? _buildGridView(products) : _buildListView(products),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  AppBar _buildTopBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      title: Row(
        children: [
          const Icon(Icons.store, color: Color(0xFF6A1B9A)), // purple-ish
          const SizedBox(width: 10),
          Text("DropKart",
              style: GoogleFonts.inter(fontSize: 20, color: const Color(0xFF6A1B9A), fontWeight: FontWeight.bold)),
          const SizedBox(width: 20),
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Search products...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: "Toggle view",
            onPressed: () {
              setState(() => gridView = !gridView);
            },
            icon: Icon(gridView ? Icons.view_list : Icons.grid_view),
          ),
          IconButton(
            tooltip: "Wishlist",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WishlistScreen(userId: user!.uid)),
            ),
            icon: const Icon(Icons.favorite_border),
          ),
          IconButton(
            tooltip: "Cart",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CartScreen(userId: user!.uid)),
            ),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<QueryDocumentSnapshot> products) {
    // Responsive crossAxisCount: 2 for phones, 3 for larger, 4 for wide screens
    final width = MediaQuery.of(context).size.width;
    int crossAxis = 2;
    if (width > 1200) {
      crossAxis = 4;
    } else if (width > 800) {
      crossAxis = 3;
    } else {
      crossAxis = 2;
    }

    return GridView.builder(
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxis,
        mainAxisExtent: 320,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, i) => _buildProductCard(products[i]),
    );
  }

  Widget _buildListView(List<QueryDocumentSnapshot> products) {
    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildProductCard(products[i]),
    );
  }

  Widget _buildProductCard(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    // Resolve productId and businessId robustly
    final productId = data['productId'] ?? data['id'] ?? doc.id;
    final businessId = (data['businessId'] as String?) ?? doc.reference.parent.parent?.id;

    final images = (data['images'] is List) ? List<String>.from(data['images']) : <String>[];
    final imageUrl = images.isNotEmpty ? images.first : null;
    final price = (data['price'] ?? 0).toDouble();
    final name = data['name'] ?? 'Unnamed product';

    return InkWell(
      onTap: () {
        if (businessId != null && productId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(businessId: businessId, productId: productId),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product details not available')));
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Container(
              height: 180,
              width: double.infinity,
              decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image)),
                )
                    : const Center(child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey)),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 8),
                Text('₹${price.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                        label: const Text("Add to Cart"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _addToCart(productId.toString(), businessId?.toString(), data),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Wishlist',
                      onPressed: () {
                        // temp: open wishlist (or add to wishlist)
                        Navigator.push(context, MaterialPageRoute(builder: (_) => WishlistScreen(userId: user!.uid)));
                      },
                      icon: const Icon(Icons.favorite_border),
                    ),
                  ],
                )
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(String productId, String? businessId, Map<String, dynamic> productData) async {
    final uid = user?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please sign in to add items to cart")));
      return;
    }

    final cartItemRef = FirebaseFirestore.instance.collection('carts').doc(uid).collection('items').doc(productId);

    final snapshot = await cartItemRef.get();

    if (snapshot.exists) {
      // increment quantity
      await cartItemRef.update({
        'quantity': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } else {
      // add new cart item
      await cartItemRef.set({
        'productId': productId,
        'businessId': businessId ?? '',
        'name': productData['name'] ?? '',
        'price': productData['price'] ?? 0,
        'image': (productData['images'] is List && (productData['images'] as List).isNotEmpty) ? productData['images'][0] : null,
        'quantity': 1,
        'addedAt': Timestamp.now(),
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to cart")));
  }
}
