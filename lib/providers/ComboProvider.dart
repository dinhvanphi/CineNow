import 'package:flutter/foundation.dart';
import '../models/Combo.dart';
import '../services/ComboService.dart';

class ComboProvider with ChangeNotifier {
  final ComboService _comboService = ComboService();
  List<Combo> _combos = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Combo> get combos => _combos;
  List<Combo> get selectedCombos => _combos.where((combo) => combo.quantity > 0).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Tính tổng tiền combo
  double get totalAmount {
    return selectedCombos.fold(0, (sum, combo) => sum + combo.totalPrice);
  }

  // Lấy số lượng combo đã chọn
  int get totalQuantity {
    return selectedCombos.fold(0, (sum, combo) => sum + combo.quantity);
  }

  // Lấy combo theo danh mục
  List<Combo> getCombosInCategory(String category) {
    return _combos.where((combo) => combo.category == category).toList();
  }

  // Lấy danh sách tất cả combo từ API
  Future<void> loadCombos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _combos = await _comboService.getAllCombos();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Tăng số lượng combo
  void incrementCombo(Combo combo) {
    int index = _combos.indexWhere((c) => c.id == combo.id);
    if (index != -1) {
      _combos[index].quantity++;
      notifyListeners();
    }
  }

  // Giảm số lượng combo
  void decrementCombo(Combo combo) {
    int index = _combos.indexWhere((c) => c.id == combo.id);
    if (index != -1 && _combos[index].quantity > 0) {
      _combos[index].quantity--;
      notifyListeners();
    }
  }

  // Reset danh sách combo đã chọn
  void reset() {
    for (var combo in _combos) {
      combo.quantity = 0;
    }
    notifyListeners();
  }
  
  // Lưu danh sách combo đã chọn
  Future<Map<String, dynamic>> saveSelectedCombos(int bookingId) async {
    if (selectedCombos.isEmpty) {
      return {
        'success': true,
        'message': 'Không có combo nào được chọn',
        'combo_total': 0,
      };
    }
    
    try {
      return await _comboService.saveBookingCombos(bookingId, selectedCombos);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}