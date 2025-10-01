import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../shop/controllers/category_controller.dart';

class AddCategoryScreen extends StatelessWidget {
  AddCategoryScreen({super.key});

  final CategoryController _categoryController = Get.find<CategoryController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        title: const Text('Ajouter catégorie'),
        showBackArrow: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _categoryController.formKey,
          child: Column(
            children: [
              // Section Image
              Obx(() {
                final imageFile = _categoryController.pickedImage.value;
                return GestureDetector(
                  onTap: _categoryController.pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: imageFile != null
                        ? Image.file(
                      imageFile,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      TImages.coffee,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _categoryController.pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Choisir une image'),
              ),

              const SizedBox(height: 16),

              // Champ nom de la catégorie
              TextFormField(
                controller: _categoryController.nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la catégorie',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppSizes.spaceBtwInputFields),

              // Dropdown catégorie parente
              Obx(() {
                return DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(
                    labelText: "Catégorie parente (optionnel)",
                    border: OutlineInputBorder(),
                  ),
                  value: _categoryController.selectedParentId.value,
                  items: _categoryController.allCategories.map((cat) {
                    return DropdownMenuItem<String?>(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    _categoryController.selectedParentId.value = val;
                  },
                );
              }),


              SizedBox(height: AppSizes.spaceBtwInputFields),

              // Checkbox catégorie en vedette
              Obx(() => CheckboxListTile(
                title: const Text('Catégorie en vedette'),
                value: _categoryController.isFeatured.value,
                onChanged: (val) {
                  _categoryController.isFeatured.value = val ?? false;
                },
              )),

              const SizedBox(height: 20),

              // Bouton Ajouter
              Obx(() => _categoryController.isLoading.value
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _categoryController.addCategory();
                  },
                  child: const Text('Ajouter'),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
