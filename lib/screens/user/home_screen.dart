// home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/recipe_model.dart';
import 'recipe_detail_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  List<Recipe> _recipes = [];
  List<Recipe> _favoriteRecipes = [];
  String _activeCategory = 'Popular';
  String? _profileImagePath;

  // Variabel baru untuk Sinkronisasi Nama
  String _displayName = "User DapueOnline";
  bool _isEditingName = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Memuat data user login
    _refreshRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Fungsi memuat data user dari Firebase Auth
  void _loadUserData() {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      setState(() {
        // Ambil display name, jika null ambil email sebelum @
        _displayName = user.displayName ?? user.email?.split('@')[0] ?? "User";
        _nameController.text = _displayName;
      });
    }
  }

  // Fungsi update nama ke Firebase
  Future<void> _updateDisplayName() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null && _nameController.text.isNotEmpty) {
      try {
        await user.updateDisplayName(_nameController.text);
        setState(() {
          _displayName = _nameController.text;
          _isEditingName = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nama berhasil diperbarui")),
        );
      } catch (e) {
        debugPrint("Error update nama: $e");
      }
    }
  }

  Future<void> _refreshRecipes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final uid = authService.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _recipes = [];
          _favoriteRecipes = [];
        });
        return;
      }

      final data = await DatabaseService.instance.readAllRecipesPublic();
      final favoriteIds = await DatabaseService.instance.getFavoriteRecipeIds(
        uid,
      );

      setState(() {
        _recipes = data.map((r) {
          return r.copy(isFavorite: favoriteIds.contains(r.id));
        }).toList();

        _favoriteRecipes = _recipes.where((r) => r.isFavorite).toList();
      });
    } catch (e) {
      debugPrint("Error Load: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Recipe> get _filteredRecipes {
    List<Recipe> filtered = _recipes;
    if (_activeCategory != 'Popular') {
      filtered = filtered
          .where((recipe) => recipe.category == _activeCategory)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (recipe) =>
                recipe.title.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    return filtered;
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _refreshRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMainHomeContent(),
          _buildFavoriteContent(),
          _buildProfileContent(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildMainHomeContent() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Hello, Foodie!",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _displayName, // SINKRON DENGAN NAMA USER
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _buildSearchBar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 25)),
        SliverToBoxAdapter(child: _buildCategoryList()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 25, 25, 15),
            child: Text(
              _searchQuery.isEmpty
                  ? "$_activeCategory Recipes"
                  : "Search results for '$_searchQuery'",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
          ),
        ),
        _isLoading
            ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent),
                ),
              )
            : _filteredRecipes.isEmpty
            ? SliverFillRemaining(
                child: _buildEmptyState(Icons.search_off, "No recipes found"),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildRecipeCard(_filteredRecipes[index]),
                    childCount: _filteredRecipes.length,
                  ),
                ),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Search any recipe...",
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.orangeAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return InkWell(
      onTap: () async {
        final refresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RecipeDetailScreen(recipe: recipe, isReadOnly: true),
          ),
        );
        if (refresh == true) _refreshRecipes();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      image: DecorationImage(
                        image:
                            (recipe.imageUrl != null &&
                                recipe.imageUrl!.isNotEmpty &&
                                File(recipe.imageUrl!).existsSync())
                            ? FileImage(File(recipe.imageUrl!)) as ImageProvider
                            : const AssetImage('assets/images/placeholder.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        recipe.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${recipe.duration} min",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.flash_on_rounded,
                        size: 14,
                        color: Colors.orangeAccent,
                      ),
                      Text(
                        "${recipe.calories} kcal",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final categories = [
      {'icon': Icons.local_fire_department, 'label': 'Popular'},
      {'icon': Icons.restaurant, 'label': 'Western'},
      {'icon': Icons.set_meal, 'label': 'Seafood'},
      {'icon': Icons.local_cafe, 'label': 'Drinks'},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 25),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isActive = _activeCategory == categories[index]['label'];
          return GestureDetector(
            onTap: () => setState(
              () => _activeCategory = categories[index]['label'] as String,
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.orangeAccent : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (isActive)
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        else
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                          ),
                      ],
                    ),
                    child: Icon(
                      categories[index]['icon'] as IconData,
                      color: isActive ? Colors.white : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    categories[index]['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.orangeAccent : Colors.black45,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteContent() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(25, 20, 25, 10),
            child: Text(
              "My Favorites",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _favoriteRecipes.isEmpty
                ? _buildEmptyState(
                    Icons.favorite_border,
                    "No favorite recipes yet",
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: _favoriteRecipes.length,
                    itemBuilder: (context, index) =>
                        _buildRecipeCard(_favoriteRecipes[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final authService = Provider.of<AuthService>(context, listen: false);

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 60),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.orange[50],
                  backgroundImage: _profileImagePath != null
                      ? FileImage(File(_profileImagePath!))
                      : null,
                  child: _profileImagePath == null
                      ? const Icon(
                          Icons.person,
                          size: 70,
                          color: Colors.orangeAccent,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: FloatingActionButton.small(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null)
                        setState(() => _profileImagePath = image.path);
                    },
                    backgroundColor: Colors.orangeAccent,
                    child: const Icon(
                      Icons.camera_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- BAGIAN EDIT NAMA USER ---
          _isEditingName
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: _updateDisplayName,
                      ),
                      hintText: "Enter your name...",
                    ),
                    onSubmitted: (_) => _updateDisplayName(),
                  ),
                )
              : GestureDetector(
                  onTap: () => setState(() => _isEditingName = true),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.edit, size: 16, color: Colors.grey),
                    ],
                  ),
                ),

          const Text("Happy Cooking!", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 35),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              children: [
                _buildModernStatCard(
                  "All Recipes",
                  _recipes.length.toString(),
                  Icons.restaurant_menu,
                ),
                const SizedBox(width: 15),
                _buildModernStatCard(
                  "Favorites",
                  _favoriteRecipes.length.toString(),
                  Icons.favorite,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                _buildProfileMenuTile(Icons.info_outline, "About App", () {
                  showAboutDialog(
                    context: context,
                    applicationName: "DapueOnline", // Nama Aplikasi Baru
                    applicationVersion: "1.0.0",
                    applicationIcon: const Icon(
                      Icons.restaurant_menu,
                      color: Colors.orangeAccent,
                      size: 40,
                    ),
                    children: [
                      const SizedBox(height: 15),
                      const Text(
                        "DapueOnline adalah asisten memasak digital Anda. Temukan berbagai resep masakan nusantara dan mancanegara dengan mudah. "
                        "Simpan resep favorit Anda, pantau kalori, dan kembangkan keahlian memasak Anda setiap hari.",
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Dibuat dengan ❤️ untuk para pecinta kuliner.",
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => authService.signOut(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Log Out",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.orangeAccent, size: 28),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuTile(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.orangeAccent),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orangeAccent,
        unselectedItemColor: const Color(0xFFB2BEC3),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded, size: 28),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded, size: 28),
            label: "Fav",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded, size: 28),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: Colors.grey[200]),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
