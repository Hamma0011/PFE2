import 'dart:convert';

import 'package:flutter/foundation.dart';

class ProduitModel {
  final String id;
  final String name;
  final String? imageUrl;
  final String categoryId;
  final List<ProductSizePrice> sizesPrices;
  final List<String> supplements;
  final String? description;
  final int preparationTime;
  final String etablissementId;
  final bool isStockable;
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProduitModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.categoryId,
    required this.sizesPrices,
    required this.supplements,
    this.description,
    required this.preparationTime,
    required this.etablissementId,
    required this.isStockable,
    required this.stockQuantity,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Instance vide
  static ProduitModel empty() {
    return ProduitModel(
      id: '',
      name: '',
      categoryId: '',
      sizesPrices: [],
      supplements: [],
      preparationTime: 0,
      etablissementId: '',
      isStockable: false,
      stockQuantity: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Conversion depuis Map (depuis la base de données)
  factory ProduitModel.fromMap(Map<String, dynamic> map) {
    // Gestion des tailles_prix JSONB
    List<ProductSizePrice> sizesPrices = [];
    if (map['tailles_prix'] != null) {
      if (map['tailles_prix'] is String) {
        // Si c'est une chaîne JSON, on la parse
        try {
          final List<dynamic> jsonList = json.decode(map['tailles_prix']);
          sizesPrices = jsonList
              .map((jsonItem) =>
                  ProductSizePrice.fromMap(Map<String, dynamic>.from(jsonItem)))
              .toList();
        } catch (e) {
          print('Erreur parsing tailles_prix: $e');
        }
      } else if (map['tailles_prix'] is List) {
        // Si c'est déjà une liste
        sizesPrices = (map['tailles_prix'] as List)
            .map((item) =>
                ProductSizePrice.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    }

    // Gestion des supplements (tableau PostgreSQL)
    List<String> supplements = [];
    if (map['supplements'] != null) {
      if (map['supplements'] is List) {
        supplements = List<String>.from(map['supplements']);
      } else if (map['supplements'] is String) {
        // Pour les cas où c'est stocké comme chaîne
        supplements = map['supplements'].split(',');
      }
    }

    // Gestion des dates
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is DateTime) return date;
      if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return ProduitModel(
      id: map['id']?.toString() ?? '',
      name: map['nom']?.toString() ?? '',
      imageUrl: map['url_image']?.toString(),
      categoryId: map['categorie_id']?.toString() ?? '',
      sizesPrices: sizesPrices,
      supplements: supplements,
      description: map['description']?.toString(),
      preparationTime: (map['temps_preparation'] ?? 0) as int,
      etablissementId: map['etablissement_id']?.toString() ?? '',
      isStockable: (map['est_stockable'] ?? false) as bool,
      stockQuantity: (map['quantite_stock'] ?? 0) as int,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  // Conversion vers Map (pour la base de données)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': name,
      'url_image': imageUrl,
      'categorie_id': categoryId,
      'tailles_prix': json
          .encode(sizesPrices.map((sizePrice) => sizePrice.toMap()).toList()),
      'supplements': supplements,
      'description': description,
      'temps_preparation': preparationTime,
      'etablissement_id': etablissementId,
      'est_stockable': isStockable,
      'quantite_stock': stockQuantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Conversion depuis JSON
  factory ProduitModel.fromJson(String source) =>
      ProduitModel.fromMap(json.decode(source));

  /// Conversion vers JSON pour Supabase
  Map<String, dynamic> toJson({bool includeId = false}) {
    final data = <String, dynamic>{
      'nom': name.trim(),
      'url_image': imageUrl,
      'categorie_id': categoryId,
      'tailles_prix': json
          .encode(sizesPrices.map((sizePrice) => sizePrice.toMap()).toList()),
      'supplements': supplements,
      'description': description,
      'temps_preparation': preparationTime,
      'etablissement_id': etablissementId,
      'est_stockable': isStockable,
      'quantite_stock': stockQuantity,
    };

    if (includeId && id.isNotEmpty) {
      data['id'] = id;
    }

    return data;
  }

  /// Copie avec modifications
  ProduitModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? categoryId,
    List<ProductSizePrice>? sizesPrices,
    List<String>? supplements,
    String? description,
    int? preparationTime,
    String? etablissementId,
    bool? isStockable,
    int? stockQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProduitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      sizesPrices: sizesPrices ?? this.sizesPrices,
      supplements: supplements ?? this.supplements,
      description: description ?? this.description,
      preparationTime: preparationTime ?? this.preparationTime,
      etablissementId: etablissementId ?? this.etablissementId,
      isStockable: isStockable ?? this.isStockable,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Méthodes utilitaires
  double get minPrice {
    if (sizesPrices.isEmpty) return 0.0;
    return sizesPrices
        .map((sizePrice) => sizePrice.price)
        .reduce((a, b) => a < b ? a : b);
  }

  double get maxPrice {
    if (sizesPrices.isEmpty) return 0.0;
    return sizesPrices
        .map((sizePrice) => sizePrice.price)
        .reduce((a, b) => a > b ? a : b);
  }

  bool get isAvailable {
    if (!isStockable) return true;
    return stockQuantity > 0;
  }

  List<String> get availableSizes {
    return sizesPrices.map((sizePrice) => sizePrice.size).toList();
  }

  // Égalité
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProduitModel &&
        other.id == id &&
        other.name == name &&
        other.imageUrl == imageUrl &&
        other.categoryId == categoryId &&
        listEquals(other.sizesPrices, sizesPrices) &&
        listEquals(other.supplements, supplements) &&
        other.description == description &&
        other.preparationTime == preparationTime &&
        other.etablissementId == etablissementId &&
        other.isStockable == isStockable &&
        other.stockQuantity == stockQuantity;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      imageUrl,
      categoryId,
      Object.hashAll(sizesPrices),
      Object.hashAll(supplements),
      description,
      preparationTime,
      etablissementId,
      isStockable,
      stockQuantity,
    );
  }

  @override
  String toString() {
    return 'ProduitModel(id: $id, name: $name, categoryId: $categoryId, etablissementId: $etablissementId, isAvailable: $isAvailable)';
  }
}

class ProductSizePrice {
  final String size;
  final double price;

  ProductSizePrice({
    required this.size,
    required this.price,
  });

  factory ProductSizePrice.fromMap(Map<String, dynamic> map) {
    return ProductSizePrice(
      size: map['taille']?.toString() ?? map['size']?.toString() ?? '',
      price: (map['prix'] ?? map['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taille': size,
      'prix': price,
    };
  }

  // Conversion depuis JSON
  factory ProductSizePrice.fromJson(String source) =>
      ProductSizePrice.fromMap(json.decode(source));

  // Conversion vers JSON
  String toJson() => json.encode(toMap());

  ProductSizePrice copyWith({
    String? size,
    double? price,
  }) {
    return ProductSizePrice(
      size: size ?? this.size,
      price: price ?? this.price,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductSizePrice &&
        other.size == size &&
        other.price == price;
  }

  @override
  int get hashCode => Object.hash(size, price);

  @override
  String toString() {
    return 'ProductSizePrice(size: $size, price: $price)';
  }
}
