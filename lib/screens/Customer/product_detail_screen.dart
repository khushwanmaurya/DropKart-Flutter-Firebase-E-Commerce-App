// lib/screens/Customer/product_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailScreen extends StatefulWidget {
  final String businessId;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.businessId,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Map<String, dynamic>? _product;
  bool _isWishlisted = false;
  bool _isLoading = true;
  bool _isBuying = false;
  final _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProductAndWishlist();
  }

  Future<void> _loadProductAndWishlist() async {
    setState(() => _isLoading = true);
    try {
      // Load product details
      final doc = await FirebaseFirestore.instance
          .collection("businesses")
          .doc(widget.businessId)
          .collection("products")
          .doc(widget.productId)
          .get();

      if (!mounted) return;
      setState(() {
        _product = doc.data();
      });

      // Check wishlist status only if a user is logged in
      if (_user != null) {
        final wishDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(_user!.uid)
            .collection("wishlist")
            .doc(widget.productId)
            .get();
        if (mounted) {
          setState(() {
            _isWishlisted = wishDoc.exists;
          });
        }
      }
    } catch (e) {
      // ignore or show feedback
      debugPrint("Error loading product: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWishlist() async {
    if (_user == null) {
      _showSignInPrompt("Please sign in to manage your wishlist.");
      return;
    }
    if (_product == null) return;

    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(_user!.uid)
        .collection("wishlist")
        .doc(widget.productId);

    setState(() => _isWishlisted = !_isWishlisted);

    try {
      if (_isWishlisted) {
        // Store essential product data directly in the wishlist
        await ref.set({
          'name': _product!['name'],
          'price': _product!['price'],
          'image': (_product!['images'] is List && (_product!['images'] as List).isNotEmpty)
              ? (_product!['images'] as List)[0]
              : null,
          'productId': widget.productId,
          'businessId': widget.businessId,
          'addedAt': Timestamp.now(),
        });
        _showFeedback("Added to wishlist!");
      } else {
        await ref.delete();
        _showFeedback("Removed from wishlist.");
      }
    } catch (e) {
      _showFeedback("Could not update wishlist.");
      debugPrint("Wishlist error: $e");
    }
  }

  /// Adds product to cart. This implementation writes to two common locations:
  /// 1) users/{uid}/cart/{productId}  (your original schema)
  /// 2) carts/{uid}/items/{productId}  (alternate schema some screens may read)
  /// This helps compatibility in case other screens expect a different path.
  Future<void> _addToCart() async {
    if (_user == null) {
      _showSignInPrompt("Please sign in to add items to your cart.");
      return;
    }
    if (_product == null) return;

    try {
      final uid = _user!.uid;

      // Write to users/{uid}/cart/{productId} (existing project convention)
      final cartRefUsers = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("cart")
          .doc(widget.productId);

      // Write to carts/{uid}/items/{productId} (alternate convention)
      final cartRefCarts = FirebaseFirestore.instance
          .collection("carts")
          .doc(uid)
          .collection("items")
          .doc(widget.productId);

      final data = {
        'name': _product!['name'],
        'price': _product!['price'],
        'image': (_product!['images'] is List && (_product!['images'] as List).isNotEmpty)
            ? (_product!['images'] as List)[0]
            : null,
        // Ensure productId & businessId are stored
        'productId': widget.productId,
        'businessId': widget.businessId,
        'updatedAt': Timestamp.now(),
      };

      // For users cart: increment quantity properly (use merge so first time sets quantity to 1)
      await cartRefUsers.set({
        ...data,
        'quantity': FieldValue.increment(1),
        'addedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      // For carts collection: do same increment (merge:true)
      await cartRefCarts.set({
        ...data,
        'quantity': FieldValue.increment(1),
        'addedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      _showFeedback("Added to cart!");
    } catch (e) {
      _showFeedback("Failed to add to cart.");
      debugPrint("AddToCart error: $e");
    }
  }

  Future<void> _buyNowSingleItem() async {
    if (_user == null) {
      _showSignInPrompt("Please sign in to buy");
      return;
    }
    if (_product == null) return;

    setState(() => _isBuying = true);

    try {
      final uid = _user!.uid;
      // Build single item order
      final item = {
        'productId': widget.productId,
        'name': _product!['name'] ?? '',
        'price': _product!['price'] ?? 0,
        'quantity': 1,
        'image': (_product!['images'] is List && (_product!['images'] as List).isNotEmpty)
            ? (_product!['images'] as List)[0]
            : null,
        'businessId': widget.businessId,
      };

      final total = (item['price'] ?? 0);

      final order = {
        'userId': uid,
        'items': [item],
        'status': 'Pending',
        'createdAt': Timestamp.now(),
        'total': total,
        'paymentMethod': 'COD',
      };

      await FirebaseFirestore.instance.collection('orders').add(order);

      _showFeedback("Order placed successfully");
      // Optionally navigate to an order success or orders screen if available
      // If you have OrderSuccessScreen or customer_orders_screen, navigate accordingly.
      // Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OrderSuccessScreen()));
    } catch (e) {
      _showFeedback("Failed to place order.");
      debugPrint("BuyNow error: $e");
    } finally {
      if (mounted) setState(() => _isBuying = false);
    }
  }

  void _showSignInPrompt(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: "SIGN IN",
          onPressed: () {
            // TODO: Navigate to your login screen
            // Example:
            // Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoginScreen()));
          },
        ),
      ),
    );
  }

  void _showFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_product == null) {
      return const Scaffold(body: Center(child: Text("Product not found.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_product!["name"] ?? 'Product', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            onPressed: _toggleWishlist,
            icon: Icon(
              _isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: _isWishlisted ? Colors.red : null,
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 800;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: isWide
                ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildProductImages()),
                const SizedBox(width: 50),
                Expanded(child: _buildProductDetails()),
              ],
            )
                : Column(
              children: [
                _buildProductImages(),
                const SizedBox(height: 20),
                _buildProductDetails(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProductImages() {
    final images = List<String>.from(_product!['images'] ?? []);
    if (images.isEmpty) {
      return const Center(child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey));
    }
    return Column(
      children: [
        cs.CarouselSlider(
          items: images.map((img) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(img, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, __, ___) {
                return Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 80),
                  height: 250,
                );
              }),
            );
          }).toList(),
          options: cs.CarouselOptions(
            height: 350,
            enlargeCenterPage: true,
            autoPlay: images.length > 1,
            viewportFraction: 1,
          ),
        ),
        const SizedBox(height: 10),
        if (images.length > 1)
          Wrap(
            spacing: 10,
            children: images.map((img) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(img, height: 70, width: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                  return Container(color: Colors.grey.shade200, height: 70, width: 70, child: const Icon(Icons.broken_image));
                }),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildProductDetails() {
    final formatINR = NumberFormat.currency(locale: "en_IN", symbol: "₹");

    final price = _product!['price'] ?? 0;
    final stock = _product!['stock'] ?? 0;
    final desc = _product!['description'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_product!['name'] ?? '', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(formatINR.format(price), style: const TextStyle(fontSize: 24, color: Colors.green)),
        const SizedBox(height: 8),
        Text("Stock: $stock", style: TextStyle(color: (stock > 0) ? Colors.green : Colors.red, fontSize: 16)),
        const SizedBox(height: 20),
        const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(desc, style: const TextStyle(fontSize: 15, height: 1.4)),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: _addToCart,
              label: const Text("Add to Cart"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: _isBuying ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.flash_on_outlined),
              onPressed: _isBuying ? null : _buyNowSingleItem,
              label: Text(_isBuying ? "Placing Order..." : "Buy Now (COD)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
