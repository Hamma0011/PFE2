import 'package:caferesto/features/personalization/screens/categories/widgets/category_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shop/controllers/category_controller.dart';
import '../../../shop/models/category_model.dart';

class EditCategoryScreen extends StatefulWidget {
  final CategoryModel category;

  const EditCategoryScreen({super.key, required this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen> with SingleTickerProviderStateMixin {
  final CategoryController categoryController = Get.find();
  final _formKey = GlobalKey<FormState>();
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeController();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
    _animationController!.forward();
  }

  void _initializeController() {
    categoryController.initializeForEdit(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Obx(() => _buildBody()),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87,
      title: const Text(
        "Modifier Catégorie",
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    if (categoryController.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    return _fadeAnimation != null
        ? FadeTransition(
      opacity: _fadeAnimation!,
      child: _buildForm(),
    )
        : const SizedBox.shrink();
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Image
              CategoryImageSection(
                onPickImage: categoryController.pickImage,
                pickedImage: categoryController.pickedImage.value,
                existingImageUrl: widget.category.image,
              ),
              const SizedBox(height: 40),

              // Formulaire
              CategoryFormCard(
                children: [
                  CategoryNameField(
                    controller: categoryController.nameController,
                  ),
                  const SizedBox(height: 24),
                  CategoryParentDropdown(
                    selectedParentId: categoryController.selectedParentId.value,
                    categories: categoryController.allCategories,
                    onChanged: (value) {
                      categoryController.selectedParentId.value = value;
                    },
                    excludeCategoryId: widget.category.id,
                  ),
                  const SizedBox(height: 24),
                  Obx(() => CategoryFeaturedSwitch(
                    value: categoryController.isFeatured.value,
                    onChanged: (value) {
                      categoryController.isFeatured.value = value;
                    },
                  )),
                ],
              ),
              const SizedBox(height: 32),

              // Bouton Sauvegarder
              Obx(() => CategorySubmitButton(
                isLoading: categoryController.isLoading.value,
                onPressed: _saveCategory,
                text: "Enregistrer les modifications",
                icon: Icons.check_circle_outline,
              )),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final success = await categoryController.editCategory(widget.category);

      if (success) {
        // Utilise la méthode du contrôleur
        categoryController.showSuccessSnackbar(
            "Catégorie mise à jour avec succès"
        );
        Get.back();
      }
    } catch (e) {
      // Utilise la méthode du contrôleur
      categoryController.showErrorSnackbar(e.toString());
    }
  }}


/*
  void _showSuccessSnackbar() {
    Get.snackbar(
      "Succès",
      "Catégorie mise à jour avec succès",
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade400,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

  void _showErrorSnackbar(String error) {
    Get.snackbar(
      "Erreur",
      error,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade400,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
}*/
/*
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
    // Initialiser les valeurs locales
    nameController = TextEditingController(text: widget.category.name);
    selectedParentId = widget.category.parentId;
    isFeatured = widget.category.isFeatured;

    // Initialiser le contrôleur AVEC les bonnes valeurs
    _initializeController();
  }

  void _initializeController() {
    // Mettre à jour le CategoryController avec les valeurs de la catégorie à éditer
    categoryController.nameController.text = widget.category.name;
    categoryController.selectedParentId.value = widget.category.parentId;
    categoryController.isFeatured.value = widget.category.isFeatured;
    categoryController.pickedImage.value = null; // Réinitialiser l'image
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        newImage = File(pickedFile.path);
      });
      // Mettre à jour aussi le contrôleur
      categoryController.pickedImage.value = newImage;
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      categoryController.isLoading.value = true;

      // Appeler directement editCategory - le contrôleur a déjà les bonnes valeurs
      final success = await categoryController.editCategory(widget.category);

      if (success) {
        Get.snackbar(
          "Succès",
          "Catégorie mise à jour avec succès",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade400,
          colorText: Colors.white,
        );
        Get.back(); // Retour à la page précédente
      }
    } catch (e) {
      Get.snackbar(
        "Erreur",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade400,
        colorText: Colors.white,
      );
    } finally {
      categoryController.isLoading.value = false;
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

                /// Nom - Utilise le contrôleur LOCAL
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Nom de la catégorie",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? "Nom requis" : null,
                  onChanged: (value) {
                    // Mettre à jour le contrôleur en temps réel
                    categoryController.nameController.text = value;
                  },
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
                    const DropdownMenuItem<String?>(
                        value: null, child: Text("Aucune")),
                    ...categoryController.allCategories
                        .where((cat) => cat.id != widget.category.id)
                        .toSet()
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
                    // Mettre à jour le contrôleur
                    categoryController.selectedParentId.value = value;
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
                    // Mettre à jour le contrôleur
                    categoryController.isFeatured.value = val;
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

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}*/
