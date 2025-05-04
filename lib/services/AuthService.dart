import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/AppConfig.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/User.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Bổ sung biến storage nếu chưa có
final storage = FlutterSecureStorage();
final baseUrl = AppConfig.apiBaseUrl;

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId: Platform.isIOS 
        ? '1017985540889-h1irr37rpiudup78cntmoqadrcggpsh6.apps.googleusercontent.com'
        : null, // Chỉ cần thiết cho iOS
  );

  // Đăng nhập bằng Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // In thông tin debug
      print('Google Sign-In thành công: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        print('Không nhận được idToken từ Google');
        return null;
      }

      print('Gửi token đến server: ${idToken.substring(0, 10)}...');

      // Gửi token đến server
      final response = await http.post(
        Uri.parse('$baseUrl${AppConfig.googleAuthEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': idToken}),
      );

      print('Phản hồi từ server: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Kiểm tra cấu trúc dữ liệu trả về
        print('Cấu trúc dữ liệu từ server: ${data.keys.toList()}');
        
        if (data['token'] == null) {
          print('Lỗi: Server không trả về token');
          return null;
        }
        
        // Lưu token
        final token = data['token'];
        print('Token nhận được từ server: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
        await storage.write(key: 'token', value: token);
        
        // QUAN TRỌNG: Lưu thông tin user vào bộ nhớ cục bộ
        final userData = data['user'];
        print('Thông tin user nhận được: $userData');
        
        if (userData == null) {
          print('Lỗi: Server không trả về thông tin người dùng');
          return null;
        }
        
        // Kiểm tra xem userData có id không
        if (userData['id'] == null) {
          print('Lỗi: Thông tin người dùng không có id');
          print('Các trường trong dữ liệu người dùng: ${userData.keys.toList()}');
        } else {
          print('ID người dùng từ server: ${userData['id']} (kiểu: ${userData['id'].runtimeType})');
        }
        
        await storage.write(key: 'user_data', value: jsonEncode(userData));
        
        // Khởi tạo đối tượng User từ JSON
        final user = User.fromJson(userData);
        print('Đối tượng User đã tạo: ${user.id}, ${user.fullName}, ${user.email}');
        
        return user;
      } else {
        print('Đăng nhập Google thất bại: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Lỗi trong quá trình đăng nhập Google: $e');
      return null;
    }
  }

  // Đăng nhập bằng Facebook
  // Future<Map<String, dynamic>?> signInWithFacebook() async {
  //   try {
  //     print("===== BẮT ĐẦU ĐĂNG NHẬP FACEBOOK =====");
      
  //     // Bắt đầu quá trình đăng nhập Facebook
  //     print("1. Bắt đầu đăng nhập Facebook");
  //     final LoginResult result = await FacebookAuth.instance.login(
  //       permissions: ['email', 'public_profile'],
  //     );
      
  //     print("2. Kết quả login: ${result.status}");
      
  //     if (result.status != LoginStatus.success) {
  //       print("Người dùng đã hủy đăng nhập hoặc lỗi: ${result.message}");
  //       return null;
  //     }
      
  //     // Lấy access token
  //     print("3. Lấy access token");
  //     final accessToken = result.accessToken?.tokenString;
      
  //     if (accessToken == null) {
  //       print("Không thể lấy access token từ Facebook");
  //       throw Exception('Không thể lấy access token từ Facebook');
  //     }
      
  //     print("4. AccessToken: ${accessToken.substring(0, min(10, accessToken.length))}...");
      
  //     // Lấy thông tin người dùng
  //     print("5. Lấy thông tin người dùng");
  //     final userData = await FacebookAuth.instance.getUserData(fields: "name,email,picture");
  //     print("6. Thông tin người dùng: ${userData['name']}, ${userData['email']}");
      
  //     // Gửi token đến server để xác thực
  //     print("7. Gửi request đến: ${AppConfig.apiBaseUrl}${AppConfig.facebookAuthEndpoint}");
  //     try {
  //       final response = await http.post(
  //         Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.facebookAuthEndpoint}'),
  //         headers: {'Content-Type': 'application/json'},
  //         body: jsonEncode({
  //           'token': accessToken,
  //         }),
  //       );
        
  //       print("8. Nhận response: ${response.statusCode}");
  //       print("9. Response body: ${response.body}");
        
  //       if (response.statusCode == 200) {
  //         final data = jsonDecode(response.body);
  //         if (data['success']) {
  //           // Lưu token xác thực
  //           final prefs = await SharedPreferences.getInstance();
  //           await prefs.setString('auth_token', data['token']);
  //           return data['user'];
  //         }
  //       }
        
  //       throw Exception('Xác thực với server thất bại: ${response.body}');
  //     } catch (networkError) {
  //       print("Lỗi network: $networkError");
  //       rethrow;
  //     }
  //   } catch (e, stackTrace) {
  //     print("===== LỖI ĐĂNG NHẬP FACEBOOK =====");
  //     print("Lỗi: $e");
  //     print("Stack trace: $stackTrace");
  //     await FacebookAuth.instance.logOut();
  //     return null;
  //   }
  // }

  // Kiểm tra trạng thái đăng nhập
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token') && prefs.getString('auth_token')!.isNotEmpty;
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      // await FacebookAuth.instance.logOut();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      print('Lỗi đăng xuất: $e');
      rethrow;
    }
  }
} 