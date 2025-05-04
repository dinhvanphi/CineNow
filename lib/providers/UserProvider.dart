import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/User.dart';
import '../config/AppConfig.dart';

final baseUrl = AppConfig.apiBaseUrl;

class UserProvider extends ChangeNotifier {
  User? _user;
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  
  User? get user => _user;
  
  bool get isLoggedIn => _user != null;
  
  // Khởi tạo: Đọc từ bộ nhớ cục bộ
  Future<void> initialize() async {
    final userData = await _storage.read(key: 'user_data');
    if (userData != null) {
      try {
        _user = User.fromJson(jsonDecode(userData));
        notifyListeners();
      } catch (e) {
        print('Lỗi khi parse thông tin user từ storage: $e');
      }
    }
  }
  
  // Cập nhật user sau khi đăng nhập
  Future<void> setUser(User user) async {
    _user = user;
    await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
    notifyListeners();
  }
  
  // Xóa dữ liệu khi đăng xuất
  Future<void> logout() async {
    _user = null;
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user_data');
    notifyListeners();
  }
  
  // Lấy thông tin profile từ API
  Future<void> fetchUserProfile() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) {
        print('Không có token, không thể lấy thông tin người dùng');
        return;
      }
      
      // Giải mã token để lấy ID người dùng (nếu có trong token)
      final tokenData = _parseJwt(token);
      final userId = tokenData['id']; // Lấy ID từ token
      
      print('ID người dùng từ token: $userId');
      
      if (userId == null) {
        print('Không thể lấy ID người dùng từ token');
        return;
      }
      
      // Đảm bảo userId là số nguyên
      int? userIdInt;
      try {
        userIdInt = int.parse(userId.toString());
      } catch (e) {
        print('Lỗi chuyển đổi ID người dùng thành số nguyên: $e');
        return;
      }
      
      final url = '$baseUrl${AppConfig.userEndpoint}/$userIdInt';
      print('Đang gọi API: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );
      
      print('Phản hồi API profile: ${response.statusCode}');
      print('Dữ liệu: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          // In thông tin chi tiết hơn về dữ liệu người dùng
          final userData = data['user'];
          print('Dữ liệu người dùng chi tiết:');
          userData.forEach((key, value) {
            print(' - $key: $value');
          });
          
          _user = User.fromJson(userData);
          print('Đối tượng User sau khi parse: ID=${_user?.id}, Tên=${_user?.fullName}, Email=${_user?.email}');
          
          // Lưu thông tin mới nhất
          await _storage.write(key: 'user_data', value: jsonEncode(userData));
          
          notifyListeners();
        } else {
          print('API trả về thành công nhưng dữ liệu không đúng định dạng: ${response.body}');
        }
      } else {
        print('API trả về lỗi: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi lấy thông tin profile: $e');
    }
  }
  
  // Hàm phân tích JWT token để lấy thông tin người dùng
  Map<String, dynamic> _parseJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('Token không đúng định dạng JWT (không có 3 phần): $token');
        return {};
      }
      
      // Lấy phần payload của JWT token (phần thứ hai)
      final payload = parts[1];
      print('JWT payload (encoded): $payload');
      
      // Thêm padding nếu cần
      String normalized = payload;
      try {
        normalized = base64Url.normalize(payload);
      } catch (e) {
        print('Lỗi khi normalize payload: $e');
      }
      
      // Giải mã Base64
      String decoded;
      try {
        decoded = utf8.decode(base64Url.decode(normalized));
        print('JWT payload (decoded): $decoded');
      } catch (e) {
        print('Lỗi khi decode JWT payload: $e');
        return {};
      }
      
      // Parse JSON
      Map<String, dynamic> payloadMap;
      try {
        payloadMap = jsonDecode(decoded);
        print('JWT data: $payloadMap');
        
        // Kiểm tra xem có trường id trong payload không
        if (payloadMap.containsKey('id')) {
          print('Tìm thấy id trong token: ${payloadMap['id']} (kiểu: ${payloadMap['id'].runtimeType})');
        } else if (payloadMap.containsKey('user_id')) {
          print('Tìm thấy user_id trong token: ${payloadMap['user_id']}');
          // Nếu server sử dụng user_id thay vì id
          payloadMap['id'] = payloadMap['user_id'];
        } else if (payloadMap.containsKey('sub')) {
          print('Tìm thấy sub trong token: ${payloadMap['sub']}');
          // Nhiều JWT token sử dụng trường 'sub' cho ID người dùng
          payloadMap['id'] = payloadMap['sub'];
        } else {
          print('Không tìm thấy trường id trong token JWT. Các trường có sẵn: ${payloadMap.keys.toList()}');
        }
        
        return payloadMap;
      } catch (e) {
        print('Lỗi khi parse JSON từ JWT payload: $e');
        return {};
      }
    } catch (e) {
      print('Lỗi khi parse JWT token: $e');
      return {};
    }
  }
}