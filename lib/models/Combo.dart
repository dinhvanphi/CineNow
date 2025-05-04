import 'package:flutter/material.dart';

class Combo {
  final int id;
  final String name;
  final String description;
  final double price;
  final String category;
  final bool isAvailable;
  
  // Biến đếm số lượng đã chọn
  int quantity = 0;

  Combo({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.isAvailable,
  });

  factory Combo.fromJson(Map<String, dynamic> json) {
    return Combo(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      category: json['category'],
      isAvailable: json['is_available'] ?? true,
    );
  }
  
  // Tính tổng tiền theo số lượng
  double get totalPrice => price * quantity;
  
  // Icon cho từng loại combo
  IconData get categoryIcon {
    switch (category) {
      case 'combo': return Icons.fastfood;
      case 'popcorn': return Icons.local_dining;
      case 'drink': return Icons.local_drink;
      case 'snack': return Icons.restaurant;
      default: return Icons.menu_book;
    }
  }
}