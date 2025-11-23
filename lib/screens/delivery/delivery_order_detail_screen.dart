import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryOrderDetailScreen extends StatefulWidget {
  final String deliveryId;
  final String orderId;
  final String partnerId;

  const DeliveryOrderDetailScreen({
    super.key,
    required this.deliveryId,
    required this.orderId,
    required this.partnerId,
  });

  @override
  State<DeliveryOrderDetailScreen> createState() =>
      _DeliveryOrderDetailScreenState();
}

class _DeliveryOrderDetailScreenState extends State<DeliveryOrderDetailScreen> {
  final formatINR = NumberFormat.currency(locale: "en_IN", symbol: "₹");

  // State variables to hold the loaded data
  Map<String, dynamic>? _deliveryData;
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  // --- DATA LOADING ---
  Future<void> _loadOrderDetails() async {
    try {
      // Use Future.wait to fetch both documents concurrently for better performance
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection("deliveryPartners")
            .doc(widget.partnerId)
            .collection("deliveries")
            .doc(widget.deliveryId)
            .get(),
        FirebaseFirestore.instance.collection("orders").doc(widget.orderId).get(),
      ]);

      final deliveryDoc = results[0];
      final orderDoc = results[1];

      if (!mounted) return;

      if (!deliveryDoc.exists || !orderDoc.exists) {
        setState(() {
          _errorMessage = "Order or delivery details not found.";
        });
        return;
      }

      setState(() {
        _deliveryData = deliveryDoc.data();
        _orderData = orderDoc.data();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "An error occurred: $e";
        _isLoading = false;
      });
    }
  }

  // --- UI BUILDING ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Order Details")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductSection(),
            const Divider(height: 40),
            _buildCustomerSection(),
            const Divider(height: 40),
            _buildOrderInfoSection(),
            const SizedBox(height: 30),
            Center(child: _buildStatusButtons(_deliveryData!['status'])),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade200,
              image: _orderData!['productImage'] != null
                  ? DecorationImage(
                image: NetworkImage(_orderData!["productImage"]),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: _orderData!['productImage'] == null
                ? const Icon(Icons.image_not_supported, size: 60, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _orderData!["productName"] ?? "Product Name Not Available",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          formatINR.format(_orderData!["totalAmount"] ?? 0),
          style: const TextStyle(
            color: Colors.green,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Customer Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _detailRow("Name", _orderData!["customerName"] ?? "N/A"),
        _detailRow("Phone", _orderData!["customerPhone"] ?? "N/A"),
        _detailRow("Address", _orderData!["customerAddress"] ?? "N/A"),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _openMap(_orderData!["customerAddress"] ?? ""),
          icon: const Icon(Icons.map, color: Colors.white),
          label: const Text("Open in Google Maps", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
        ),
      ],
    );
  }

  Widget _buildOrderInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Order Information", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _detailRow("Order ID", widget.orderId),
        _detailRow("Payment Type", _orderData!["paymentType"] ?? "N/A"),
        _detailRow("Status", _deliveryData!["status"] ?? "N/A"),
      ],
    );
  }

  // --- HELPER WIDGETS ---
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text("$label:")),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButtons(String currentStatus) {
    return Column(
      children: [
        if (currentStatus == "pending")
          _statusUpdateButton("Accept Order", Colors.blue, "accepted"),
        if (currentStatus == "accepted")
          _statusUpdateButton("Mark as Picked", Colors.orange, "picked"),
        if (currentStatus == "picked")
          _statusUpdateButton("Out for Delivery", Colors.purple, "out_for_delivery"),
        if (currentStatus == "out_for_delivery")
          _statusUpdateButton("Mark as Delivered", Colors.green, "delivered"),
      ],
    );
  }

  Widget _statusUpdateButton(String text, Color color, String newStatus) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () => _updateStatus(newStatus),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        ),
        child: Text(text, style: const TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  // --- ACTIONS & LOGIC ---
  Future<void> _updateStatus(String newStatus) async {
    try {
      final deliveryRef = FirebaseFirestore.instance
          .collection("deliveryPartners")
          .doc(widget.partnerId)
          .collection("deliveries")
          .doc(widget.deliveryId);

      final orderRef = FirebaseFirestore.instance.collection("orders").doc(widget.orderId);

      final updateData = {
        "status": newStatus,
        if (newStatus == "delivered") "deliveredAt": Timestamp.now(),
      };

      await deliveryRef.update(updateData);
      await orderRef.update({"orderStatus": newStatus});

      // Update the local state instead of re-fetching everything
      if (mounted) {
        setState(() {
          _deliveryData!["status"] = newStatus;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e")),
        );
      }
    }
  }

  Future<void> _openMap(String address) async {
    final url = "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}";
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Add feedback for the user if the URL can't be launched
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open maps.")),
        );
      }
    }
  }
}
