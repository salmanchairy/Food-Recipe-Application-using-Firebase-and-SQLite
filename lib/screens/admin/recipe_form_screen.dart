import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/recipe_model.dart';
import '../../services/database_service.dart';

class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;

  const RecipeFormScreen({Key? key, this.recipe}) : super(key: key);

  @override
  _RecipeFormScreenState createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _title, _description, _instructions, _category;
  late int _calories, _duration;
  String? _imageUrl;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.recipe != null;

    _title = widget.recipe?.title ?? '';
    _description = widget.recipe?.description ?? '';
    _instructions = widget.recipe?.instructions ?? '';
    _category = widget.recipe?.category ?? 'Popular';
    _calories = widget.recipe?.calories ?? 0;
    _duration = widget.recipe?.duration ?? 0;
    _imageUrl = widget.recipe?.imageUrl;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageUrl = pickedFile.path);
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'admin_default';

    final recipeData = Recipe(
      id: widget.recipe?.id,
      userId: userId,
      title: _title,
      description: _description,
      instructions: _instructions,
      imageUrl: _imageUrl,
      calories: _calories,
      duration: _duration,
      category: _category,
      rating: widget.recipe?.rating ?? 4.5,
    );

    try {
      if (_isEditMode) {
        await DatabaseService.instance.update(recipeData);
      } else {
        await DatabaseService.instance.create(recipeData);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Resep berhasil disimpan!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? "Edit Resep" : "Tambah Resep Baru"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    image: _imageUrl != null && _imageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: FileImage(File(_imageUrl!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (_imageUrl == null || _imageUrl!.isEmpty)
                      ? const Icon(Icons.camera_alt,
                          size: 50, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(
                  labelText: 'Judul Resep',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Judul tidak boleh kosong' : null,
                onSaved: (v) => _title = v!,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _category,
                items: ['Popular', 'Western', 'Seafood', 'Drinks']
                    .map(
                      (label) => DropdownMenuItem(
                        value: label,
                        child: Text(label),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _duration.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Durasi (Menit)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (v) =>
                          _duration = int.tryParse(v ?? '') ?? 0,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      initialValue: _calories.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Kalori',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (v) =>
                          _calories = int.tryParse(v ?? '') ?? 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onSaved: (v) => _description = v!,
              ),
              const SizedBox(height: 15),

              TextFormField(
                initialValue: _instructions,
                decoration: const InputDecoration(
                  labelText: 'Instruksi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                onSaved: (v) => _instructions = v!,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    _isEditMode ? "Update Resep" : "Simpan Resep",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
