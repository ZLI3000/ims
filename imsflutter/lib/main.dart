import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Counter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const InventoryPage(),
    );
  }
}

class InventoryItem {
  final int id;
  final String name;
  final double price;
  int stock;
  final String category;

  InventoryItem({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    required this.category
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as int,
      price: json['price'] as double,
      name: json['name'] as String,
      stock: json['stock'] as int,
      category: json['category'] as String,
    );
  }
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final String baseUrl = 'http://127.0.0.1:8000/';
  bool _loading = false;
  bool _initialLoaded = false;
  String? _error;
  List<InventoryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/products'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final items = data.map((e) => InventoryItem.fromJson(e)).toList();
        setState(() {
          _items = items;
          _initialLoaded = true;
        });
      } else {
        setState(() {
          _error = 'Failed to load items (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Could not connect to server';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _updateQuantity(InventoryItem item, int delta) async {
    final newQuantity = item.stock + delta;
    if (newQuantity < 0) return;

    final oldQuantity = item.stock;
    setState(() {
      item.stock = newQuantity; // optimistic update
    });

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/products/${item.id}/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'stock': newQuantity}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        // revert on failure
        setState(() {
          item.stock = oldQuantity;
        });
        _showSnackBar('Failed to update quantity');
      }
    } catch (e) {
      setState(() {
        item.stock = oldQuantity;
      });
      _showSnackBar('Network error while updating');
    }
  }

  Future<void> _createItem(String name, int quantity) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/products/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'quantity': quantity,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newItem = InventoryItem.fromJson(data);
        setState(() {
          _items.add(newItem);
        });
        _showSnackBar('Item added');
      } else {
        _showSnackBar('Failed to add item');
      }
    } catch (e) {
      _showSnackBar('Network error while adding item');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openAddItemDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Inventory Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial quantity',

                ),
              ),
              TextField(
                controller:
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final q = int.tryParse(quantityController.text) ?? 0;
                if (name.isEmpty) {
                  _showSnackBar('Name is required');
                  return;
                }
                Navigator.of(context).pop();
                _createItem(name, q);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    if (_loading && !_initialLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && !_initialLoaded) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchItems,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchItems,
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(child: Text('No items yet. Tap + to add one.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchItems,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            title: Text(item.name),
            subtitle: Text('Quantity: ${item.stock}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _updateQuantity(item, -1),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _updateQuantity(item, 1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Counter'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}