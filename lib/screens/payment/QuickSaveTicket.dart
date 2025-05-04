import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../models/Ticket.dart';
import '../../HomePage.dart';
import '../../providers/SeatProvider.dart';
import '../../providers/MovieProvider.dart';
import '../../providers/RoomProvider.dart';
import '../../providers/ComboProvider.dart';

class QuickSaveTicket extends StatefulWidget {
  final Map<String, String> paymentParams;
  
  const QuickSaveTicket({
    Key? key, 
    required this.paymentParams,
  }) : super(key: key);
  
  @override
  _QuickSaveTicketState createState() => _QuickSaveTicketState();
}

class _QuickSaveTicketState extends State<QuickSaveTicket> {
  bool _isSaving = true;
  bool _isSuccess = false;
  String _message = "Đang lưu vé...";
  
  @override
  void initState() {
    super.initState();
    _processTicket();
  }
  
  Future<void> _processTicket() async {
    try {
      // Hiển thị thông tin đã nhận
      print("QUICK SAVE: Xử lý thanh toán với params:");
      widget.paymentParams.forEach((key, value) {
        print("  $key: $value");
      });
      
      await Future.delayed(Duration(seconds: 1));
      
      // Kiểm tra mã giao dịch
      final responseCode = widget.paymentParams['vnp_ResponseCode'];
      if (responseCode != '00') {
        setState(() {
          _isSaving = false;
          _isSuccess = false;
          _message = "Thanh toán không thành công (mã: $responseCode)";
        });
        return;
      }
      
      // Lấy thông tin từ tham số thanh toán
      final orderId = widget.paymentParams['vnp_TxnRef'] ?? 'TXN${DateTime.now().millisecondsSinceEpoch}';
      final amount = double.parse(widget.paymentParams['vnp_Amount'] ?? '0') / 100;
      final payDate = widget.paymentParams['vnp_PayDate'] ?? DateTime.now().toString();
      
      print("QUICK SAVE: Lưu vé với mã $orderId, số tiền $amount");
      
      // Lấy thông tin từ Provider
      final seatProvider = Provider.of<SeatProvider>(context, listen: false);
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      final comboProvider = Provider.of<ComboProvider>(context, listen: false);
      
      // Lấy tên phim
      final savedMovieInfo = await _getSavedMovieInfo(movieProvider.movieId);
      
      // Lấy danh sách ghế
      List<String> selectedSeats = [];
      if (seatProvider.selectedSeats.isNotEmpty) {
        selectedSeats = seatProvider.selectedSeats.map((seat) => seat.seatName).toList();
      } else {
        // Phòng hợp nếu không có ghế được chọn, lấy từ params
        String seatInfo = widget.paymentParams['vnp_OrderInfo'] ?? '';
        if (seatInfo.contains('ghế') || seatInfo.contains('seat')) {
          final seatMatch = RegExp(r'[A-Z]\d+').allMatches(seatInfo);
          if (seatMatch.isNotEmpty) {
            selectedSeats = seatMatch.map((m) => m.group(0)!).toList();
          } else {
            selectedSeats = ["A8"]; // Giá trị mặc định nếu không tìm thấy
          }
        } else {
          selectedSeats = ["A8"]; // Giá trị mặc định
        }
      }
      
      // Tạo vé với thông tin chính xác
      final ticket = Ticket(
        id: orderId,
        movieTitle: savedMovieInfo['title'] ?? "Nàng Bạch Tuyết",
        duration: savedMovieInfo['duration'] ?? "2 hours",
        genres: savedMovieInfo['genres'] ?? "Action, Adventure",
        showtime: "14:15",
        showDate: _formatDate(DateTime.now()),
        theater: "CineNow",
        section: roomProvider.roomName ?? "Phòng thường 1",
        seats: selectedSeats,
        price: amount,
        imageUrl: savedMovieInfo['image'] ?? "https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
        purchaseDate: DateTime.now(),
      );
      
      // Lưu vé
      final prefs = await SharedPreferences.getInstance();
      
      // Lấy danh sách vé hiện có
      List<String> ticketJsonList = prefs.getStringList('tickets') ?? [];
      
      // Kiểm tra xem vé đã tồn tại chưa
      bool ticketExists = false;
      for (var ticketJson in ticketJsonList) {
        final existingTicket = Ticket.fromJson(jsonDecode(ticketJson));
        if (existingTicket.id == ticket.id) {
          ticketExists = true;
          break;
        }
      }
      
      // Nếu vé chưa tồn tại, thêm vào danh sách
      if (!ticketExists) {
        ticketJsonList.add(jsonEncode(ticket.toJson()));
        await prefs.setStringList('tickets', ticketJsonList);
        
        // Lưu thông tin combos nếu có
        if (comboProvider.selectedCombos.isNotEmpty) {
          try {
            // Chuyển đổi Combo objects sang dạng Map đơn giản
            final comboList = comboProvider.selectedCombos.map((combo) => {
              'id': combo.id,
              'name': combo.name, 
              'price': combo.price,
              'quantity': combo.quantity,
            }).toList();
            
            await prefs.setString('combos_$orderId', jsonEncode(comboList));
          } catch (e) {
            print('Lỗi khi lưu thông tin combo: $e');
            // Lỗi khi lưu combo không ảnh hưởng đến việc lưu vé
          }
        }
        
        print("QUICK SAVE: Đã lưu vé thành công");
      } else {
        print("QUICK SAVE: Vé đã tồn tại, không lưu lại");
      }
      
      setState(() {
        _isSaving = false;
        _isSuccess = true;
        _message = "Vé đã được lưu thành công!";  
      });
      
    } catch (e) {
      print("QUICK SAVE LỖI: $e");
      setState(() {
        _isSaving = false;
        _isSuccess = false;
        _message = "Có lỗi khi lưu vé: $e";
      });
    }
  }
  
