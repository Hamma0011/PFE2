import 'dart:io';
import 'package:caferesto/data/repositories/product/produit_repository.dart';
import 'package:caferesto/features/personalization/controllers/user_controller.dart';
import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../etablissement_controller.dart';

class ProduitController extends GetxController {
  static ProduitController get instance => Get.find();

  // --- FORMULAIRES ET CONTROLLERS ---
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final preparationTimeController = TextEditingController();
  final stockQuantityController = TextEditingController();

  final isStockable = false.obs;
  final selectedCategoryId = Rx<String?>(null);
  final ImagePicker _picker = ImagePicker();
  final pickedImage = Rx<File?>(null);

  // --- DÉPENDANCES ---
  final UserController userController = Get.find<UserController>();
  late final ProduitRepository produitRepository;

  // --- ÉTATS ET LISTES ---
  final isLoading = false.obs;
  RxList<ProduitModel> allProducts = <ProduitModel>[].obs;
  RxList<ProduitModel> filteredProducts = <ProduitModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    produitRepository = Get.put(ProduitRepository());
  }

  // --- IMAGE ---
  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        pickedImage.value = File(pickedFile.path);
      }
    } catch (e) {
      _showErrorSnackbar("Erreur lors de la sélection de l'image: $e");
    }
  }

  Future<String?> uploadProductImage(File imageFile) async {
    try {
      return await produitRepository.uploadProductImage(imageFile);
    } catch (e) {
      _showErrorSnackbar("Erreur lors de l'upload de l'image: $e");
      return null;
    }
  }

  // --- CHARGEMENT DES PRODUITS ---
  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final productsList = await produitRepository.getAllProducts();
      allProducts.assignAll(productsList);
      filteredProducts.assignAll(productsList); // initialise la liste filtrée
    } catch (e) {
      _showErrorSnackbar('Erreur lors du chargement des produits: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<ProduitModel>> getProductsByEtablissement(String etablissementId) async {
    try {
      return await produitRepository.getProductsByEtablissement(etablissementId);
    } catch (e) {
      _showErrorSnackbar('Erreur: $e');
      return [];
    }
  }

  Future<List<ProduitModel>> getProductsByCategory(String categoryId) async {
    try {
      return await produitRepository.getProductsByCategory(categoryId);
    } catch (e) {
      _showErrorSnackbar('Erreur: $e');
      return [];
    }
  }

  // --- ÉTABLISSEMENT ---
  Future<String?> getEtablissementIdUtilisateur() async {
    try {
      final etablissementController = Get.find<EtablissementController>();
      final etablissement = await etablissementController.getEtablissementUtilisateurConnecte();

      if (etablissement == null) {
        _showErrorSnackbar("Aucun établissement trouvé. Veuillez d'abord créer un établissement.");
        return null;
      }

      return etablissement.id;
    } catch (e) {
      _showErrorSnackbar("Erreur lors de la récupération de l'établissement: $e");
      return null;
    }
  }

  // --- AJOUT / MODIFICATION / SUPPRESSION ---
  Future<bool> addProduct(ProduitModel produit) async {
    if (!_hasProductManagementPermission()) {
      _showErrorSnackbar("Vous n'avez pas la permission d'ajouter un produit.");
      return false;
    }

    if (produit.name.isEmpty) {
      _showErrorSnackbar("Le nom du produit ne peut pas être vide.");
      return false;
    }

    if (produit.etablissementId.isEmpty) {
      _showErrorSnackbar("ID d'établissement manquant.");
      return false;
    }

    try {
      isLoading.value = true;
      await produitRepository.addProduct(produit);
      await fetchProducts();
      _showSuccessSnackbar('Produit "${produit.name}" ajouté avec succès');
      return true;
    } catch (e) {
      _showErrorSnackbar("Erreur lors de l'ajout: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProduct(ProduitModel produit) async {
    if (!_hasProductManagementPermission()) {
      _showErrorSnackbar("Vous n'avez pas la permission de modifier un produit.");
      return false;
    }

    if (produit.name.isEmpty) {
      _showErrorSnackbar("Le nom du produit ne peut pas être vide.");
      return false;
    }

    try {
      isLoading.value = true;
      await produitRepository.updateProduct(produit);
      await fetchProducts();
      _showSuccessSnackbar('Produit "${produit.name}" modifié avec succès');
      return true;
    } catch (e) {
      _showErrorSnackbar("Erreur lors de la modification: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (!_hasProductManagementPermission()) {
      _showErrorSnackbar("Vous n'avez pas la permission de supprimer un produit.");
      return;
    }

    try {
      isLoading.value = true;
      await produitRepository.deleteProduct(productId);
      await fetchProducts();
      _showSuccessSnackbar('Produit supprimé avec succès');
    } catch (e) {
      _showErrorSnackbar("Erreur lors de la suppression: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // --- RECHERCHE / FILTRAGE ---
  void filterProducts(String query) {
    if (query.isEmpty) {
      filteredProducts.assignAll(allProducts);
    } else {
      final filtered = allProducts.where((product) =>
          product.name.toLowerCase().contains(query.toLowerCase())).toList();
      filteredProducts.assignAll(filtered);
    }
  }

  // --- AUTRES OUTILS ---
  bool _hasProductManagementPermission() {
    final userRole = userController.user.value.role;
    return userRole == 'Gérant' || userRole == 'Admin';
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      "Succès",
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade400,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 3),
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
      duration: const Duration(seconds: 4),
    );
  }

  ProduitModel? getProductById(String id) {
    try {
      return allProducts.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  List<ProduitModel> getAvailableProducts() {
    return allProducts.where((product) => product.isAvailable).toList();
  }

  List<ProduitModel> getProductsWithStock() {
    return allProducts
        .where((product) => product.isStockable && product.stockQuantity > 0)
        .toList();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    preparationTimeController.dispose();
    stockQuantityController.dispose();
    super.onClose();
  }
}
