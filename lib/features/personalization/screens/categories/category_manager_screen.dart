/*import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caferesto/features/shop/models/category_model.dart';
import 'package:caferesto/features/shop/controllers/category_controller.dart';

import 'add_category_screen.dart';
import 'edit_category_screen.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage>
    with SingleTickerProviderStateMixin {
  final CategoryController categoryController = Get.put(CategoryController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des catégories"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Catégories"),
            Tab(text: "Sous-catégories"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Ajouter une catégorie",
            onPressed: () {
              Get.to(() => AddCategoryScreen());
            },
          ),
        ],
      ),
      body: Obx(() {
        if (categoryController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (categoryController.allCategories.isEmpty) {
          return const Center(child: Text("Aucune catégorie trouvée"));
        }

        return TabBarView(
          controller: _tabController,
          children: [
            // Onglet Catégories principales
            _buildCategoryList(
              categoryController.allCategories
                  .where((c) => c.parentId == null)
                  .toList(),
            ),

            // Onglet Sous-catégories
            _buildCategoryList(
              categoryController.allCategories
                  .where((c) => c.parentId != null)
                  .toList(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final CategoryModel category = categories[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(category.image),
              onBackgroundImageError: (_, __) =>
              const Icon(Icons.category),
            ),
            title: Text(category.name),
            subtitle: category.parentId != null
                ? Text(
                "Sous-catégorie de : ${categoryController.getParentName(category.parentId!)}")
                : const Text("Catégorie principale"),
            onTap: () {
              _showCategoryOptions(context, category);
            },
          ),
        );
      },
    );
  }

  void _showCategoryOptions(BuildContext context, CategoryModel category) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec les informations de la catégorie
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(category.image),
                    onBackgroundImageError: (_, __) =>
                    const Icon(Icons.category),
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        category.parentId != null
                            ? Text(
                          "Sous-catégorie de : ${categoryController.getParentName(category.parentId!)}",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        )
                            : Text(
                          "Catégorie principale",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // Boutons Éditer et Supprimer
              Row(
                children: [
                  // Bouton Éditer
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Get.to(() => EditCategoryScreen(category: category));
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text("Éditer"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bouton Supprimer
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: ElevatedButton.icon(
                        onPressed: () => _showDeleteConfirmationDialog(context, category),
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: const Text("Supprimer"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Méthode pour afficher la dialogue de confirmation de suppression
  void _showDeleteConfirmationDialog(BuildContext context, CategoryModel category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer la suppression"),
          content: const Text("Êtes-vous sûr de vouloir supprimer cette catégorie ? Cette action est irréversible."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fermer la dialogue
                Navigator.pop(context); // Fermer le bottom sheet
                categoryController.removeCategory(category.id);
                // Afficher un message de succès
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${category.name} supprimée avec succès"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                "Supprimer",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}*/
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caferesto/features/shop/models/category_model.dart';
import 'package:caferesto/features/shop/controllers/category_controller.dart';
//import 'package:caferesto/utils/constants/image_strings.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage>
    with SingleTickerProviderStateMixin {
  final CategoryController categoryController = Get.find<CategoryController>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    categoryController.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        "Gestion des catégories",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      bottom: _buildTabBar(),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.blue.shade600,
      unselectedLabelColor: Colors.grey[600],
      indicatorColor: Colors.blue.shade600,
      indicatorWeight: 3,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
      tabs: const [
        Tab(
          icon: Icon(Icons.category, size: 20),
          text: "Catégories",
        ),
        Tab(
          icon: Icon(Icons.subdirectory_arrow_right, size: 20),
          text: "Sous-catégories",
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (categoryController.isLoading.value) {
        return _buildLoadingState();
      }

      if (categoryController.allCategories.isEmpty) {
        return _buildEmptyState();
      }

      return TabBarView(
        controller: _tabController,
        children: [
          // Onglet Catégories principales
          _buildCategoryList(
            categoryController.allCategories
                .where((c) => c.parentId == null)
                .toList(),
            isSubcategory: false,
          ),

          // Onglet Sous-catégories
          _buildCategoryList(
            categoryController.allCategories
                .where((c) => c.parentId != null)
                .toList(),
            isSubcategory: true,
          ),
        ],
      );
    });
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            "Chargement des catégories...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            "Aucune catégorie trouvée",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Commencez par ajouter votre première catégorie",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.to(() => AddCategoryScreen()),
            icon: const Icon(Icons.add),
            label: const Text("Ajouter une catégorie"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories, {required bool isSubcategory}) {
    if (categories.isEmpty) {
      return _buildEmptyTabState(isSubcategory);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await categoryController.fetchCategories();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(category, index);
        },
      ),
    );
  }

  Widget _buildEmptyTabState(bool isSubcategory) {
    return RefreshIndicator(
      onRefresh: () async {
        await categoryController.fetchCategories();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSubcategory ? Icons.subdirectory_arrow_right : Icons.category,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  isSubcategory ? "Aucune sous-catégorie" : "Aucune catégorie principale",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isSubcategory
                      ? "Les sous-catégories apparaîtront ici"
                      : "Les catégories principales apparaîtront ici",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildCategoryImage(category),
        title: Text(
          category.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: _buildCategorySubtitle(category),
        trailing: _buildFeaturedBadge(category),
        onTap: () => _showCategoryOptions(category),
      ),
    );
  }

  Widget _buildCategoryImage(CategoryModel category) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          category.image,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.category,
                color: Colors.grey[400],
                size: 24,
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategorySubtitle(CategoryModel category) {
    if (category.parentId != null) {
      final parentName = categoryController.getParentName(category.parentId!);
      return Text(
        "Sous-catégorie • $parentName",
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      );
    }

    final subcategoriesCount = categoryController.allCategories
        .where((c) => c.parentId == category.id)
        .length;

    return Text(
      subcategoriesCount == 0
          ? "Catégorie principale"
          : "Catégorie principale • $subcategoriesCount sous-catégorie${subcategoriesCount > 1 ? 's' : ''}",
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildFeaturedBadge(CategoryModel category) {
    if (!category.isFeatured) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.amber.shade600,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            "Vedette",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => Get.to(() => AddCategoryScreen()),
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.add, size: 28),
    );
  }

  void _showCategoryOptions(CategoryModel category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildBottomSheetContent(category);
      },
    );
  }

  Widget _buildBottomSheetContent(CategoryModel category) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête
          _buildBottomSheetHeader(category),
          const SizedBox(height: 16),

          // Boutons d'action
          _buildActionButtons(category),
          const SizedBox(height: 8),

          // Bouton annuler
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Annuler"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetHeader(CategoryModel category) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildCategoryImage(category),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                _buildCategorySubtitle(category),
                if (category.isFeatured) ...[
                  const SizedBox(height: 8),
                  _buildFeaturedBadge(category),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CategoryModel category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Bouton Éditer
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Get.to(() => EditCategoryScreen(category: category));
                },
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text("Éditer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          // Bouton Supprimer
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteConfirmationDialog(category),
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text("Supprimer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(CategoryModel category) {
    Navigator.pop(context); // Fermer le bottom sheet

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 12),
              Text("Confirmer la suppression"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Êtes-vous sûr de vouloir supprimer la catégorie \"${category.name}\" ?",
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                "Cette action est irréversible.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Annuler"),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteCategory(category);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Supprimer"),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(CategoryModel category) {
    categoryController.removeCategory(category.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}