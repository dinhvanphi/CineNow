import 'package:postgres/postgres.dart';
import '../models/User.dart';

/*
 * LƯU Ý QUAN TRỌNG:
 * Class này đã bị vô hiệu hóa và không nên sử dụng nữa.
 * Ứng dụng bây giờ sẽ sử dụng UserService để kết nối đến API server thay vì 
 * kết nối trực tiếp đến PostgreSQL.
 * Xem file UserService.dart để biết cách triển khai mới.
 */

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  
  late PostgreSQLConnection _connection;
  bool _isConnected = false;

  // Singleton pattern
  DatabaseHelper._internal();
  
  Future<void> initConnection() async {
    throw Exception('📢 DatabaseHelper đã bị vô hiệu hóa. Vui lòng sử dụng UserService để kết nối đến API server.');
  }
  
  Future<void> closeConnection() async {
    throw Exception('📢 DatabaseHelper đã bị vô hiệu hóa. Vui lòng sử dụng UserService để kết nối đến API server.');
  }

  Future<bool> isUserExists(String email, String phone) async {
    throw Exception('📢 DatabaseHelper đã bị vô hiệu hóa. Vui lòng sử dụng UserService để kết nối đến API server.');
  }
  
  Future<User> registerUser(User user) async {
    throw Exception('📢 DatabaseHelper đã bị vô hiệu hóa. Vui lòng sử dụng UserService để kết nối đến API server.');
  }
  
  Future<User?> loginUser(String emailOrPhone, String password) async {
    throw Exception('📢 DatabaseHelper đã bị vô hiệu hóa. Vui lòng sử dụng UserService để kết nối đến API server.');
  }
} 