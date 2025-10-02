import 'dart:io';

import 'package:caferesto/features/personalization/controllers/user_controller.dart';
import 'package:caferesto/data/repositories/categories/category_repository.dart';
import 'package:caferesto/data/repositories/product/product_repository.dart';
import 'package:caferesto/features/shop/models/category_model.dart';
import 'package:caferesto/features/shop/models/product_model.dart';
import 'package:caferesto/utils/constants/image_strings.dart';
import 'package:caferesto/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class CategoryController extends GetxController {
  /// Singleton pour récupérer le contrôleur partout
  static CategoryController get instance => Get.find();

  /// Formulaire pour l'ajout de catégorie
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final parentIdController = TextEditingController();

  /// Case "Catégorie en vedette"
  final isFeatured = false.obs;

  /// Catégorie parente sélectionnée
  final Rx<String?> selectedParentId = Rx<String?>(null);

  /// Image picker
  final ImagePicker _picker = ImagePicker();
  final pickedImage = Rx<File?>(null);

  /// Contrôleur utilisateur pour vérifier le rôle
  final UserController userController = Get.find<UserController>();

  /// Variables pour état et listes
  final isLoading = false.obs;
  final _categoryRepository = Get.put(CategoryRepository());
  RxList<CategoryModel> allCategories = <CategoryModel>[].obs;
  RxList<CategoryModel> featuredCategories = <CategoryModel>[].obs;

  /// -----------------------------
  /// Méthodes
  /// -----------------------------

  /// Ouvre la galerie pour sélectionner une image
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      pickedImage.value = File(pickedFile.path);
    }
  }

  /// Réinitialise le formulaire après ajout ou annulation
  void clearForm() {
    nameController.clear();
    parentIdController.clear();
    isFeatured.value = false;
    pickedImage.value = null;
    selectedParentId.value = null;
  }

  @override
  void onInit() {
    super.onInit();
    fetchCategories(); // Charger les catégories au démarrage
  }

  /// Charger toutes les catégories depuis le repository
  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;

      final categories = await _categoryRepository.getAllCategories();

      // Mettre à jour la liste complète
      allCategories.assignAll(categories);

      // Mettre à jour les catégories en vedette (max 8)
      featuredCategories.assignAll(
        categories.where((cat) => cat.isFeatured).take(8).toList(),
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur!', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Récupérer les sous-catégories d'une catégorie
  Future<List<CategoryModel>> getSubCategories(String categoryId) async {
    try {
      return await _categoryRepository.getSubCategories(categoryId);
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: e.toString());
      return [];
    }
  }

  /// Récupérer les produits pour une catégorie ou sous-catégorie
  Future<List<ProductModel>> getCategoryProducts({
    required String categoryId,
    int limit = 4,
  }) async {
    try {
      return await ProductRepository.instance
          .getProductsForCategory(categoryId: categoryId, limit: limit);
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: e.toString());
      return [];
    }
  }
  /// Ajouter une nouvelle catégorie
  Future<void> addCategory() async {
    // 1. Validation du formulaire
    if (!formKey.currentState!.validate()) {
      print("Validation du formulaire échouée");
      return;
    }

    // 2. Vérifier le rôle utilisateur
    if (userController.user.value.role != 'Gérant' &&
        userController.user.value.role != 'Admin') {
      TLoaders.errorSnackBar(
        title: 'Erreur',
        message: "Vous n'avez pas la permission d'ajouter une catégorie.",
      );
      return;
    }

    try {
      isLoading.value = true;
      print("Début de l'ajout de catégorie...");

      // 3. Définir l'image (image par défaut si non sélectionnée)
      String imageUrl = TImages.pasdimage;

      if (pickedImage.value != null) {
        imageUrl =
        await _categoryRepository.uploadCategoryImage(pickedImage.value!);
      }

      // 4. Préparer parentId (null si vide)
      final String? parentId = (selectedParentId.value != null &&
          selectedParentId.value!.isNotEmpty)
          ? selectedParentId.value
          : null;

      // 5. Créer l'objet CategoryModel
      final newCategory = CategoryModel(
        id: '', // id généré automatiquement par Supabase
        name: nameController.text.trim(),
        image: imageUrl,
        parentId: parentId,
        isFeatured: isFeatured.value,
      );

      print("Catégorie à créer: ${newCategory.toJson()}");

      // 6. Ajouter la catégorie dans la base
      await _categoryRepository.addCategory(newCategory);

      // 7. Rafraîchir les catégories après ajout
      await fetchCategories();

      // 8. Message succès
      TLoaders.successSnackBar(
        title: 'Succès',
        message:
        'Catégorie "${nameController.text.trim()}" ajoutée avec succès',
      );

      print("Catégorie ajoutée avec succès");

      // 9. Réinitialiser le formulaire
      clearForm();
    } catch (e) {
      print("Erreur lors de l'ajout: $e");
      TLoaders.errorSnackBar(title: 'Erreur', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
  /// Modifier une catégorie
  Future<bool> editCategory(CategoryModel category) async {
    if (userController.user.value.role != 'Gérant' &&
        userController.user.value.role != 'Admin') {
      TLoaders.errorSnackBar(
        title: 'Erreur',
        message: "Vous n'avez pas la permission de modifier une catégorie.",
      );
      return false;
    }

    try {
      isLoading.value = true;

      String imageUrl = category.image;
      if (pickedImage.value != null) {
        imageUrl = await _categoryRepository.uploadCategoryImage(pickedImage.value!);
      }

      final updatedCategory = CategoryModel(
        id: category.id,
        name: nameController.text.trim().isNotEmpty
            ? nameController.text.trim()
            : category.name,
        image: imageUrl,
        parentId: selectedParentId.value ?? category.parentId,
        isFeatured: isFeatured.value,
      );

      await _categoryRepository.updateCategory(updatedCategory);
      await fetchCategories();

      TLoaders.successSnackBar(
        title: "Succès",
        message: "Catégorie mise à jour avec succès.",
      );

      clearForm();
      return true;
    } catch (e) {
      TLoaders.errorSnackBar(title: "Erreur", message: e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }




  /// Supprimer une catégorie
  Future<void> removeCategory(String categoryId) async {
    if (userController.user.value.role != 'Gérant' &&
        userController.user.value.role != 'Admin') {
      TLoaders.errorSnackBar(
        title: 'Erreur',
        message: "Vous n'avez pas la permission de supprimer une catégorie.",
      );
      return;
    }

    try {
      isLoading.value = true;

      await _categoryRepository.deleteCategory(categoryId);
      await fetchCategories();

      TLoaders.successSnackBar(
        title: "Succès",
        message: "Catégorie supprimée avec succès.",
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: "Erreur", message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
  String getParentName(String parentId) {
    try {
      final parent = allCategories.firstWhere((cat) => cat.id == parentId);
      return parent.name;
    } catch (e) {
      return "Inconnue";
    }
  }

}