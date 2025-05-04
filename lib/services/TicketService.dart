import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Ticket.dart';

class TicketService {
  static const String _ticketsKey = 'user_tickets';
  
  // Lưu vé mới sau khi thanh toán thành công
  Future<bool> saveTicket(Ticket ticket) async {
    try {
      print('===== Tiến hành lưu vé =====');
      print('Thông tin vé: ${ticket.movieTitle}, ${ticket.seats.join(", ")}, ${ticket.price}');
      
      final prefs = await SharedPreferences.getInstance();
      print('Khởi tạo SharedPreferences thành công');
      
      // Phương pháp lưu trực tiếp với key riêng cho từng vé
      final ticketJson = jsonEncode(ticket.toJson());
      
      // Tạo key duy nhất cho vé này
      final ticketKey = 'ticket_${ticket.id}_${Random().nextInt(10000)}';
      print('Lưu vé với key: $ticketKey');
      
      // Lưu vé mới với key riêng
      final saveResult = await prefs.setString(ticketKey, ticketJson);
      print('Kết quả lưu vé riêng: $saveResult');
      
      // Lưu danh sách key của các vé
      List<String> ticketKeys = prefs.getStringList(_ticketsKey) ?? [];
      ticketKeys.add(ticketKey);
      
      // Lưu cập nhật danh sách key
      final keysResult = await prefs.setStringList(_ticketsKey, ticketKeys);
      print('Lưu danh sách ${ticketKeys.length} key vé: $keysResult');
      
      // Lưu trực tiếp vé gần nhất để hiển thị nhanh
      await prefs.setString('latest_ticket', ticketJson);
      print('Lưu vé gần nhất thành công');
      
      print('===== Hoàn tất lưu vé =====');
      return keysResult;
    } catch (e) {
      print('Lỗi khi lưu vé: $e');
      print(e.toString());
      
      try {
        // Cố gắng lưu dữ liệu vé bằng cách đơn giản nhất
        final prefs = await SharedPreferences.getInstance();
        final simpleTicketJson = jsonEncode(ticket.toJson());
        await prefs.setString('emergency_ticket', simpleTicketJson);
        print('Lưu vé khẩn cấp thành công');
      } catch (backupError) {
        print('Cả lưu vé khẩn cấp cũng thất bại: $backupError');
      }
      
      return false;
    }
  }
  
  // Lấy danh sách tất cả vé
  Future<List<Ticket>> getTickets() async {
    try {
      print('***** Bắt đầu lấy danh sách vé *****');
      final prefs = await SharedPreferences.getInstance();
      
      // Lấy danh sách key vé từ SharedPreferences
      final List<String>? ticketKeys = prefs.getStringList(_ticketsKey);
      
      if (ticketKeys == null || ticketKeys.isEmpty) {
        print('Không có keys vé nào, thử kiểm tra vé khẩn cấp');
        
        // Kiểm tra vé khẩn cấp
        final emergencyTicket = prefs.getString('emergency_ticket');
        if (emergencyTicket != null) {
          print('Tìm thấy một vé khẩn cấp');
          try {
            final ticket = Ticket.fromJson(jsonDecode(emergencyTicket));
            return [ticket];
          } catch (e) {
            print('Lỗi khi giải mã vé khẩn cấp: $e');
          }
        }
        
        // Kiểm tra vé gần nhất
        final latestTicket = prefs.getString('latest_ticket');
        if (latestTicket != null) {
          print('Tìm thấy vé gần nhất');
          try {
            final ticket = Ticket.fromJson(jsonDecode(latestTicket));
            return [ticket];
          } catch (e) {
            print('Lỗi khi giải mã vé gần nhất: $e');
          }
        }
        
        // Không tìm thấy vé nào
        print('Không tìm thấy vé nào trong SharedPreferences');
        return [];
      }
      
      print('Tìm thấy ${ticketKeys.length} key vé trong SharedPreferences');
      
      // Lấy dữ liệu từ từng key
      List<Ticket> tickets = [];
      for (final key in ticketKeys) {
        final ticketJson = prefs.getString(key);
        if (ticketJson != null) {
          try {
            final ticket = Ticket.fromJson(jsonDecode(ticketJson));
            tickets.add(ticket);
          } catch (e) {
            print('Lỗi khi giải mã vé $key: $e');
          }
        }
      }
      
      print('Đã tải thành công ${tickets.length} vé');
      print('***** Hoàn tất lấy danh sách vé *****');
      return tickets;
    } catch (e) {
      print('Lỗi khi lấy danh sách vé: $e');
      print(e.toString());
      
      // Thử lấy vé gần nhất trong trường hợp có lỗi
      try {
        final prefs = await SharedPreferences.getInstance();
        final latestTicket = prefs.getString('latest_ticket');
        if (latestTicket != null) {
          print('Có lỗi nhưng tìm thấy vé gần nhất');
          final ticket = Ticket.fromJson(jsonDecode(latestTicket));
          return [ticket];
        }
      } catch (backupError) {
        print('Lỗi khi lấy vé gần nhất: $backupError');
      }
      
      return [];
    }
  }
  
  // Đánh dấu vé đã được sử dụng
  Future<bool> markTicketAsUsed(String ticketId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Lấy danh sách vé hiện tại
      final List<Ticket> tickets = await getTickets();
      
      // Tìm và cập nhật vé
      for (int i = 0; i < tickets.length; i++) {
        if (tickets[i].id == ticketId) {
          // Tạo vé mới với trạng thái đã sử dụng
          final updatedTicket = Ticket(
            id: tickets[i].id,
            movieTitle: tickets[i].movieTitle,
            duration: tickets[i].duration,
            genres: tickets[i].genres,
            showtime: tickets[i].showtime,
            showDate: tickets[i].showDate,
            theater: tickets[i].theater,
            section: tickets[i].section,
            seats: tickets[i].seats,
            price: tickets[i].price,
            imageUrl: tickets[i].imageUrl,
            purchaseDate: tickets[i].purchaseDate,
            isUsed: true,
          );
          
          // Thay thế vé cũ bằng vé đã cập nhật
          tickets[i] = updatedTicket;
          
          // Lưu lại danh sách
          final List<String> ticketsJson = tickets.map((t) => jsonEncode(t.toJson())).toList();
          await prefs.setStringList(_ticketsKey, ticketsJson);
          
          return true;
        }
      }
      
      return false; // Không tìm thấy vé
    } catch (e) {
      print('Lỗi khi đánh dấu vé đã sử dụng: $e');
      return false;
    }
  }
  
  // Tạo vé mới từ thông tin thanh toán
  Ticket createTicketFromPayment({
    required String orderId,
    required String movieTitle,
    required String theaterName,
    required String roomName,
    required List<String> seats,
    required double amount,
    required String imageUrl,
    String duration = "2 hours 30 minutes",
    String genres = "Action, adventure, sci-fi",
  }) {
    final now = DateTime.now();
    final showDate = "${now.day}.${now.month}.${now.year}";
    final showtime = "${now.hour}:${now.minute}";
    
    return Ticket(
      id: orderId,
      movieTitle: movieTitle,
      duration: duration,
      genres: genres,
      showtime: showtime,
      showDate: showDate,
      theater: theaterName,
      section: roomName,
      seats: seats,
      price: amount,
      imageUrl: imageUrl,
      purchaseDate: now,
    );
  }
}
