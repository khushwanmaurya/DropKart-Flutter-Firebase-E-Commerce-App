// lib/screens/business_owner/dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Local imports - keep these names unless your files use different class names.
// Make sure product_screen.dart defines ProductScreen,
// order_screen.dart defines OrdersScreen,
// and product_upload.dart defines AddProductScreen.
import 'product_screen.dart';
import 'order_screen.dart';
import 'product_upload.dart';

class DashboardScreen extends StatefulWidget {
  final String businessId;

  const DashboardScreen({super.key, required this.businessId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectedIndex = 0;

  // Friendly titles for the top bar
  final List<String> _titles = [
    'Overview',
    'Products',
    'Orders',
    'Add Product',
  ];

  void _onProductAdded() {
    // Navigate to products tab after adding a product
    setState(() {
      selectedIndex = 1;
    });
    // Optionally show a confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product added — showing Products tab')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The pages shown in the main area. Keep constructors as your files implement.
    final List<Widget> pages = [
      OverviewScreen(businessId: widget.businessId),
      ProductScreen(businessId: widget.businessId),
      OrdersScreen(businessId: widget.businessId),
      AddProductScreen(
        businessId: widget.businessId,
        onProductAdded: _onProductAdded,
      ),
    ];

    final isWide = MediaQuery.of(context).size.width >= 780;

    return Scaffold(
      appBar: isWide
          ? null
          : AppBar(
        title: Text(_titles[selectedIndex], style: GoogleFonts.inter()),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
            },
          )
        ],
      ),
      drawer: isWide ? null : Drawer(child: _buildSidebar(context, isWide)),
      body: isWide
          ? Row(
        children: [
          // Left Sidebar
          Container(
            width: 260,
            color: const Color(0xFFF5F7FB),
            child: _buildSidebar(context, isWide),
          ),

          // Main content
          Expanded(
            child: Container(
              color: const Color(0xFFF9FAFC),
              child: Column(
                children: [
                  // Top area with title and quick actions
                  _buildTopBar(),
                  Expanded(child: pages[selectedIndex]),
                ],
              ),
            ),
          ),
        ],
      )
          : // Mobile layout: single column, pages inside Scaffold body
      Column(
        children: [
          Expanded(child: pages[selectedIndex]),
        ],
      ),
      // Bottom navigation for narrow screens
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (i) => setState(() => selectedIndex = i),
        selectedItemColor: const Color(0xFF6A1B9A),
        unselectedItemColor: Colors.grey[700],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Add'),
        ],
      ),
    );
  }

  // Top bar for wide layout: title, search placeholder, quick stats/actions
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            _titles[selectedIndex],
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.black45),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Search products, orders...', style: GoogleFonts.inter(color: Colors.black54))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _statChip('Sales', '₹0', Colors.green),
          const SizedBox(width: 8),
          _statChip('Orders', '0', Colors.orange),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
            },
          )
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // Sidebar (used in both wide & drawer)
  Widget _buildSidebar(BuildContext context, bool isWide) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Header / brand
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.storefront_outlined, color: Colors.deepPurple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DropKart', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text('Business Panel', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Navigation items
            _sidebarItem(icon: Icons.dashboard_outlined, text: 'Dashboard', index: 0),
            _sidebarItem(icon: Icons.inventory_2_outlined, text: 'Products', index: 1),
            _sidebarItem(icon: Icons.shopping_cart_outlined, text: 'Orders', index: 2),
            _sidebarItem(icon: Icons.add_box_outlined, text: 'Add Product', index: 3),

            const Spacer(),

            // Small footer controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: Text('Settings', style: GoogleFonts.inter()),
                onTap: () {
                  // open settings - add later
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: Text('Logout', style: GoogleFonts.inter()),
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // Individual sidebar item
  Widget _sidebarItem({required IconData icon, required String text, required int index}) {
    final active = selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: active ? Colors.deepPurple : Colors.grey[700]),
      title: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: active ? Colors.deepPurple : Colors.black87,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      selected: active,
      selectedTileColor: Colors.white,
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }
}

// ---------------------- OVERVIEW SCREEN ---------------------- //

class OverviewScreen extends StatelessWidget {
  final String businessId;
  const OverviewScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    // Placeholder dashboard cards - replace with real data queries & charts
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          // KPI row
          Row(
            children: [
              Expanded(child: _kpiCard('Total Sales', '₹0', Icons.attach_money, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Orders', '0', Icons.shopping_cart, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _kpiCard('Products', '0', Icons.inventory_2, Colors.indigo)),
            ],
          ),
          const SizedBox(height: 18),
          // Recent orders placeholder
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2)),
            ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Orders', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                const Text('No orders yet. Orders will appear here.'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Quick actions
          Row(
            children: [
              Expanded(child: _actionCard(context, Icons.add_box_outlined, 'Add Product')),
              const SizedBox(width: 12),
              Expanded(child: _actionCard(context, Icons.inventory_2_outlined, 'Manage Products')),
              const SizedBox(width: 12),
              Expanded(child: _actionCard(context, Icons.shopping_cart_outlined, 'View Orders')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ])
        ],
      ),
    );
  }

  Widget _actionCard(BuildContext context, IconData icon, String title) {
    return InkWell(
      onTap: () {
        // Map actions to pages if needed: Add Product / Manage Products / Orders
        if (title == 'Add Product') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(businessId: businessId, onProductAdded: () {})));
        } else if (title == 'Manage Products') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(businessId: businessId)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => OrdersScreen(businessId: businessId)));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white, boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2)),
        ]),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.deepPurple.shade50, child: Icon(icon, color: Colors.deepPurple)),
            const SizedBox(width: 12),
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
