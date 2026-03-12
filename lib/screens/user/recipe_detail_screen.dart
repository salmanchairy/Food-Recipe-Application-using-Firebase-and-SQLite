import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:proyek3/screens/admin/recipe_form_screen.dart';
import 'package:confetti/confetti.dart'; // IMPORT BARU
import '../../models/recipe_model.dart';
import '../../services/database_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final bool isReadOnly;

  const RecipeDetailScreen({
    Key? key,
    required this.recipe,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe currentRecipe;
  bool _isFavorite = false;
  
  // VARIABLE BARU
  late ConfettiController _confettiController;
  bool _isCookingStarted = false;

  @override
  void initState() {
    super.initState();
    currentRecipe = widget.recipe;
    _isFavorite = currentRecipe.isFavorite;
    
    // INISIALISASI BARU
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  // DISPOSE BARU
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  List<String> _parseInstructions(String text) {
    return text
        .split(RegExp(r'\n|\.'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // FUNGSI LOGIKA BARU UNTUK TOMBOL
  void _handleStartCooking() {
    setState(() {
      _isCookingStarted = true;
    });

    _confettiController.play();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.local_fire_department, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "SELAMAT MEMASAK! 👨‍🍳🔥",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.restaurant, color: Colors.white),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 10,
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || currentRecipe.id == null) return;

    final uid = user.uid;
    final newStatus = !_isFavorite;

    await DatabaseService.instance.toggleFavoriteStatus(
      uid,
      currentRecipe.id!,
      newStatus,
    );

    setState(() {
      _isFavorite = newStatus;
      currentRecipe = currentRecipe.copy(isFavorite: newStatus);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus ? "Ditambahkan ke Favorit" : "Dihapus dari Favorit",
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: newStatus ? Colors.orangeAccent : Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _deleteRecipe(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Resep'),
        content: const Text('Apakah Anda yakin ingin menghapus resep ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'HAPUS',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && currentRecipe.id != null) {
      await DatabaseService.instance.delete(currentRecipe.id!);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _editRecipe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeFormScreen(recipe: currentRecipe),
      ),
    );

    if (result != null && result is bool && result == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructionPoints = _parseInstructions(currentRecipe.instructions);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack( // MODIFIKASI: Menggunakan Stack agar confetti muncul di atas content
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350.0,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.orangeAccent,
                flexibleSpace: FlexibleSpaceBar(
                  background:
                      currentRecipe.imageUrl != null &&
                              File(currentRecipe.imageUrl!).existsSync()
                          ? Image.file(File(currentRecipe.imageUrl!), fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                ),
                leading: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                ),
                actions: [
                  if (widget.isReadOnly)
                    IconButton(
                      icon: CircleAvatar(
                        backgroundColor: Colors.black26,
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  if (!widget.isReadOnly) ...[
                    IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.black26,
                        child: Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                      onPressed: _editRecipe,
                    ),
                    IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.black26,
                        child: Icon(Icons.delete, color: Colors.white, size: 20),
                      ),
                      onPressed: () => _deleteRecipe(context),
                    ),
                  ],
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentRecipe.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentRecipe.category,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _infoChip(
                              Icons.star,
                              '${currentRecipe.rating}',
                              Colors.amber,
                            ),
                            const SizedBox(width: 12),
                            _infoChip(
                              Icons.timer,
                              '${currentRecipe.duration} Min',
                              Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            _infoChip(
                              Icons.local_fire_department,
                              '${currentRecipe.calories} kcal',
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 40, thickness: 1),
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentRecipe.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Cooking Instructions',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: instructionPoints.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Colors.orangeAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    instructionPoints[index],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // WIDGET CONFETTI BARU (MUNCUL DI TENAH ATAS)
          // WIDGET CONFETTI (Dibuat Lebih Meriah)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive, 
              shouldLoop: false,
              colors: const [
                Colors.orange, 
                Colors.yellow, 
                Colors.red, 
                Colors.blue, 
                Colors.pink, 
                Colors.green,
                Colors.purple
              ],
              numberOfParticles: 40, // Partikel diperbanyak (sebelumnya 30)
              emissionFrequency: 0.1, // Frekuensi semburan lebih cepat
              minBlastForce: 18, // Dorongan ledakan lebih kuat
              maxBlastForce: 50, 
              gravity: 0.2, // Efek jatuh yang lebih natural
              particleDrag: 0.05,
            ),
          ),
        ],
      ),
      // MODIFIKASI: Tombol menghilang jika _isCookingStarted = true
      bottomNavigationBar: _isCookingStarted ? const SizedBox.shrink() : _buildStartCookingButton(),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartCookingButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      color: Colors.white,
      child: ElevatedButton(
        // MODIFIKASI: Panggil fungsi handler baru
        onPressed: _handleStartCooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          'Start Cooking',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}