import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Import screens
import '../screens/business_owner/dashboard.dart';
import '../screens/Customer/customer_screen.dart';

const Color kPrimaryColor = Color(0xFF1E88E5);
const Color kDarkPrimaryColor = Color(0xFF0D47A1);

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  bool isLoading = false;
  bool isPasswordObscured = true;

  final _formKey = GlobalKey<FormState>();

  String? _selectedRole = 'Customer';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  // -----------------------------
  // SIGNUP
  // -----------------------------
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      final uid = userCredential.user!.uid;

      await _firestore.collection("users").doc(uid).set({
        "fullName": _fullNameController.text.trim(),
        "email": _emailController.text.trim(),
        "role": _selectedRole,
        "createdAt": Timestamp.now(),
      });

      if (_selectedRole == "business_owner") {
        await _firestore.collection("businesses").doc(uid).set({
          "ownerId": uid,
          "fullName": _fullNameController.text.trim(),
          "email": _emailController.text.trim(),
          "createdAt": Timestamp.now(),
        });
      }

      if (!mounted) return;
      await _handleRedirect(userCredential.user!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  // -----------------------------
  // LOGIN
  // -----------------------------
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final userCredential =
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      await _handleRedirect(userCredential.user!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  // -----------------------------
  // REDIRECT
  // -----------------------------
  Future<void> _handleRedirect(User user) async {
    final snap =
    await _firestore.collection("users").doc(user.uid).get();

    if (!mounted) return;

    final data = snap.data();
    if (data == null) return;

    if (data["role"] == "business_owner") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(businessId: user.uid),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CustomerScreen(),
        ),
      );
    }
  }

  // -----------------------------
  // UI STARTS
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),

                  Container(
                    width: 420,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0,5))
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 250),
                        child: isLogin
                            ? _buildLoginForm()
                            : _buildSignupForm(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () =>
                        setState(() => isLogin = !isLogin),
                    child: Text(
                      isLogin
                          ? "Don't have an account? Sign Up"
                          : "Already have an account? Login",
                      style: const TextStyle(color: kPrimaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  // -----------------------------
  // HEADER
  // -----------------------------
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        CircleAvatar(
          radius: 28,
          backgroundColor: Color(0xFFE3F2FD),
          child:
          Icon(Icons.shopping_cart, size: 30, color: kPrimaryColor),
        ),
        SizedBox(width: 12),
        Text(
          "DropKart",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: kDarkPrimaryColor,
          ),
        ),
      ],
    );
  }

  // -----------------------------
  // LOGIN FORM
  // -----------------------------
  Widget _buildLoginForm() {
    return Column(
      key: ValueKey("login"),
      children: [
        const Text(
          "Welcome Back!",
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        _input(_emailController, "Email", Icons.email_outlined,
            validator: (v) =>
            v!.contains("@") ? null : "Invalid email"),

        const SizedBox(height: 15),

        _input(_passwordController, "Password", Icons.lock_outline,
            isPassword: true,
            validator: (v) =>
            v!.length < 6 ? "Min 6 chars" : null),

        const SizedBox(height: 30),

        _authBtn("Login", _login),
      ],
    );
  }

  // -----------------------------
  // SIGNUP FORM
  // -----------------------------
  Widget _buildSignupForm() {
    return Column(
      key: ValueKey("signup"),
      children: [
        const Text(
          "Create Your Account",
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        _input(_fullNameController, "Full Name", Icons.person_outline,
            validator: (v) =>
            v!.isEmpty ? "Enter name" : null),

        const SizedBox(height: 15),

        _input(_emailController, "Email", Icons.email_outlined,
            validator: (v) =>
            v!.contains("@") ? null : "Invalid email"),

        const SizedBox(height: 15),

        _input(_passwordController, "Password", Icons.lock_outline,
            isPassword: true,
            validator: (v) =>
            v!.length < 6 ? "Min 6 chars" : null),

        const SizedBox(height: 15),

        DropdownButtonFormField<String>(
          initialValue: _selectedRole,
          decoration: InputDecoration(
            labelText: "Role",
            prefixIcon: Icon(Icons.person_pin_outlined,
                color: kPrimaryColor),
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
          items: const [
            DropdownMenuItem(
                value: "Customer", child: Text("Customer")),
            DropdownMenuItem(
                value: "Delivery", child: Text("Delivery Partner")),
            DropdownMenuItem(
                value: "business_owner",
                child: Text("Business Owner")),
          ],
          onChanged: (v) => _selectedRole = v,
          validator: (v) =>
          v == null ? "Select role" : null,
        ),

        const SizedBox(height: 30),

        _authBtn("Sign Up", _signUp),
      ],
    );
  }

  // -----------------------------
  // INPUT FIELD
  // -----------------------------
  Widget _input(TextEditingController c, String label, IconData icon,
      {bool isPassword = false, FormFieldValidator<String>? validator}) {
    return TextFormField(
      controller: c,
      obscureText: isPassword ? isPasswordObscured : false,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryColor),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            isPasswordObscured
                ? Icons.visibility_off
                : Icons.visibility,
          ),
          onPressed: () =>
              setState(() => isPasswordObscured = !isPasswordObscured),
        )
            : null,
        filled: true,
        fillColor: Colors.blue.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // -----------------------------
  // BUTTON
  // -----------------------------
  Widget _authBtn(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        padding: EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        text,
        style:
        TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
