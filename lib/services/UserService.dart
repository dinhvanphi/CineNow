import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/User.dart';

class UserService {
  // URL của API server - thay đổi nếu cần
  // Sử dụng địa chỉ IP thực của máy tính thay vì localhost
  // Nếu bạn đang sử dụng iOS simulator, "localhost" sẽ không hoạt động
  final String _baseUrl = 'http://127.0.0.1:3000/api'; // Sử dụng localhost/127.0.0.1 cho iOS simulator

  // Đăng ký người dùng mới
  Future<User> register(String fullName, String phone, String email, String password) async {
    try {
      // Tạo body request với đúng tên trường theo cấu trúc bảng
      final Map<String, dynamic> requestBody = {
        'name': fullName,     // Bảng sử dụng 'name' thay vì 'fullName' hoặc 'full_name'
        'email': email,
        'phone': phone,
        'password': password,
        'role': 'customer'    // Mặc định là customer
      };
      
      // In thông tin chi tiết về request
      print('Đang gửi yêu cầu đăng ký đến API...');
      print('URL: $_baseUrl/register');
      print('Request body: ${jsonEncode(requestBody)}');
      
      // Tạo request với các header phù hợp
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15)); // Tăng timeout lên 15 giây
      
      print('Nhận phản hồi từ API: ${response.statusCode}');
      print('Body: ${response.body}');
      
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          // Tạo đối tượng User từ dữ liệu trả về
          final userData = responseData['user'];
          final user = User(
            id: userData['id'],
            fullName: userData['name'],   // Thay đổi này để phù hợp với tên trường trong DB
            email: userData['email'],
            phone: userData['phone'],
            password: password, // Lưu ý: API không trả về password
            createdAt: DateTime.parse(userData['created_at']),
          );
          
          // Lưu thông tin user vào SharedPreferences
          await _saveUserToPrefs(user);
          
          return user;
        } else {
          throw Exception(responseData['message'] ?? 'Đăng ký thất bại');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Đăng ký thất bại: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi đăng ký UserService: $e');
      rethrow;
    }
  }
  
  // Đăng nhập người dùng
  Future<User?> login(String emailOrPhone, String password) async {
    try {
      // Tạo body request
      final Map<String, dynamic> requestBody = {
        'emailOrPhone': emailOrPhone,
        'password': password,
      };
      
      print('Đang gửi yêu cầu đăng nhập đến API...');
      print('URL: $_baseUrl/login');
      print('Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15)); // Tăng timeout lên 15 giây
      
      print('Nhận phản hồi từ API: ${response.statusCode}');
      print('Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          // Tạo đối tượng User từ dữ liệu trả về
          final userData = responseData['user'];
          final user = User(
            id: userData['id'],
            fullName: userData['name'],   // Thay đổi này để phù hợp với tên trường trong DB
            email: userData['email'],
            phone: userData['phone'],
            password: password, // Lưu ý: API không trả về password
            createdAt: DateTime.parse(userData['created_at']),
          );
          
          // Lưu thông tin user vào SharedPreferences
          await _saveUserToPrefs(user);
          
          return user;
        } else {
          return null;
        }
      } else if (response.statusCode == 401) {
        return null; // Đăng nhập thất bại - thông tin không đúng
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Đăng nhập thất bại: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi đăng nhập UserService: $e');
      rethrow;
    }
  }
  
  // Đăng xuất
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
    } catch (e) {
      print('Lỗi đăng xuất: $e');
      rethrow;
    }
  }
  
  // Lưu thông tin user vào SharedPreferences
  Future<void> _saveUserToPrefs(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toMap());
      await prefs.setString('user', userJson);
    } catch (e) {
      print('Lỗi lưu user vào SharedPreferences: $e');
      rethrow;
    }
  }
  
  // Lấy thông tin user từ SharedPreferences
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromMap(userMap);
      }
      
      return null;
    } catch (e) {
      print('Lỗi lấy user từ SharedPreferences: $e');
      return null;
    }
  }
  
  // Kiểm tra xem người dùng đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
  
  // Thay đổi mật khẩu
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      // Lấy thông tin người dùng hiện tại
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }
      
      // Tạo body request
      final Map<String, dynamic> requestBody = {
        'userId': currentUser.id,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };
      
      print('Đang gửi yêu cầu đổi mật khẩu đến API...');
      print('URL: $_baseUrl/users/change-password');
      print('Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/users/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));
      
      print('Nhận phản hồi từ API: ${response.statusCode}');
      print('Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          // Cập nhật thông tin người dùng trong SharedPreferences
          final updatedUser = User(
            id: currentUser.id,
            fullName: currentUser.fullName,
            email: currentUser.email,
            phone: currentUser.phone,
            password: newPassword,
            createdAt: currentUser.createdAt,
          );
          
          await _saveUserToPrefs(updatedUser);
          return true;
        } else {
          throw Exception(responseData['message'] ?? 'Đổi mật khẩu thất bại');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Đổi mật khẩu thất bại: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi đổi mật khẩu: $e');
      rethrow;
    }
  }
} 