import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class AddressScreen extends StatefulWidget {
  final bool returnSelectedAddress;

  const AddressScreen({
    super.key,
    this.returnSelectedAddress = false,
  });

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  // Make user nullable and get it from FirebaseAuth
  final _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // Handle the case where the user is not logged in.
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Delivery Addresses")),
        body: const Center(
          child: Text("Please log in to manage your addresses."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Addresses"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormPopup(context, null), // Pass null for a new address
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(_user!.uid)
            .collection("addresses")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No addresses added yet.\nTap + to add one.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final addresses = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 80),
            itemCount: addresses.length,
            itemBuilder: (context, i) {
              final data = addresses[i].data() as Map<String, dynamic>;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Text(
                    data["name"] ?? 'N/A',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(data["address"] ?? 'N/A'),
                      Text("${data["city"] ?? ''}, ${data["state"] ?? ''}"),
                      Text("Pincode: ${data["pincode"] ?? ''}"),
                      const SizedBox(height: 5),
                      Text("Phone: ${data["phone"] ?? ''}",
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // The edit button now directly opens the form with the data.
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.deepPurple),
                        onPressed: () => _showFormPopup(context, data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(context, data["id"]),
                      ),
                    ],
                  ),
                  onTap: widget.returnSelectedAddress
                      ? () {
                          Navigator.pop(context, data);
                        }
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Refactored popup form to handle both Add and Edit.
  Future<void> _showFormPopup(BuildContext context, Map<String, dynamic>? addressData) {
    final isEditing = addressData != null;

    // Controllers are created here to be managed by the dialog's lifecycle.
    final nameCtrl = TextEditingController(text: isEditing ? addressData["name"] : null);
    final phoneCtrl = TextEditingController(text: isEditing ? addressData["phone"] : null);
    final pincodeCtrl = TextEditingController(text: isEditing ? addressData["pincode"] : null);
    final cityCtrl = TextEditingController(text: isEditing ? addressData["city"] : null);
    final stateCtrl = TextEditingController(text: isEditing ? addressData["state"] : null);
    final addressCtrl = TextEditingController(text: isEditing ? addressData["address"] : null);

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEditing ? "Edit Address" : "Add New Address"),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField("Full Name", nameCtrl),
                _buildTextField("Phone Number", phoneCtrl, number: true),
                _buildTextField("Pincode", pincodeCtrl, number: true),
                _buildTextField("City", cityCtrl),
                _buildTextField("State", stateCtrl),
                _buildTextField("Full Address", addressCtrl, maxLines: 3),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              // Pass all necessary data to the save function
              await _saveAddress(
                dialogContext: dialogContext,
                isEditing: isEditing,
                addressId: isEditing ? addressData["id"] : null,
                controllers: {
                  'name': nameCtrl,
                  'phone': phoneCtrl,
                  'pincode': pincodeCtrl,
                  'city': cityCtrl,
                  'state': stateCtrl,
                  'address': addressCtrl,
                },
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: Text(isEditing ? "Update" : "Save"),
          ),
        ],
      ),
    );
  }

  // Updated save logic with error handling and safety checks.
  Future<void> _saveAddress({
    required BuildContext dialogContext,
    required bool isEditing,
    String? addressId,
    required Map<String, TextEditingController> controllers,
  }) async {
    final name = controllers['name']!.text;
    final phone = controllers['phone']!.text;
    final pincode = controllers['pincode']!.text;
    final city = controllers['city']!.text;
    final state = controllers['state']!.text;
    final address = controllers['address']!.text;

    if (name.isEmpty || phone.isEmpty || pincode.isEmpty || city.isEmpty || state.isEmpty || address.isEmpty) {
      _showErrorSnackBar(dialogContext, "Please fill all fields.");
      return;
    }

    try {
      final id = isEditing ? addressId! : const Uuid().v4();
      await FirebaseFirestore.instance
          .collection("users")
          .doc(_user!.uid)
          .collection("addresses")
          .doc(id)
          .set({
        "id": id,
        "name": name,
        "phone": phone,
        "pincode": pincode,
        "city": city,
        "state": state,
        "address": address,
        "createdAt": Timestamp.now(),
      });

      if (!mounted) return;
      _showErrorSnackBar(context, isEditing ? "Address updated successfully" : "Address added successfully", isError: false);
      Navigator.pop(dialogContext); // Close the dialog

    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(dialogContext, "An error occurred: $e");
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context, String addressId) {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Address"),
        content: const Text("Are you sure you want to delete this address?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection("users").doc(_user!.uid).collection("addresses").doc(addressId).delete();
                if (!mounted) return;
                _showErrorSnackBar(context, "Address deleted successfully", isError: false);
                Navigator.pop(dialogContext);
              } catch (e) {
                if (!mounted) return;
                _showErrorSnackBar(dialogContext, "An error occurred: $e");
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool number = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
