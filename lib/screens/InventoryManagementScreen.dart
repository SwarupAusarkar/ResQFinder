// lib/screens/InventoryManagementScreen.dart
import 'package:dotted_border/dotted_border.dart';
import 'package:emergency_res_loc_new/widgets/CustomNavigation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/inventory_item_model.dart';
import '../widgets/InventoryItem.dart';
import 'package:intl/intl.dart';
import '../widgets/masterListModal.dart';

class InventoryMgmtScreen extends StatefulWidget {
  const InventoryMgmtScreen({super.key});

  @override
  State<InventoryMgmtScreen> createState() => _InventoryMgmtScreenState();
}

class _InventoryMgmtScreenState extends State<InventoryMgmtScreen> {
  // ── State (unchanged) ────────────────────────────────────────────────────────
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Search & filter state (NEW) ───────────────────────────────────────────────
  String _searchQuery = "";
  String _sortBy = 'name';        // 'name' | 'quantity_asc' | 'quantity_desc'
  bool _showCriticalOnly = false; // filter: zero-quantity items
  bool _showFilterPanel = false;

  // ── Logic (unchanged) ────────────────────────────────────────────────────────
  Future<void> _adjustQty(InventoryItem item, int change, List<InventoryItem> fullList) async {
    final idx = fullList.indexWhere((i) => i.name == item.name);
    if (idx != -1) {
      final newQty = fullList[idx].quantity + change;
      if (newQty < 0) return;
      fullList[idx] = InventoryItem(name: item.name, quantity: newQty, unit: item.unit, lastUpdated: DateTime.now());
      await _saveToFirebase(fullList);
    }
  }

  Future<void> _deleteItem(InventoryItem item, List<InventoryItem> fullList) async {
    fullList.removeWhere((i) => i.name == item.name);
    await _saveToFirebase(fullList);
  }

  Future<void> _saveToFirebase(List<InventoryItem> list) async {
    final user = _authService.currentUser;
    await _firestore.collection('providers').doc(user?.uid).update({
      'inventory': list.map((e) => e.toMap()).toList(),
    });
  }

  void _showAddMasterListPicker(BuildContext context, List<InventoryItem> currentInv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MasterListPicker(
        currentInventory: currentInv,
        onItemsAdded: (newItems) async {
          final updatedList = [...currentInv, ...newItems];
          await _saveToFirebase(updatedList);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${newItems.length} items added!")));
          }
        },
      ),
    );
  }

  /// Apply search, filter and sort to a list
  List<InventoryItem> _processItems(List<InventoryItem> raw) {
    List<InventoryItem> result = List.from(raw);

    // Search
    if (_searchQuery.isNotEmpty) {
      result = result.where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Filter critical
    if (_showCriticalOnly) result = result.where((i) => i.quantity == 0).toList();

    // Sort
    switch (_sortBy) {
      case 'quantity_asc':
        result.sort((a, b) => a.quantity.compareTo(b.quantity));
        break;
      case 'quantity_desc':
        result.sort((a, b) => b.quantity.compareTo(a.quantity));
        break;
      default: // 'name'
        result.sort((a, b) => a.name.compareTo(b.name));
    }

    return result;
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('providers').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))));
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final String providerName = userData?['name'] ?? "My Facility";
        final List<InventoryItem> inventory = (userData?['inventory'] as List? ?? [])
            .map((e) => InventoryItem.fromMap(e as Map<String, dynamic>))
            .toList();

        final processed = _processItems(inventory);
        final activeFilters = (_showCriticalOnly ? 1 : 0) + (_sortBy != 'name' ? 1 : 0);

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFB),
          body: CustomScrollView(
            slivers: [
              _InventorySliverHeader(
                providerName: providerName,
                totalCount: inventory.length,
                criticalCount: inventory.where((i) => i.quantity == 0).length,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search + filter row
                      _SearchFilterRow(
                        query: _searchQuery,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        activeFilters: activeFilters,
                        onFilterTap: () => setState(() => _showFilterPanel = !_showFilterPanel),
                      ),

                      // Filter panel (animated)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: _showFilterPanel
                            ? _FilterPanel(
                          sortBy: _sortBy,
                          showCriticalOnly: _showCriticalOnly,
                          onSortChanged: (v) => setState(() { _sortBy = v; }),
                          onCriticalChanged: (v) => setState(() => _showCriticalOnly = v),
                        )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 16),

                      // Results label
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '${processed.length} item${processed.length == 1 ? '' : 's'}${_searchQuery.isNotEmpty ? ' for "$_searchQuery"' : ''}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Items list
              processed.isEmpty
                  ? SliverFillRemaining(child: _InventoryEmptyState(hasSearch: _searchQuery.isNotEmpty))
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      if (index == processed.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _AddPlaceholder(onTap: () => _showAddMasterListPicker(context, inventory)),
                        );
                      }
                      final item = processed[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InventoryItemCard(
                          title: item.name,
                          quantity: item.quantity,
                          unit: item.unit,
                          isCritical: item.quantity == 0,
                          lastUpdated: DateFormat('hh:mm a').format(item.lastUpdated),
                          onAdd: () => _adjustQty(item, 1, inventory),
                          onRemove: () => _adjustQty(item, -1, inventory),
                          onDelete: () => _deleteItem(item, inventory),
                        ),
                      );
                    },
                    childCount: processed.length + 1,
                  ),
                ),
              ),
            ],
          ),

        );
      },
    );
  }
}

