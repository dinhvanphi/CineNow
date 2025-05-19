import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/Seat.dart';
import '../models/SeatPrice.dart';
import '../models/ShowtimeSeats.dart';
import 'dart:developer' as developer;

class SeatService {
  final String baseUrl = ApiConstants.baseUrl;

  // Lấy thông tin ghế theo suất chiếu
  Future<ShowtimeSeats> getSeatsByShowtime(int showtimeId) async {
    try {
      developer.log("Fetching seats for showtime ID: $showtimeId");
      
      final response = await http.get(
        Uri.parse('https://f32f-171-251-30-227.ngrok-free.app/api/seats/showtime/$showtimeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        developer.log("API response status: ${response.statusCode}");
        
        // Log response body để debug
        final responseBody = response.body;
        
        // In toàn bộ response từ API
        print("===== API RESPONSE START =====");
        print(responseBody);
        print("===== API RESPONSE END =====");
        
        try {
          final Map<String, dynamic> data = json.decode(responseBody);
          developer.log("JSON parsed successfully. Keys: ${data.keys.toList()}");
          
          // Kiểm tra seats key
          if(data.containsKey('seats')) {
            developer.log("'seats' key found. Type: ${data['seats'].runtimeType}");
            if(data['seats'] is List) {
              developer.log("'seats' is a List with ${data['seats'].length} items");
            }
          } else {
            developer.log("'seats' key NOT found in response");
            
            // Check for alternative keys
            List<String> possibleSeatKeys = ['seats', 'seat_list', 'seatsList', 'data', 'rows'];
            for (var key in data.keys) {
              developer.log("Examining key: $key, Type: ${data[key].runtimeType}");
              if (data[key] is List && possibleSeatKeys.contains(key)) {
                developer.log("Potential seat list found in key: $key with ${data[key].length} items");
              } else if (data[key] is Map) {
                developer.log("Map found in key: $key with ${data[key].keys.toList()} sub-keys");
              }
            }
          }
          
          return ShowtimeSeats.fromMap(data);
        } catch (jsonError) {
          developer.log("JSON parsing error: $jsonError");
          throw Exception('Lỗi phân tích dữ liệu JSON: $jsonError');
        }
      } else {
        developer.log("API error: ${response.statusCode}, Body: ${response.body}");
        throw Exception('Không thể lấy thông tin ghế. Mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      developer.log("Exception in getSeatsByShowtime: $e");
      throw Exception('Lỗi khi lấy thông tin ghế: $e');
    }
  }

  // Lấy thông tin giá ghế theo price_id
  Future<SeatPrice> getSeatPrice(int priceId) async {
    try {
      final response = await http.get(
        Uri.parse('https://f32f-171-251-30-227.ngrok-free.app/api/seat-prices/$priceId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return SeatPrice.fromMap(data);
      } else {
        throw Exception('Không thể lấy thông tin giá ghế. Mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy thông tin giá ghế: $e');
    }
  }

  // Lấy tất cả thông tin giá ghế
  Future<List<SeatPrice>> getAllSeatPrices() async {
    try {
      final response = await http.get(
        Uri.parse('https://f32f-171-251-30-227.ngrok-free.app/api/seat-prices'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => SeatPrice.fromMap(item)).toList();
      } else {
        // Trả về danh sách trống thay vì ném lỗi
        print('API giá ghế không khả dụng (${response.statusCode}). Sử dụng giá mặc định.');
        return [];
      }
    } catch (e) {
      // Trả về danh sách trống thay vì ném lỗi
      print('Không thể kết nối đến API giá ghế: $e. Sử dụng giá mặc định.');
      return [];
    }
  }

  // Lấy giá ghế dựa trên seat_id
  Future<Map<String, dynamic>> getSeatPriceById(int seatId) async {
    try {
      developer.log("Fetching price for seat ID: $seatId");
      final String apiUrl = 'https://f32f-171-251-30-227.ngrok-free.app/api/seats/$seatId/price';
      developer.log("API URL: $apiUrl");
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      developer.log("API response status: ${response.statusCode}");
      developer.log("API response body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          developer.log("Parsed price data: $data");
          return data;
        } catch (jsonError) {
          developer.log("JSON parsing error: $jsonError");
          throw Exception('Lỗi khi phân tích dữ liệu giá ghế: $jsonError');
        }
      } else {
        developer.log("Price API error: Status ${response.statusCode}, Body: ${response.body}");
        // Trả về giá mặc định nếu không lấy được từ API
        return {
          'seat_id': seatId,
          'price': 100000,
          'is_default_price': true
        };
      }
    } catch (e) {
      developer.log("Exception in getSeatPriceById: $e");
      // Trả về giá mặc định nếu có ngoại lệ
      return {
        'seat_id': seatId,
        'price': 100000,
        'is_default_price': true
      };
    }
  }

  // Khóa ghế đã chọn tạm thời
  Future<void> lockSeats(int showtimeId, List<int> seatIds, String sessionId) async {
    try {
      developer.log("Locking seats for showtime ID: $showtimeId");
      developer.log("Session ID: $sessionId");
      developer.log("Seat IDs: $seatIds");
      
      // Đổi đường dẫn API để khớp với server
      final String apiUrl = 'https://f32f-171-251-30-227.ngrok-free.app/api/seats/showtime/$showtimeId/lock';
      developer.log("API URL: $apiUrl");
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'seatIds': seatIds,
          'sessionId': sessionId,
        }),
      );

      developer.log("Lock API response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        developer.log("Lock API response body: ${response.body}");
        developer.log("Seats locked successfully");
      } else {
        developer.log("Failed to lock seats: ${response.body}");
        throw Exception('Không thể khóa ghế. Mã lỗi: ${response.statusCode}. Nội dung: ${response.body}');
      }
    } catch (e) {
      developer.log("Exception in lockSeats: $e");
      throw Exception('Lỗi khi khóa ghế: $e');
    }
  }

  // Giải phóng ghế đã khóa
  Future<void> unlockSeats(int showtimeId, List<int> seatIds, String sessionId) async {
    try {
      developer.log("Unlocking seats for showtime ID: $showtimeId");
      developer.log("Session ID: $sessionId");
      developer.log("Seat IDs: $seatIds");
      
      // Đổi đường dẫn API để khớp với server
      final String apiUrl = 'https://f32f-171-251-30-227.ngrok-free.app/api/seats/showtime/$showtimeId/unlock';
      developer.log("API URL: $apiUrl");
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'seatIds': seatIds,
          'sessionId': sessionId,
        }),
      );

      developer.log("Unlock API response status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        developer.log("Unlock API response body: ${response.body}");
        developer.log("Seats unlocked successfully");
      } else {
        developer.log("Failed to unlock seats: ${response.body}");
        throw Exception('Không thể giải phóng ghế. Mã lỗi: ${response.statusCode}. Nội dung: ${response.body}');
      }
    } catch (e) {
      developer.log("Exception in unlockSeats: $e");
      throw Exception('Lỗi khi giải phóng ghế: $e');
    }
  }

  // Xác nhận đặt ghế
  Future<Map<String, dynamic>> confirmSeatBooking(
    int showtimeId,
    List<int> seatIds,
    String sessionId,
    int userId,
    double totalAmount,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'showtime_id': showtimeId,
          'seat_ids': seatIds,
          'session_id': sessionId,
          'user_id': userId,
          'total_amount': totalAmount,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Không thể xác nhận đặt ghế. Mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi khi xác nhận đặt ghế: $e');
    }
  }
}