  // Lấy thông tin phim từ storage nếu có
  Future<Map<String, dynamic>> _getSavedMovieInfo(int? movieId) async {
    try {
      if (movieId != null) {
        final prefs = await SharedPreferences.getInstance();
        final movieInfoJson = prefs.getString('movie_$movieId');
        if (movieInfoJson != null) {
          return jsonDecode(movieInfoJson);
        }
      }
    } catch (e) {
      print("Lỗi khi lấy thông tin phim: $e");
    }
    
    // Trả về thông tin mặc định nếu không tìm thấy
    return {
      'title': 'Nàng Bạch Tuyết',
      'duration': '2 hours',
      'genres': 'Fantasy, Adventure',
      'image': 'https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg'
    };
  }
  
  // Định dạng ngày tháng
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Kết quả thanh toán'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header container với nền đen
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(
                    'Kết quả thanh toán',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSaving) ...[
                    CircularProgressIndicator(color: Colors.amber),
                    SizedBox(height: 24),
                    Text(
                      'Đang lưu vé của bạn...',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (_isSuccess) ...[
                    Icon(
                      Icons.check_circle,
                      color: Colors.amber,
                      size: 72,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Thanh toán thành công!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Vé đã được lưu thành công!',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 40),
                    // Card thông tin thanh toán
                    Card(
                      elevation: 4,
                      color: Colors.grey[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.amber.withOpacity(0.3), width: 1),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ListTile(
                              title: const Text('Mã đơn hàng'),
                              subtitle: Text(widget.paymentParams['vnp_TxnRef'] ?? 'Không xác định'),
                              leading: const Icon(Icons.confirmation_number, color: Colors.blue),
                            ),
                            if (widget.paymentParams.containsKey('vnp_Amount'))
                              Column(
                                children: [
                                  const Divider(),
                                  ListTile(
                                    title: const Text('Số tiền thanh toán'),
                                    subtitle: Text(
                                      '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(double.parse(widget.paymentParams['vnp_Amount'] ?? '0') / 100)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                    leading: Icon(Icons.monetization_on, color: Colors.amber.shade600),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    Container(
                      width: 200, // Kích thước cố định để tránh lỗi hiển thị
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => HomePage()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          backgroundColor: Colors.amber.shade600,
                          elevation: 3,
                        ),
                        child: Text(
                          'Xem vé của tôi', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 72,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Có lỗi xảy ra',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _message,
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 40),
                    Container(
                      width: 200, // Kích thước cố định để tránh lỗi hiển thị
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => HomePage()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          backgroundColor: Colors.grey.shade700,
                          elevation: 3,
                        ),
                        child: Text(
                          'Quay về trang chủ', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
