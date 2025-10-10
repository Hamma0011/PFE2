import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/produit_helper.dart';
import '../../controllers/product/produit_controller.dart';
import '../../models/produit_model.dart';
import 'add_produit_screen.dart';

class ListProduitScreen extends StatefulWidget {
  const ListProduitScreen({super.key});

  @override
  State<ListProduitScreen> createState() => _ListProduitScreenState();
}

class _ListProduitScreenState extends State<ListProduitScreen> {
  late ProduitController controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    if (!Get.isRegistered<ProduitController>()) {
      Get.put(ProduitController());
    }
    controller = Get.find<ProduitController>();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    await controller.fetchProducts();
  }

  void _navigateToAddProduit() {
    Get.to(() => AddProduitScreen())?.then((_) {
      _loadProducts();
    });
  }

  void _navigateToEditProduit(ProduitModel produit) {
    Get.to(() => AddProduitScreen(produit: produit))?.then((_) {
      _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Barre de recherche TOUJOURS visible
          _buildSearchBar(),

          // Liste des produits
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        "Gestion des produits",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (controller.isLoading.value && controller.allProducts.isEmpty) {
        return _buildLoadingState();
      }

      final produitsFiltres = controller.filteredProducts;


      if (produitsFiltres.isEmpty) {
        return _buildEmptyState();
      }

      return Column(
        children: [
         // _buildSearchBar(),
          
         // _buildFiltres(),
          Expanded(
            child: Center(
              child: RefreshIndicator(
                onRefresh: _loadProducts,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: produitsFiltres.length,
                  itemBuilder: (context, index) {
                    final produit = produitsFiltres[index];
                    return _buildProduitCard(produit, index);
                  },
                ),
              ),
            ),
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
            "Chargement des produits...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: controller.filterProducts,
        decoration: InputDecoration(
          labelText: 'Rechercher un produit',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFiltres() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildChipFiltre('Tous', 0),
            _buildChipFiltre('Stockables', 1),
            _buildChipFiltre('Non stockables', 2),
            _buildChipFiltre('Rupture', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildChipFiltre(String label, int value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
        selected: false,
        onSelected: (selected) {
          // TODO: Implémenter les filtres
        },
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.blue.shade100,
        checkmarkColor: Colors.blue.shade600,
        labelStyle: TextStyle(
          color: false ? Colors.blue.shade600 : Colors.grey[700],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    bool isSearching = controller.filteredProducts.isEmpty && controller.allProducts.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fastfood_outlined,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    isSearching
                        ? "Aucun produit ne correspond à votre recherche"
                        : "Aucun produit trouvé",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                if (!isSearching) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Commencez par ajouter votre premier produit",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddProduit,
                    icon: const Icon(Icons.add),
                    label: const Text("Ajouter un produit"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildProduitCard(ProduitModel produit, int index) {
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: _buildProduitImage(produit),
        title: Text(
          produit.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: _buildProduitSubtitle(produit),
        trailing: _buildProduitActions(produit),
        onTap: () => _showProduitOptions(produit),
      ),
    );
  }

  Widget _buildProduitImage(ProduitModel produit) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: produit.imageUrl != null && produit.imageUrl!.isNotEmpty
            ? Image.network(
          produit.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultProduitIcon();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildImageLoading();
          },
        )
            : _buildDefaultProduitIcon(),
      ),
    );
  }

  Widget _buildDefaultProduitIcon() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.fastfood,
        color: Colors.grey,
        size: 28,
      ),
    );
  }

  Widget _buildImageLoading() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildProduitSubtitle(ProduitModel produit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ProduitHelper.getAffichagePrix(produit),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Temps: ${produit.preparationTime} min',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        if (produit.description != null && produit.description!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            produit.description!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (produit.sizesPrices.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            ProduitHelper.getAffichageTailles(produit),
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
            ),
          ),
        ],
        const SizedBox(height: 4),
        _buildIndicateurStock(produit),
      ],
    );
  }

  Widget _buildIndicateurStock(ProduitModel produit) {
    Color backgroundColor;
    Color textColor;
    String text;

    if (!produit.isStockable) {
      backgroundColor = Colors.grey[100]!;
      textColor = Colors.grey[600]!;
      text = 'Non stockable';
    } else if (produit.stockQuantity > 0) {
      backgroundColor = Colors.green[50]!;
      textColor = Colors.green[700]!;
      text = 'Stock: ${produit.stockQuantity}';
    } else {
      backgroundColor = Colors.red[50]!;
      textColor = Colors.red[700]!;
      text = 'Rupture de stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildProduitActions(ProduitModel produit) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (produit.isStockable)
          IconButton(
            icon: Icon(Icons.inventory_2, size: 20, color: Colors.orange[600]),
            onPressed: () => _showModifierStockDialog(produit),
            tooltip: 'Modifier le stock',
          ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
          onPressed: () => _navigateToEditProduit(produit),
          tooltip: 'Modifier',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _navigateToAddProduit,
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.add, size: 28),
    );
  }

  void _showProduitOptions(ProduitModel produit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _buildBottomSheetContent(produit);
      },
    );
  }

  Widget _buildBottomSheetContent(ProduitModel produit) {
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
          _buildBottomSheetHeader(produit),
          const SizedBox(height: 16),

          // Boutons d'action
          _buildActionButtons(produit),
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

  Widget _buildBottomSheetHeader(ProduitModel produit) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildProduitImage(produit),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ProduitHelper.getAffichagePrix(produit),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Temps: ${produit.preparationTime} min',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                _buildIndicateurStock(produit),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ProduitModel produit) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Bouton Stock
          if (produit.isStockable)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showModifierStockDialog(produit);
                  },
                  icon: const Icon(Icons.inventory_2_outlined, size: 20),
                  label: const Text("Stock"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade50,
                    foregroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          // Bouton Éditer
          Expanded(
            child: Container(
              margin: produit.isStockable
                  ? const EdgeInsets.symmetric(horizontal: 4)
                  : const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToEditProduit(produit);
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
                onPressed: () => _showDeleteConfirmationDialog(produit),
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

  void _showDeleteConfirmationDialog(ProduitModel produit) {
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
                "Êtes-vous sûr de vouloir supprimer le produit \"${produit.name}\" ?",
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
                      controller.deleteProduct(produit.id);
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

  void _showModifierStockDialog(ProduitModel produit) {
    final quantiteController = TextEditingController(text: produit.stockQuantity.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Modifier le stock"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Produit: ${produit.name}"),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantiteController,
                decoration: const InputDecoration(
                  labelText: 'Nouvelle quantité en stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                // TODO: Implémenter la mise à jour du stock
                Navigator.pop(context);
                Get.snackbar(
                  'Info',
                  'Fonctionnalité à implémenter',
                  backgroundColor: Colors.orange,
                );
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }
}
