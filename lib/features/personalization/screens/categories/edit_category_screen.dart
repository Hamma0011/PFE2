import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shop/controllers/category_controller.dart';
import '../../../shop/models/category_model.dart';

class EditCategoryScreen extends StatefulWidget {
  final CategoryModel category;

  const EditCategoryScreen({super.key, required this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> {
  final CategoryController categoryController = Get.find();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  String? selectedParentId;
  bool isFeatured = false;
  File? newImage;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.category.name);
    selectedParentId = widget.category.parentId;
    isFeatured = widget.category.isFeatured;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        newImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    categoryController.nameController.text = nameController.text.trim();
    categoryController.selectedParentId.value = selectedParentId;
    categoryController.isFeatured.value = isFeatured;

    if (newImage != null) {
      categoryController.pickedImage.value = newImage;
    }

    try {
      categoryController.isLoading.value = true;
      await categoryController.editCategory(widget.category);
      categoryController.isLoading.value = false;

      Get.snackbar(
        "Succès",
        "Catégorie mise à jour avec succès",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade400,
        colorText: Colors.white,
      );

      Get.back(); // Retour à la page précédente
    } catch (e) {
      categoryController.isLoading.value = false;

      Get.snackbar(
        "Erreur",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier Catégorie"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(
              () => categoryController.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : Form(
            key: _formKey,
            child: ListView(
              children: [
                /// Image
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: newImage != null
                          ? FileImage(newImage!)
                          : NetworkImage(widget.category.image)
                      as ImageProvider,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: CircleAvatar(
                          backgroundColor: Colors.blue,
                          radius: 18,
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                /// Nom
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Nom de la catégorie",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? "Nom requis" : null,
                ),
                const SizedBox(height: 20),

                /// Parent
                DropdownButtonFormField<String?>(
                  value: selectedParentId,
                  decoration: const InputDecoration(
                    labelText: "Catégorie parente",
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text("Aucune")),
                    ...categoryController.allCategories
                        .where((cat) => cat.id != widget.category.id) // Exclure la catégorie elle-même
                        .toSet() // Supprimer les doublons si nécessaire
                        .map((cat) => DropdownMenuItem<String?>(
                      value: cat.id,
                      child: Text(cat.name),
                    ))
                        .toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedParentId = value;
                    });
                  },
                ),

                const SizedBox(height: 20),

                /// En vedette
                SwitchListTile(
                  title: const Text("Catégorie en vedette"),
                  value: isFeatured,
                  onChanged: (val) {
                    setState(() {
                      isFeatured = val;
                    });
                  },
                ),
                const SizedBox(height: 20),

                /// Bouton Sauvegarder
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveCategory,
                    child: const Text("Enregistrer"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
