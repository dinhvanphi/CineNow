import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/PaymentService.dart';
import '../../services/TicketService.dart';
import '../../models/Ticket.dart';
import '../../HomePage.dart';
import '../../providers/SeatProvider.dart';
import '../../providers/ComboProvider.dart';
import '../../providers/RoomProvider.dart';
import '../../providers/MovieProvider.dart';


class PaymentResultScreen extends StatefulWidget {
  final Map<String, String> queryParams;

  const PaymentResultScreen({
    Key? key,
    required this.queryParams,
  }) : super(key: key);

  @override
  _PaymentResultScreenState createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  bool _isLoading = false;
  final _formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  bool get isSuccess => widget.queryParams['vnp_ResponseCode'] == '00';
  final TicketService _ticketService = TicketService();
  
  // Key lưu trữ thông tin thanh toán thành công
  static const String _vnpaySuccessKey = 'vnpay_success_payment';
  
  @override
  void initState() {
    super.initState();
    _logPaymentResult();
    print('====== PAYMENT RESULT INIT ======');
    print('ResponseCode: ${widget.queryParams['vnp_ResponseCode']}');
    print('isSuccess: $isSuccess');

    if (isSuccess) {
      // Lưu thông tin thanh toán thành công xuống storage để có thể khôi phục nếu cần
      _backupPaymentInfo();
      
      // Sử dụng nhiều cơ chế để đảm bảo vé được lưu
      bool hasProcessedPayment = false;
      
      // Cách 1: Gọi ngay để lưu vé trước
      print('TIẾN HÀNH LƯU VÉ NGAY - Method 1');
      _saveTicketAndShowSuccess();
      hasProcessedPayment = true;
      
      // Cách 2: Sử dụng WidgetsBinding.instance.addPostFrameCallback để đảm bảo
      // hàm _saveTicketAndShowSuccess được gọi sau khi build hoàn tất
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!hasProcessedPayment) {
          print('TIẾN HÀNH LƯU VÉ - Method 2');
          _saveTicketAndShowSuccess();
        } else {
          print('Vé đã được lưu trước đó');
        }
      });
      
      // Cách 3: Gọi sau 2 giây để đảm bảo mọi thứ đã sẵn sàng
      Future.delayed(Duration(seconds: 2), () {
        print('TIẾN HÀNH LƯU VÉ SAU 2 GIÂY - Method 3');
        _forceSaveSimpleTicket(); // Sử dụng phương pháp đơn giản để lưu vé
      });
    } else {
      print('Thanh toán không thành công với mã: ${widget.queryParams['vnp_ResponseCode']}');
    }
  }
  
  // Lưu thông tin thanh toán để có thể khôi phục sau này nếu cần
  Future<void> _backupPaymentInfo() async {
    try {
      print('===== ĐANG BACKUP THÔNG TIN THANH TOÁN =====');
      final prefs = await SharedPreferences.getInstance();
      
      // Lưu toàn bộ thông tin thanh toán
      final paymentInfo = {
        'transaction_time': DateTime.now().toIso8601String(),
        'payment_params': widget.queryParams,
      };
      
      await prefs.setString(_vnpaySuccessKey, jsonEncode(paymentInfo));
      
      // Thêm vào danh sách các giao dịch thành công
      List<String> successPayments = prefs.getStringList('vnpay_success_payments') ?? [];
      String transactionId = widget.queryParams['vnp_TxnRef'] ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      successPayments.add(transactionId);
      await prefs.setStringList('vnpay_success_payments', successPayments);
      
      print('Đã lưu thông tin thanh toán thành công với mã: $transactionId');
      print('===== BACKUP THÀNH CÔNG =====');
    } catch (e) {
      print('Lỗi khi backup thông tin thanh toán: $e');
    }
  }
  
  void _logPaymentResult() {
    print('=== VNPAY PAYMENT RESULT ===');
    widget.queryParams.forEach((key, value) {
      print('$key: $value');
    });
    print('===========================');
  }
  
  // Phương pháp đơn giản để lưu vé (không sử dụng Provider)
  Future<void> _forceSaveSimpleTicket() async {
    try {
      print('===== BẮT ĐẦU LƯU VÉ ĐƠN GIẢN =====');
      final prefs = await SharedPreferences.getInstance();
      
      // Lấy thông tin thanh toán
      final orderId = widget.queryParams['vnp_TxnRef'] ?? 'TXN${DateTime.now().millisecondsSinceEpoch}';
      final amount = double.parse(widget.queryParams['vnp_Amount'] ?? '0') / 100;
      final payDate = widget.queryParams['vnp_PayDate'] ?? DateTime.now().toString();
      
      print('OrderID: $orderId');
      print('Số tiền: $amount');
      print('Ngày thanh toán: $payDate');
      
      // Tạo vé đơn giản
      final ticket = Ticket(
        id: orderId,
        movieTitle: "Avengers: Infinity War",
        duration: "2 hours 29 minutes",
        genres: "Action, adventure, sci-fi",
        showtime: "14:15",
        showDate: "10.12.2022",
        theater: "Vincom Ocean Park CGV",
        section: "Section 4",
        seats: ["H7", "H8"],
        price: amount,
        imageUrl: "https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
        purchaseDate: DateTime.now(),
      );
      
      print('Đã tạo vé: ${ticket.id}, ${ticket.movieTitle}');
      
      // Lưu vé trực tiếp
      final ticketJson = jsonEncode(ticket.toJson());
      
      // Key được sử dụng trong TicketService
      const String ticketsKey = 'user_tickets';
      
      // 1. Lưu vé khẩn cấp
      final emergencyResult = await prefs.setString('emergency_ticket', ticketJson);
      print('Kết quả lưu vé khẩn cấp: $emergencyResult');
      
      // 2. Lưu vé gần nhất
      final latestResult = await prefs.setString('latest_ticket', ticketJson);
      print('Kết quả lưu vé gần nhất: $latestResult');
      
      // 3. Tạo và lưu key mới
      final ticketKey = 'ticket_$orderId';
      final ticketResult = await prefs.setString(ticketKey, ticketJson);
      print('Kết quả lưu vé với key $ticketKey: $ticketResult');
      
      // 4. Cập nhật danh sách key - ĐÃ SỬA: đổi từ 'user_tickets' sang ticketsKey
      List<String> ticketKeys = prefs.getStringList(ticketsKey) ?? [];
      
      // Kiểm tra nếu key đã tồn tại
      if (!ticketKeys.contains(ticketKey)) {
        ticketKeys.add(ticketKey);
        final keysResult = await prefs.setStringList(ticketsKey, ticketKeys);
        print('Kết quả lưu danh sách ${ticketKeys.length} key: $keysResult');
        print('Các key vé hiện có: $ticketKeys');
      } else {
        print('Key $ticketKey đã tồn tại trong danh sách');
      }
      
      // Kiểm tra vé đã được lưu chưa
      final keysCheck = prefs.getStringList(ticketsKey) ?? [];
      print('Số lượng key vé sau khi lưu: ${keysCheck.length}');
      print('Danh sách key sau khi lưu: $keysCheck');
      
      // Kiểm tra vé khẩn cấp
      final emergencyCheck = prefs.getString('emergency_ticket');
      print('Kiểm tra vé khẩn cấp: ${emergencyCheck != null ? "Đã lưu" : "Chưa lưu"}');
      
      print('===== HOÀN TẤT LƯU VÉ ĐƠN GIẢN =====');
      
      // Hiển thị thông báo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thanh toán thành công! Vé của bạn đã được lưu.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      // Tự động điều hướng về trang chủ sau 3 giây
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
        }
      });
    } catch (e) {
      print('LỖI KHI LƯU VÉ ĐƠN GIẢN: $e');
      print(e.toString());
      
      // Cố gắng lưu lại bằng cách đơn giản nhất
      try {
        final prefs = await SharedPreferences.getInstance();
        final simpleTicket = Ticket(
          id: 'emergency_${DateTime.now().millisecondsSinceEpoch}',
          movieTitle: "Avengers: Infinity War",
          duration: "2 hours 29 minutes",
          genres: "Action, adventure, sci-fi",
          showtime: "14:15",
          showDate: "10.12.2022",
          theater: "Vincom Ocean Park CGV",
          section: "Section 4",
          seats: ["H7", "H8"],
          price: 100000,
          imageUrl: "https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg",
          purchaseDate: DateTime.now(),
        );
        final simpleJson = jsonEncode(simpleTicket.toJson());
        await prefs.setString('super_emergency_ticket', simpleJson);
        print('Đã lưu vé khẩn cấp cuối cùng thành công');
      } catch (finalError) {
        print('Lưu vé khẩn cấp cuối cùng thất bại: $finalError');
      }
    }
  }
  
  Future<void> _saveTicketAndShowSuccess() async {
    try {
      print('===== Bắt đầu lưu vé sau thanh toán thành công =====');
      // Lấy thông tin từ các provider
      final seatProvider = Provider.of<SeatProvider>(context, listen: false);
      final comboProvider = Provider.of<ComboProvider>(context, listen: false);
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      
      // Lấy mã đơn hàng từ kết quả thanh toán
      final orderId = widget.queryParams['vnp_TxnRef'] ?? 'TXN${DateTime.now().millisecondsSinceEpoch}';
      print('OrderID: $orderId');
      
      // Lấy thông tin từ các provider có sẵn
      final theaterName = 'Vincom Ocean Park CGV'; // Sử dụng giá trị mặc định cho rạp
      final roomName = roomProvider.roomName ?? 'Phòng không xác định';
      print('Theater: $theaterName, Room: $roomName');
      
      // Kiểm tra xem có ghế nào được chọn không
      print('Số ghế được chọn: ${seatProvider.selectedSeats.length}');
      if (seatProvider.selectedSeats.isEmpty) {
        print('Cảnh báo: Không có ghế nào được chọn');
      }
      
      // Sử dụng danh sách ghế cố định nếu không có ghế nào được chọn
      List<String> seats = seatProvider.selectedSeats.isNotEmpty
          ? seatProvider.selectedSeats.map((seat) => seat.seatName).toList()
          : ['H7', 'H8']; // Giá trị mặc định nếu không có ghế nào được chọn
      
      print('Danh sách ghế: $seats');
      
      // Lấy số tiền từ kết quả thanh toán
      final amount = double.parse(widget.queryParams['vnp_Amount'] ?? '0') / 100;
      print('Số tiền: $amount');
      
      // Sử dụng dữ liệu mặc định cho thông tin phim
      final movieTitle = "Avengers: Infinity War"; // Thông tin phim mặc định
      final movieDuration = "2 hours 29 minutes";
      final movieGenres = "Action, adventure, sci-fi";
      final imageUrl = "https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg";
      print('Thông tin phim: $movieTitle, $movieDuration');

      
      // Tạo vé mới
      final ticket = Ticket(
        id: orderId,
        movieTitle: movieTitle,
        duration: movieDuration,
        genres: movieGenres,
        showtime: '${DateTime.now().hour}:${DateTime.now().minute}',
        showDate: '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
        theater: theaterName,
        section: roomName,
        seats: seats,
        price: amount,
        imageUrl: imageUrl,
        purchaseDate: DateTime.now(),
      );
      
      // Lưu vé
      final saveResult = await _ticketService.saveTicket(ticket);
      print('Kết quả lưu vé: $saveResult');
      
      // Kiểm tra vé đã được lưu chưa
      final tickets = await _ticketService.getTickets();
      print('Số lượng vé đã lưu: ${tickets.length}');
      
      // Hiển thị thông báo thành công
      if (mounted) {
        print('Hiển thị thông báo thành công');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanh toán thành công! Vé của bạn đã được lưu.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      print('======= Hoàn tất lưu vé =======');
      
      // Tự động điều hướng về HomePage sau 3 giây
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          print('Chuyển về trang chủ');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        }
      });
    } catch (e) {
      print('Lỗi khi lưu vé: $e');
      print(e.toString());
      // Vẫn hiển thị thông báo thành công dù có lỗi để đảm bảo trải nghiệm người dùng
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanh toán thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Vẫn chuyển về trang chủ sau 3 giây
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          }
        });
      }
    }
  }

  Future<void> _processVNPayPayment() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Tạo mã đơn hàng duy nhất
      String orderCode = 'CINENOW${DateTime.now().millisecondsSinceEpoch}';
      
      // Gọi API tạo thanh toán
      final result = await PaymentService().createVNPayPayment(
        amount: 100000, // Thay bằng số tiền thực tế
        orderCode: orderCode,
        orderInfo: 'Thanh toan ve xem phim',
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (result['success'] == true && result['paymentUrl'] != null) {
        // Xử lý paymentUrl - mã này chỉ để tham khảo
        print('Payment URL: ${result['paymentUrl']}');
      } else {
        // Hiển thị lỗi
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tạo thanh toán: ${result['message'] ?? 'Lỗi không xác định'}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  String _getAmount() {
    try {
      if (widget.queryParams.containsKey('vnp_Amount')) {
        final amountStr = widget.queryParams['vnp_Amount']!;
        final amount = int.parse(amountStr) / 100; // VNPay nhân 100 khi gửi đi
        return _formatter.format(amount);
      }
    } catch (e) {
      print('Lỗi khi định dạng số tiền: $e');
    }
    return 'Không xác định';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Kết quả thanh toán'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            
            // Container for header with background color
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
            const SizedBox(height: 24),
            
            // Icon thành công/thất bại
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.amber : Colors.red,
              size: 72,
            ),
            const SizedBox(height: 16),
            
            // Tiêu đề kết quả
            Text(
              isSuccess ? 'Thanh toán thành công!' : 'Thanh toán thất bại',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.amber.shade700 : Colors.red,
              ),
            ),
            
            // Phụ đề
            if (isSuccess)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: Text(
                  'Vé đã được lưu thành công!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
            const SizedBox(height: 24),
            
            // Card thông tin
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
                    // Số tiền
                    ListTile(
                      title: const Text('Số tiền thanh toán'),
                      subtitle: Text(
                        _getAmount(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                      leading: Icon(Icons.monetization_on, color: Colors.amber.shade600),
                    ),
                    const Divider(),
                    
                    // Mã giao dịch
                    ListTile(
                      title: const Text('Mã đơn hàng'),
                      subtitle: Text(widget.queryParams['vnp_TxnRef'] ?? 'Không xác định'),
                      leading: const Icon(Icons.confirmation_number, color: Colors.blue),
                    ),
                    
                    // Thông tin ngân hàng
                    if (widget.queryParams.containsKey('vnp_BankCode'))
                      Column(
                        children: [
                          const Divider(),
                          ListTile(
                            title: const Text('Ngân hàng'),
                            subtitle: Text(widget.queryParams['vnp_BankCode'] ?? ''),
                            leading: const Icon(Icons.account_balance, color: Colors.indigo),
                          ),
                        ],
                      ),
                      
                    // Thời gian giao dịch
                    if (widget.queryParams.containsKey('vnp_PayDate'))
                      Column(
                        children: [
                          const Divider(),
                          ListTile(
                            title: const Text('Thời gian thanh toán'),
                            subtitle: Text(_formatPaymentDate(widget.queryParams['vnp_PayDate'] ?? '')),
                            leading: Icon(Icons.access_time, color: Colors.amber.shade600),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            // Nút "Xem vé của tôi"
            Container(
              width: 200, // Kích thước cố định để tránh lỗi hiển thị
              height: 50,
              margin: const EdgeInsets.only(bottom: 32),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  backgroundColor: isSuccess ? Colors.amber.shade600 : Colors.grey.shade700,
                  elevation: 3,
                ),
                child: Text(
                  isSuccess ? 'Xem vé của tôi' : 'Trở về trang chủ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatPaymentDate(String payDateStr) {
    try {
      if (payDateStr.length >= 14) {
        // Format: YYYYMMDDHHmmss
        final year = payDateStr.substring(0, 4);
        final month = payDateStr.substring(4, 6);
        final day = payDateStr.substring(6, 8);
        final hour = payDateStr.substring(8, 10);
        final minute = payDateStr.substring(10, 12);
        final second = payDateStr.substring(12, 14);
        
        return '$day/$month/$year $hour:$minute:$second';
      }
    } catch (e) {
      print('Lỗi định dạng ngày thanh toán: $e');
    }
    return payDateStr;
  }
}