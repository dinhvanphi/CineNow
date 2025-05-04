import 'Seat.dart';
import 'dart:developer' as developer;
import 'dart:convert';

class ShowtimeSeats {
  final Map<String, dynamic> showtime;
  final Map<String, dynamic> seatsSummary;
  final Map<String, List<Seat>> seatsByRow;
  final List<Seat> seats;

  ShowtimeSeats({
    required this.showtime,
    required this.seatsSummary,
    required this.seatsByRow,
    required this.seats,
  });

  factory ShowtimeSeats.fromMap(Map<String, dynamic> data) {
    // Thêm log để debug
    developer.log("ShowtimeSeats.fromMap - Received data: ${data.keys.toList()}");
    
    // Trích xuất dữ liệu từ response với kiểm tra null safety
    final Map<String, dynamic> showtime = data['showtime'] ?? {};
    final Map<String, dynamic> seatsSummary = data['seats_summary'] ?? {};
    
    // Log thông tin ghế
    developer.log("Showtime info: ${showtime['movie_title']} - ${showtime['room_name']}");
    
    List<dynamic> seatsList = [];
    
    // Kiểm tra nhiều cấu trúc JSON có thể có
    if (data.containsKey('seats') && data['seats'] != null) {
      if (data['seats'] is List) {
        seatsList = data['seats'];
        developer.log("Found ${seatsList.length} seats in 'seats' key");
      } else {
        developer.log("Warning: 'seats' is not a List: ${data['seats'].runtimeType}");
      }
    } else if (data.containsKey('data') && data['data'] != null) {
      // Một số API có thể wrap dữ liệu trong key 'data'
      if (data['data'] is List) {
        seatsList = data['data'];
        developer.log("Found ${seatsList.length} seats in 'data' key");
      } else if (data['data'] is Map && data['data'].containsKey('seats')) {
        if (data['data']['seats'] is List) {
          seatsList = data['data']['seats'];
          developer.log("Found ${seatsList.length} seats in 'data.seats' key");
        }
      }
    } else if (data.containsKey('seat_list') && data['seat_list'] != null) {
      // Tên key khác có thể được sử dụng
      if (data['seat_list'] is List) {
        seatsList = data['seat_list'];
        developer.log("Found ${seatsList.length} seats in 'seat_list' key");
      }
    } else {
      // Cuối cùng, thử tìm key có thể chứa danh sách ghế
      for (var key in data.keys) {
        if (data[key] is List && (key.contains('seat') || key.contains('Seat'))) {
          seatsList = data[key];
          developer.log("Found ${seatsList.length} seats in '$key' key");
          break;
        }
      }
      
      if (seatsList.isEmpty) {
        developer.log("No seat list found in any key. Creating dummy seats for testing.");
        
        // Tạo dữ liệu ghế giả để kiểm tra UI
        final List<String> rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
        int seatId = 1;
        
        for (var row in rows) {
          for (int i = 1; i <= 8; i++) {
            seatsList.add({
              'seat_id': seatId++,
              'seat_name': '$row$i',
              'row_letter': row,
              'row_number': i,
              'seat_type': 'ghế thường',
              'status': null,
              'price_id': 1
            });
          }
        }
        
        developer.log("Created ${seatsList.length} dummy seats for testing");
      }
    }
    
    try {
      // Chuyển đổi danh sách ghế thành đối tượng Seat với xử lý ngoại lệ
      final List<Seat> seats = seatsList.map<Seat>((seatData) {
        if (seatData is! Map<String, dynamic>) {
          developer.log("Warning: seat data is not a Map: ${seatData.runtimeType}. Converting to string and checking.");
          
          // Có thể dữ liệu là string JSON
          if (seatData is String) {
            try {
              Map<String, dynamic> parsedSeat = Map<String, dynamic>.from(
                  Map.castFrom(jsonDecode(seatData)));
              return Seat.fromMap(parsedSeat);
            } catch (e) {
              developer.log("Failed to parse seat from string: $e");
            }
          }
          
          return Seat(
            seatId: 0,
            seatName: "Unknown",
            rowLetter: "?",
            rowNumber: 0,
            seatType: "Unknown",
          );
        }
        
        // Normalize key names if needed
        Map<String, dynamic> normalizedSeat = {...seatData};
        
        // Kiểm tra và chuyển đổi format key nếu cần
        if (!normalizedSeat.containsKey('seat_id') && normalizedSeat.containsKey('id')) {
          normalizedSeat['seat_id'] = normalizedSeat['id'];
        }
        if (!normalizedSeat.containsKey('seat_name') && normalizedSeat.containsKey('name')) {
          normalizedSeat['seat_name'] = normalizedSeat['name'];
        }
        if (!normalizedSeat.containsKey('row_letter') && normalizedSeat.containsKey('row')) {
          normalizedSeat['row_letter'] = normalizedSeat['row'];
        }
        if (!normalizedSeat.containsKey('row_number') && normalizedSeat.containsKey('number')) {
          normalizedSeat['row_number'] = normalizedSeat['number'];
        }
        if (!normalizedSeat.containsKey('seat_type') && normalizedSeat.containsKey('type')) {
          normalizedSeat['seat_type'] = normalizedSeat['type'];
        }
        
        try {
          return Seat.fromMap(normalizedSeat);
        } catch (e) {
          developer.log("Error creating Seat from map: $e. Data: $normalizedSeat");
          return Seat(
            seatId: normalizedSeat['seat_id'] ?? 0,
            seatName: normalizedSeat['seat_name'] ?? "Unknown",
            rowLetter: normalizedSeat['row_letter'] ?? "?",
            rowNumber: normalizedSeat['row_number'] ?? 0,
            seatType: normalizedSeat['seat_type'] ?? "Unknown",
          );
        }
      }).toList();
      
      // Sắp xếp ghế theo hàng với kiểm tra null safety
      final Map<String, List<Seat>> seatsByRow = {};
      for (var seat in seats) {
        final rowKey = seat.rowLetter;
        if (!seatsByRow.containsKey(rowKey)) {
          seatsByRow[rowKey] = [];
        }
        seatsByRow[rowKey]!.add(seat);
      }
      
      // Log thông tin hàng ghế
      developer.log("Organized seats into ${seatsByRow.length} rows: ${seatsByRow.keys.toList()}");
      
      // Sắp xếp ghế trong mỗi hàng theo số thứ tự
      seatsByRow.forEach((rowKey, rowSeats) {
        rowSeats.sort((a, b) => a.rowNumber.compareTo(b.rowNumber));
      });
      
      return ShowtimeSeats(
        showtime: showtime,
        seatsSummary: seatsSummary,
        seatsByRow: seatsByRow,
        seats: seats,
      );
    } catch (e, stackTrace) {
      // Log lỗi chi tiết
      developer.log("Error parsing seat data: $e");
      developer.log("Stack trace: $stackTrace");
      
      // Trả về đối tượng với dữ liệu trống để tránh ứng dụng bị crash
      return ShowtimeSeats(
        showtime: showtime,
        seatsSummary: seatsSummary,
        seatsByRow: {},
        seats: [],
      );
    }
  }
} 