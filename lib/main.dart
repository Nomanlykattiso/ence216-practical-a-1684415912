// main.dart
// CampusCafé Order Counter — Practical A (with challenge exercises)
//
// This version keeps the CampusCafé name and structure, but uses a
// different menu and color theme from the original handout, and adds
// all four graded challenge exercises.
//
// Still no database here — everything lives in memory (state) and
// disappears when the app closes. That's the point of this practical:
// learn setState() before learning persistence (Practical B).

import 'package:flutter/material.dart';

void main() => runApp(const CampusCafeApp());

// ---------------- APP SHELL (stateless — never changes) ----------------
class CampusCafeApp extends StatelessWidget {
  const CampusCafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusCafé',
      theme: ThemeData(
        // Different from the handout's navy (0xFF002060) — a deep teal.
        colorSchemeSeed: const Color(0xFF00695C),
        useMaterial3: true,
      ),
      home: const OrderPage(),
    );
  }
}

// ---------------- MENU MODEL ----------------
// Immutable — the menu itself never changes, only the quantities do.
class MenuItem {
  final String name;
  final double price; // in GHS
  const MenuItem(this.name, this.price);
}

// Different dishes from the original handout's Jollof/Waakye/Banku menu.
const menu = [
  MenuItem('Fufu & Light Soup', 30.00),
  MenuItem('Rice & Groundnut Stew', 25.00),
  MenuItem('Yam & Kontomire Stew', 28.00),
  MenuItem('Spring Rolls (3 pcs)', 10.00),
  MenuItem('Asana (Millet Drink)', 6.00),
  MenuItem('Bofrot (4 pcs)', 8.00),
];

// ---------------- REUSABLE QUANTITY STEPPER ----------------
// CHALLENGE — Refactor (3 marks)
//
// This is its own widget instead of being built inline inside the
// list. It's a StatelessWidget, not a StatefulWidget, even though the
// quantity it shows keeps changing. That's because this widget does
// NOT own the number itself — it only displays whatever "qty" value
// it's handed, and reports taps back up through the two callback
// functions (onAdd / onRemove). The real state (the order map) still
// lives up in _OrderPageState. Keeping small display widgets like
// this stateless is a common, useful Flutter pattern.
class QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback? onRemove; // null disables the button

  const QtyStepper({
    required this.qty,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: onRemove,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: onAdd,
        ),
      ],
    );
  }
}

// ---------------- STATEFUL ORDER PAGE ----------------
class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  // THE STATE: how many of each menu item (by index) has been ordered.
  final Map<int, int> _qty = {};

  // CHALLENGE — Search filter (3 marks)
  // Created in initState(), released in dispose().
  late final TextEditingController _searchCtrl;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    debugPrint('OrderPage: initState() — runs ONCE');
    _searchCtrl = TextEditingController();
    _searchCtrl.addListener(() {
      setState(() => _searchTerm = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    debugPrint('OrderPage: dispose() — cleaning up');
    _searchCtrl.dispose();
    super.dispose();
  }

  // Computed value — derived from _qty rather than stored separately.
  // This avoids the total ever getting "out of sync" with the quantities.
  double get _total {
    var sum = 0.0;
    _qty.forEach((i, q) => sum += menu[i].price * q);
    return sum;
  }

  // CHALLENGE — Order badge (2 marks)
  // Total number of items ordered (not distinct dishes).
  int get _itemCount => _qty.values.fold(0, (a, b) => a + b);

  // Filters the MENU based on the search box. Quantities are still
  // tracked by each dish's ORIGINAL menu index, so a half-typed
  // search term never mixes up which dish's count you're adjusting.
  List<int> get _visibleIndexes {
    if (_searchTerm.isEmpty) {
      return List.generate(menu.length, (i) => i);
    }
    return [
      for (var i = 0; i < menu.length; i++)
        if (menu[i].name.toLowerCase().contains(_searchTerm)) i,
    ];
  }

  // Every + or - tap goes through here, wrapped in setState()
  // so Flutter knows to rebuild the screen.
  void _change(int index, int delta) {
    setState(() {
      final next = (_qty[index] ?? 0) + delta;
      if (next <= 0) {
        _qty.remove(index); // never goes below zero
      } else {
        _qty[index] = next;
      }
    });
  }

  Future<void> _clearOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear order?'),
        content: const Text('All quantities will reset to zero.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    // mounted guard: the dialog is async, so the page could theoretically
    // have been closed before the user answers. Calling setState() on a
    // disposed page throws an error — this check protects against that.
    if (confirmed == true && mounted) {
      setState(() => _qty.clear());

      // CHALLENGE — SnackBar feedback (2 marks)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('OrderPage: build() — drawing UI');
    final visible = _visibleIndexes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusCafé — New Order'),
        actions: [
          // CHALLENGE — Order badge (2 marks)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Badge(
              label: Text('$_itemCount'),
              isLabelVisible: _itemCount > 0,
              child: IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Clear order',
                onPressed: _qty.isEmpty ? null : _clearOrder,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // CHALLENGE — Search filter (3 marks)
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search menu...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchTerm.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _searchCtrl.clear,
                      ),
              ),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('No dishes match your search'))
                : ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, listIndex) {
                      final menuIndex = visible[listIndex];
                      final item = menu[menuIndex];
                      final q = _qty[menuIndex] ?? 0;
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text('GHS ${item.price.toStringAsFixed(2)}'),
                        // CHALLENGE — Refactor (3 marks): using the
                        // extracted QtyStepper widget from above.
                        trailing: QtyStepper(
                          qty: q,
                          onAdd: () => _change(menuIndex, 1),
                          onRemove: q == 0 ? null : () => _change(menuIndex, -1),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                'GHS ${_total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}