import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/Combo.dart';
import 'dart:developer' as developer;

class ComboService {
  final String baseUrl = ApiConstants.baseUrl;

  // Lấy danh sách tất cả combo
  Future<List<Combo>> getAllCombos() async {
    try {
      developer.log("Fetching all combos from API");
      
      final response = await http.get(
        Uri.parse('https://d623-116-105-212-66.ngrok-free.app/api/combos'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        developer.log("API response status: ${response.statusCode}");
        
        final responseData = json.decode(response.body);
        final List<dynamic> combosJson = responseData['combos'];
        
        developer.log("Received ${combosJson.length} combos");
        
        return combosJson.map((json) => Combo.fromJson(json)).toList();
      } else {
        developer.log("Failed to fetch combos: ${response.body}");
        throw Exception('Không thể lấy danh sách combo. Mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      developer.log("Exception in getAllCombos: $e");
      throw Exception('Lỗi khi lấy danh sách combo: $e');
    }
  }

  // Lấy danh sách combo theo danh mục
  Future<List<Combo>> getCombosByCategory(String category) async {
    try {
      developer.log("Fetching combos for category: $category");
      
      final response = await http.get(
        Uri.parse('https://d623-116-105-212-66.ngrok-free.app/api/combos/$category'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        developer.log("API response status: ${response.statusCode}");
        
        final responseData = json.decode(response.body);
        final List<dynamic> combosJson = responseData['combos'];
        
        developer.log("Received ${combosJson.length} $category");
        
        return combosJson.map((json) => Combo.fromJson(json)).toList();
      } else {
        developer.log("Failed to fetch $category: ${response.body}");
        throw Exception('Không thể lấy danh sách $category. Mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      developer.log("Exception in getCombosByCategory: $e");
      throw Exception('Lỗi khi lấy danh sách $category: $e');
    }
  }
  
  // Lưu danh sách combo đã chọn vào booking
  Future<Map<String, dynamic>> saveBookingCombos(int bookingId, List<Combo> selectedCombos) async {
    try {
      developer.log("Saving combos for booking ID: $bookingId");
      
      // Chuyển đổi từ danh sách Combo sang format cần thiết cho API
      final combosToSave = selectedCombos.map((combo) => {
        'combo_id': combo.id,
        'quantity': combo.quantity,
      }).toList();
      
      developer.log("Combos to save: ${json.encode(combosToSave)}");
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/booking-combos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'booking_id': bookingId,
          'combos': combosToSave,
        }),
      );

      if (response.statusCode == 200) {
        developer.log("API response status: ${response.statusCode}");
        developer.log("Response body: ${response.body}");
        
        return json.decode(response.body);
      } else {
        developer.log("Failed to save booking combos: ${response.body}");
        throw Exception('Không thể lưu combo. Mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      developer.log("Exception in saveBookingCombos: $e");
      throw Exception('Lỗi khi lưu combo: $e');
    }
  }
}