// ── Sub-components ────────────────────────────────────────────────────────────

class _InventorySliverHeader extends StatelessWidget {
  final String providerName;
  final int totalCount;
  final int criticalCount;

  const _InventorySliverHeader({
    required this.providerName,
    required this.totalCount,
    required this.criticalCount,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 60, // reduced height
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF0D4F4A),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),

      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: const Color(0xFF0D4F4A),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(72, 20, 20, 8), // shifted upward
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  providerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _StatPill(
                      label: '$totalCount Items',
                      icon: Icons.inventory_2_rounded,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(width: 8),
                    if (criticalCount > 0)
                      _StatPill(
                        label: '$criticalCount Critical',
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFDC2626).withOpacity(0.7),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatPill({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}

class _SearchFilterRow extends StatelessWidget {
  final String query;
  final void Function(String) onChanged;
  final int activeFilters;
  final VoidCallback onFilterTap;

  const _SearchFilterRow({required this.query, required this.onChanged, required this.activeFilters, required this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, color: Color(0xFF0D4F4A)),
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: onFilterTap,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: activeFilters > 0 ? const Color(0xFF0D9488) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                ),
                child: Icon(Icons.tune_rounded, color: activeFilters > 0 ? Colors.white : const Color(0xFF0D4F4A), size: 20),
              ),
            ),
            if (activeFilters > 0)
              Positioned(
                top: -4, right: -4,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                  child: Center(child: Text('$activeFilters', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final String sortBy;
  final bool showCriticalOnly;
  final void Function(String) onSortChanged;
  final void Function(bool) onCriticalChanged;

  const _FilterPanel({required this.sortBy, required this.showCriticalOnly, required this.onSortChanged, required this.onCriticalChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort row
          const Text('SORT BY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SortPill(label: 'Name A–Z', value: 'name', selected: sortBy, onTap: onSortChanged),
                const SizedBox(width: 8),
                _SortPill(label: 'Qty: Low → High', value: 'quantity_asc', selected: sortBy, onTap: onSortChanged),
                const SizedBox(width: 8),
                _SortPill(label: 'Qty: High → Low', value: 'quantity_desc', selected: sortBy, onTap: onSortChanged),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Critical filter toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FILTER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    const Text('Show critical items only (qty = 0)', style: TextStyle(fontSize: 13, color: Color(0xFF0D4F4A))),
                  ],
                ),
              ),
              Switch(value: showCriticalOnly, onChanged: onCriticalChanged, activeColor: const Color(0xFFDC2626)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortPill extends StatelessWidget {
  final String label, value, selected;
  final void Function(String) onTap;
  const _SortPill({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF0D4F4A))),
      ),
    );
  }
}

class _InventoryEmptyState extends StatelessWidget {
  final bool hasSearch;
  const _InventoryEmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: const Color(0xFFF0FDF9), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF0D9488)),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No items match your search' : 'No items in inventory',
            style: TextStyle(fontSize: 15, color: Colors.grey[500], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AddPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        color: Colors.grey[300]!,
        strokeWidth: 1.5,
        dashPattern: const [6, 4],
        radius: const Radius.circular(16),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              const Icon(Icons.add_circle_outline_rounded, size: 36, color: Color(0xFF0D9488)),
              const SizedBox(height: 8),
              const Text('Missing a resource?', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D4F4A))),
              const SizedBox(height: 4),
              Text('Add oxygen tanks, ambulances & more', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF0D9488), borderRadius: BorderRadius.circular(20)),
                child: const Text('Browse Categories', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}