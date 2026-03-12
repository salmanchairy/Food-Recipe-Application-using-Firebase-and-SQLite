import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/recipe_model.dart';
import '../../services/database_service.dart';
import 'recipe_form_screen.dart';
import '../user/recipe_detail_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  bool _isLoading = true;
  // Di dalam _AdminHomeScreenState
  String _selectedCategory = 'Popular'; // Ubah dari 'All'
  int _totalUsers = 0; // Variabel baru untuk menampung jumlah akun

  @override
  void initState() {
    super.initState();
    _refreshRecipes();
  }

  Future<void> _refreshRecipes() async {
  setState(() => _isLoading = true);
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = await DatabaseService.instance.readAllRecipes(user.uid);
      final userCount = await DatabaseService.instance.getTotalUserCount();

      setState(() {
        _allRecipes = data;
        _totalUsers = userCount;
        // Pastikan filter awal adalah Popular
        _applyFilter(_selectedCategory); 
      });
    }
  } catch (e) {
    debugPrint("Error loading admin data: $e");
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _applyFilter(String category) {
    setState(() {
      _selectedCategory = category;
      // Jika 'Popular' dipilih, tampilkan semua resep
      if (category == 'Popular') {
        _filteredRecipes = _allRecipes;
      } else {
        _filteredRecipes = _allRecipes
            .where((r) => r.category == category)
            .toList();
      }
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Admin Panel",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            )
          : Column(
              children: [
                _buildStatisticsHeader(), // Header dengan info Akun
                _buildCategoryFilterBar(),
                Expanded(
                  child: _filteredRecipes.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredRecipes.length,
                          itemBuilder: (context, index) =>
                              _buildRecipeCard(_filteredRecipes[index]),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orangeAccent,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RecipeFormScreen()),
          );
          if (result == true) _refreshRecipes();
        },
        label: const Text("Resep Baru"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // Widget Statistik dengan tambahan Total Akun
  Widget _buildStatisticsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Resep", _allRecipes.length.toString()),
          _buildDivider(),
          _buildStatItem(
            "Kategori",
            _allRecipes.map((r) => r.category).toSet().length.toString(),
          ),
          _buildDivider(),
          _buildStatItem("Akun", _totalUsers.toString()), // Item Akun Baru
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 30, color: Colors.white30);
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }

  Widget _buildCategoryFilterBar() {
    // Hapus 'All' dari list ini
    final categories = ['Popular', 'Western', 'Seafood', 'Drinks'];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => _applyFilter(cat),
              selectedColor: Colors.orangeAccent,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
              backgroundColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  RecipeDetailScreen(recipe: recipe, isReadOnly: false),
            ),
          );
          if (result == true) _refreshRecipes();
        },
        child: Row(
          children: [
            Hero(
              tag: 'recipe-${recipe.id}',
              child: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image:
                        recipe.imageUrl != null &&
                            File(recipe.imageUrl!).existsSync()
                        ? FileImage(File(recipe.imageUrl!)) as ImageProvider
                        : const AssetImage('assets/placeholder.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.category,
                      style: TextStyle(color: Colors.orange[700], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${recipe.duration}m",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.local_fire_department_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "${recipe.calories} kcal",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                bool confirm = await _showDeleteDialog(recipe.title);
                if (confirm) {
                  await DatabaseService.instance.delete(recipe.id!);
                  _refreshRecipes();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Tidak ada resep di kategori $_selectedCategory",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteDialog(String title) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text("Hapus Resep"),
            content: Text("Yakin ingin menghapus '$title'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Hapus", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }
}