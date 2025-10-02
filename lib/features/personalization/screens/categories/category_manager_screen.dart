import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caferesto/features/shop/models/category_model.dart';
import 'package:caferesto/features/shop/controllers/category_controller.dart';

import 'add_category_screen.dart';
import 'edit_category_screen.dart';

class CategoryManagementPage extends StatelessWidget {
  final CategoryController categoryController = Get.put(CategoryController());

  CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des catégories"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Ajouter une catégorie",
            onPressed: () {
              // Naviguer vers la page d'ajout
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

        return ListView.builder(
          itemCount: categoryController.allCategories.length,
          itemBuilder: (context, index) {
            final CategoryModel category =
            categoryController.allCategories[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(category.image),
                  onBackgroundImageError: (_, __) =>
                  const Icon(Icons.category),
                ),
                title: Text(category.name),
                subtitle: category.parentId != null
                    ? Text("Sous-catégorie de : ${categoryController.getParentName(category.parentId!)}")
                    : const Text("Catégorie principale"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton Editer
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Get.to(() => EditCategoryScreen(category: category));
                      },
                    ),
                    // Bouton Supprimer
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        categoryController.removeCategory(category.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  /// Popup pour modifier une catégorie
  void _showEditDialog(BuildContext context, CategoryModel category) {
    final TextEditingController nameController =
    TextEditingController(text: category.name);

    Get.defaultDialog(
      title: "Modifier Catégorie",
      content: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Nom de catégorie"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              final updatedCategory = CategoryModel(
                id: category.id,
                name: nameController.text.trim(),
                image: category.image,
                parentId: category.parentId,
                isFeatured: category.isFeatured,
              );

              categoryController.editCategory(updatedCategory);
              Get.back(); // Fermer la popup
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }
}
