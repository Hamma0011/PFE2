import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';

import '../../controllers/product/produit_controller.dart';
import '../../models/produit_model.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../../data/repositories/categories/category_repository.dart';
import '../../controllers/etablissement_controller.dart';
import '../../../personalization/screens/categories/widgets/category_form_widgets.dart';

class AddProduitScreen extends StatefulWidget {
  final ProduitModel? produit;

  const AddProduitScreen({super.key, this.produit});

  @override
  State<AddProduitScreen> createState() => _AddProduitScreenState();
}

class _AddProduitScreenState extends State<AddProduitScreen>
    with SingleTickerProviderStateMixin {
  final ProduitController _produitController = Get.find<ProduitController>();
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final UserController _userController = Get.find<UserController>();
  final EtablissementController _etablissementController = Get.find<EtablissementController>();

  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tempsPreparationController = TextEditingController();
  final _quantiteStockController = TextEditingController();
  final _tailleController = TextEditingController();
  final _prixTailleController = TextEditingController();
  final _supplementController = TextEditingController();

  String? _selectedCategorieId;
  final List<ProductSizePrice> _taillesPrix = [];
  final List<String> _supplements = [];

  List<Map<String, dynamic>> _categories = [];
  bool _isEditing = false;
  bool _estStockable = false;
  bool _isLoading = false;
  File? _selectedImage;

  // Animations
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.produit != null;
    if (_isEditing) {
      _fillFormData();
    }
    _initializeAnimation();
    _loadCategories();
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

  void _fillFormData() {
    final produit = widget.produit!;
    _nomController.text = produit.name;
    _descriptionController.text = produit.description ?? '';
    _tempsPreparationController.text = produit.preparationTime.toString();
    _selectedCategorieId = produit.categoryId;
    _taillesPrix.addAll(produit.sizesPrices);
    _supplements.addAll(produit.supplements);
    _estStockable = produit.isStockable;
    _quantiteStockController.text = produit.stockQuantity.toString();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);

      final categories = await _categoryRepository.getAllCategories();

      final uniqueCategories = _removeDuplicateCategories(
          categories.map((cat) => {
            'id': cat.id,
            'name': cat.name,
          }).toList()
      );

      setState(() {
        _categories = uniqueCategories;
        _isLoading = false;
      });

      if (_isEditing && _selectedCategorieId != null) {
        final categoryExists = _categories.any((cat) => cat['id'] == _selectedCategorieId);
        if (!categoryExists) {
          setState(() => _selectedCategorieId = null);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Impossible de charger les catégories: $e');
    }
  }

  List<Map<String, dynamic>> _removeDuplicateCategories(List<Map<String, dynamic>> categories) {
    final seenIds = <String>{};
    return categories.where((category) {
      final id = category['id'] as String;
      if (!seenIds.contains(id)) {
        seenIds.add(id);
        return true;
      }
      return false;
    }).toList();
  }

  List<DropdownMenuItem<String>> _buildCategoryDropdownItems() {
    if (_isLoading) {
      return [
        const DropdownMenuItem<String>(
          value: 'loading',
          child: Text('Chargement des catégories...'),
        )
      ];
    }

    if (_categories.isEmpty) {
      return [
        const DropdownMenuItem<String>(
          value: 'empty',
          child: Text('Aucune catégorie disponible'),
        )
      ];
    }

    final items = _categories.map<DropdownMenuItem<String>>((categorie) {
      return DropdownMenuItem<String>(
        value: categorie['id'] as String,
        child: Text(categorie['name'] as String),
      );
    }).toList();

    if (_selectedCategorieId == null) {
      items.insert(0, const DropdownMenuItem<String>(
        value: null,
        child: Text('Sélectionnez une catégorie'),
      ));
    }

    return items;
  }

  bool _isSelectedCategoryValid() {
    if (_selectedCategorieId == null) return true;
    if (_isLoading) return _selectedCategorieId == 'loading';
    if (_categories.isEmpty) return _selectedCategorieId == 'empty';
    return _categories.any((cat) => cat['id'] == _selectedCategorieId);
  }

  void _ajouterTaille() {
    final taille = _tailleController.text.trim();
    final prixText = _prixTailleController.text.trim();

    if (taille.isEmpty || prixText.isEmpty) {
      _showErrorSnackbar('Veuillez remplir la taille et le prix');
      return;
    }

    final prix = double.tryParse(prixText);
    if (prix == null || prix <= 0) {
      _showErrorSnackbar('Veuillez entrer un prix valide (supérieur à 0)');
      return;
    }

    final nouvelleTaille = ProductSizePrice(size: taille, price: prix);

    if (_taillesPrix.any((tp) => tp.size == nouvelleTaille.size)) {
      _showWarningSnackbar('Cette taille existe déjà');
      return;
    }

    setState(() {
      _taillesPrix.add(nouvelleTaille);
      _tailleController.clear();
      _prixTailleController.clear();
    });
  }

  void _supprimerTaille(int index) {
    setState(() => _taillesPrix.removeAt(index));
  }

  void _modifierTaille(int index) {
    final taille = _taillesPrix[index];
    _tailleController.text = taille.size;
    _prixTailleController.text = taille.price.toString();
    _supprimerTaille(index);
  }

  Future<void> _pickImage() async {
    try {
      await _produitController.pickImage();
      if (_produitController.pickedImage.value != null) {
        setState(() {
          _selectedImage = _produitController.pickedImage.value;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Impossible de sélectionner l\'image: $e');
    }
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Image du Produit',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: _selectedImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_selectedImage!, fit: BoxFit.cover),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate,
                    size: 48,
                    color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  _isEditing && widget.produit!.imageUrl != null
                      ? 'Image actuelle conservée'
                      : 'Appuyez pour sélectionner une image',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGestionStockSection() {
    return CategoryFormCard(
      children: [
        const Text(
          'Gestion du Stock',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Produit stockable'),
          subtitle: const Text('Le produit a une quantité limitée en stock'),
          contentPadding: EdgeInsets.zero,
          value: _estStockable,
          onChanged: (value) {
            setState(() {
              _estStockable = value;
              if (!value) _quantiteStockController.clear();
            });
          },
        ),
        if (_estStockable) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantiteStockController,
            decoration: const InputDecoration(
              labelText: 'Quantité en stock *',
              border: OutlineInputBorder(),
              hintText: '0',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_estStockable && (value == null || value.isEmpty)) {
                return 'Veuillez entrer une quantité';
              }
              if (_estStockable) {
                final quantite = int.tryParse(value!);
                if (quantite == null || quantite < 0) {
                  return 'Veuillez entrer un nombre valide (≥ 0)';
                }
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTaillesSection() {
    return CategoryFormCard(
      children: [
        const Text(
          'Tailles et Prix',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ajoutez des tailles si votre produit existe en plusieurs formats',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _tailleController,
                decoration: const InputDecoration(
                  labelText: 'Taille (ex: Petit, Unité)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _prixTailleController,
                decoration: const InputDecoration(
                  labelText: 'Prix DT',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: IconButton(
                icon: const Icon(Icons.add_circle_outlined,
                    color: Colors.green, size: 32),
                onPressed: _ajouterTaille,
                tooltip: 'Ajouter la taille',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_taillesPrix.isNotEmpty) ...[
          const Text(
            'Tailles configurées:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _taillesPrix.asMap().entries.map((entry) {
              final index = entry.key;
              final taillePrix = entry.value;
              return Chip(
                label: Text('DT {taillePrix.size}: DT${taillePrix.price.toStringAsFixed(2)}'),
                deleteIcon: const Icon(Icons.edit, size: 18),
                onDeleted: () => _modifierTaille(index),
                backgroundColor: Colors.blue.shade50,
                deleteIconColor: Colors.blue.shade700,
                avatar: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _supprimerTaille(index),
                ),
              );
            }).toList(),
          ),
        ] else ...[
          _buildInfoCard(
            'Aucune taille configurée. Le produit aura un prix unique.',
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(String message) {
    return Card(
      color: Colors.orange.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return CategoryFormCard(
      children: [
        const Text(
          'Informations de Base',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Nom du produit
        TextFormField(
          controller: _nomController,
          decoration: const InputDecoration(
            labelText: 'Nom du produit *',
            border: OutlineInputBorder(),
            hintText: 'Ex: Café Latte, Croissant...',
            prefixIcon: Icon(Icons.fastfood_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez entrer un nom';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Catégorie
        DropdownButtonFormField<String>(
          value: _isSelectedCategoryValid() ? _selectedCategorieId : null,
          decoration: const InputDecoration(
            labelText: 'Catégorie *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category_outlined),
          ),
          items: _buildCategoryDropdownItems(),
          onChanged: _isLoading ? null : (value) {
            if (value == 'loading' || value == 'empty') return;
            setState(() => _selectedCategorieId = value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner une catégorie';
            }
            if (value == 'loading' || value == 'empty') {
              return 'Aucune catégorie disponible';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Description
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description du produit',
            border: OutlineInputBorder(),
            hintText: 'Décrivez votre produit...',
            prefixIcon: Icon(Icons.description_outlined),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 20),

        // Temps de préparation
        TextFormField(
          controller: _tempsPreparationController,
          decoration: const InputDecoration(
            labelText: 'Temps de préparation (minutes) *',
            border: OutlineInputBorder(),
            hintText: '0',
            prefixIcon: Icon(Icons.timer_outlined),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un temps de préparation';
            }
            final temps = int.tryParse(value);
            if (temps == null || temps < 0) {
              return 'Veuillez entrer un nombre valide (≥ 0)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_isSelectedCategoryValid()) {
      _showErrorSnackbar('La catégorie sélectionnée n\'est pas valide');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showErrorSnackbar('Veuillez corriger les erreurs dans le formulaire');
      return;
    }

    if (_selectedCategorieId == null) {
      _showErrorSnackbar('Veuillez sélectionner une catégorie');
      return;
    }

    if (_nomController.text.trim().isEmpty) {
      _showErrorSnackbar('Le nom du produit ne peut pas être vide');
      return;
    }

    if (_taillesPrix.isEmpty) {
      final confirmer = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Aucune taille définie'),
          content: const Text(
              'Ce produit n\'aura pas de tailles spécifiques. Souhaitez-vous continuer ?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Ajouter des tailles'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Continuer sans tailles'),
            ),
          ],
        ),
      );

      if (confirmer != true) return;
    }

    try {
      setState(() => _isLoading = true);

      final etablissementId = await _getEtablissementIdUtilisateur();
      if (etablissementId == null) {
        setState(() => _isLoading = false);
        return;
      }

      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _produitController.uploadProductImage(_selectedImage!);
        if (imageUrl == null) {
          setState(() => _isLoading = false);
          return;
        }
      } else if (_isEditing && widget.produit!.imageUrl != null) {
        imageUrl = widget.produit!.imageUrl;
      }

      final produit = ProduitModel(
        id: _isEditing ? widget.produit!.id : '',
        name: _nomController.text.trim(),
        imageUrl: imageUrl,
        categoryId: _selectedCategorieId!,
        sizesPrices: _taillesPrix,
        supplements: _supplements,
        description: _descriptionController.text.trim(),
        preparationTime: int.parse(_tempsPreparationController.text),
        etablissementId: etablissementId,
        isStockable: _estStockable,
        stockQuantity: _estStockable ? int.parse(_quantiteStockController.text) : 0,
        createdAt: _isEditing ? widget.produit!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = _isEditing
          ? await _produitController.updateProduct(produit)
          : await _produitController.addProduct(produit);

      if (success && mounted) {
        _showSuccessSnackbar(_isEditing ?
        'Produit modifié avec succès' : 'Produit ajouté avec succès');
        Get.back(result: true);
      }
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la sauvegarde: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _getEtablissementIdUtilisateur() async {
    try {
      final etablissement = await _etablissementController.getEtablissementUtilisateurConnecte();

      if (etablissement != null) {
        return etablissement.id;
      }

      _showErrorSnackbar('Aucun établissement trouvé. Veuillez d\'abord créer votre établissement.');
      return null;
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la récupération de l\'établissement: $e');
      return null;
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Erreur',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Succès',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showWarningSnackbar(String message) {
    Get.snackbar(
      'Attention',
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _isEditing ? 'Modifier le produit' : 'Ajouter un produit',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Get.back(),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _buildBody() {
    if (_isLoading && _categories.isEmpty) {
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
              _buildImageSection(),

              // Informations de base
              _buildBasicInfoSection(),
              const SizedBox(height: 24),

              // Gestion du stock
              _buildGestionStockSection(),
              const SizedBox(height: 24),

              // Tailles et prix
              _buildTaillesSection(),
              const SizedBox(height: 32),

              // Bouton Sauvegarder
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isLoading ? 'Enregistrement...' :
                    _isEditing ? 'Modifier le produit' : 'Ajouter le produit',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _nomController.dispose();
    _descriptionController.dispose();
    _tempsPreparationController.dispose();
    _quantiteStockController.dispose();
    _tailleController.dispose();
    _prixTailleController.dispose();
    _supplementController.dispose();
    super.dispose();
  }
}