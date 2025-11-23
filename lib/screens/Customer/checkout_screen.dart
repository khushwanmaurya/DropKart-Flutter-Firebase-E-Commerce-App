import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropkart_app/screens/Customer/address_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _user = FirebaseAuth.instance.currentUser;

  Map<String, dynamic>? _selectedAddress;
  List<Map<String, dynamic>> _cartItems = [];

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  double get _deliveryFee => _subtotal > 500 ? 0 : 50; // Free delivery above 500
  double get _total => _subtotal + _deliveryFee;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;

    // Load cart items
    final cartSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(_user!.uid)
        .collection("cart")
        .get();

    final cart = cartSnapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();

    // Load addresses and set the first one as default
    final addressSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(_user!.uid)
        .collection("addresses")
        .orderBy("createdAt", descending: true)
        .get();

    Map<String, dynamic>? defaultAddress;
    if (addressSnapshot.docs.isNotEmpty) {
      defaultAddress = addressSnapshot.docs.first.data();
    }

    if (mounted) {
      setState(() {
        _cartItems = cart;
        _selectedAddress = defaultAddress;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_user == null || _selectedAddress == null || _cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a shipping address and ensure your cart is not empty.")),
      );
      return;
    }

    final orderId = const Uuid().v4();
    final orderRef = FirebaseFirestore.instance.collection("orders").doc(orderId);

    await orderRef.set({
      'orderId': orderId,
      'userId': _user!.uid,
      'items': _cartItems,
      'total': _total,
      'deliveryFee': _deliveryFee,
      'shippingAddress': _selectedAddress,
      'status': 'Pending',
      'orderedAt': Timestamp.now(),
    });

    // Clear the cart
    final cartCollection = FirebaseFirestore.instance.collection("users").doc(_user!.uid).collection("cart");
    for (var item in _cartItems) {
      await cartCollection.doc(item['id']).delete();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: Text("Please log in to check out.")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShippingSection(),
            const SizedBox(height: 30),
            _buildItemsSection(),
            const SizedBox(height: 30),
            _buildPriceDetails(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildShippingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Shipping Address", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (_selectedAddress != null)
          Card(
            elevation: 1,
            child: ListTile(
              title: Text(_selectedAddress!['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  "${_selectedAddress!['address']}, ${_selectedAddress!['city']}, ${_selectedAddress!['state']} - ${_selectedAddress!['pincode']}"),
              trailing: TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddressScreen(returnSelectedAddress: true)),
                  );
                  if (result != null) {
                    setState(() => _selectedAddress = result);
                  }
                },
                child: const Text("Change"),
              ),
            ),
          )
        else
          OutlinedButton.icon(
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text("Select or Add Address"),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressScreen(returnSelectedAddress: true)),
              );
              if (result != null) {
                setState(() => _selectedAddress = result);
              }
            },
          ),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Items in Cart", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (_cartItems.isEmpty)
          const Text("Your cart is empty.")
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              return ListTile(
                leading: Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover),
                title: Text(item['name']),
                subtitle: Text("Qty: ${item['quantity']}"),
                trailing: Text("₹${item['price'] * item['quantity']}"),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPriceDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            _priceRow("Subtotal", "₹$_subtotal"),
            const SizedBox(height: 8),
            _priceRow("Delivery Fee", "₹$_deliveryFee"),
            const Divider(height: 20, thickness: 1),
            _priceRow("Total", "₹$_total", isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String title, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 16)),
        Text(amount, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 16)),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: ElevatedButton(
        onPressed: _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        child: const Text("Place Order"),
      ),
    );
  }
}
