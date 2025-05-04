// lib/screens/payment/sandbox_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cinenow/screens/payment/PaymentResultScreen.dart';
import 'package:cinenow/services/PaymentService.dart';
import 'package:cinenow/providers/SeatProvider.dart';
import 'package:cinenow/providers/ComboProvider.dart';
import 'package:cinenow/providers/MovieProvider.dart';
import 'package:cinenow/providers/CinemaProvider.dart';
import 'package:cinenow/providers/RoomProvider.dart';

class SandboxPaymentScreen extends StatefulWidget {
  final int bookingId;
  final double totalAmount;
  final String movieTitle;
  
  const SandboxPaymentScreen({
    Key? key, 
    required this.bookingId, 
    required this.totalAmount,
    required this.movieTitle,
  }) : super(key: key);

  @override
  _SandboxPaymentScreenState createState() => _SandboxPaymentScreenState();
}

class _SandboxPaymentScreenState extends State<SandboxPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  
  // Các thông tin về rạp và phòng chiếu
  String _theaterName = '';
  String _roomName = '';
  
  @override
  void initState() {
    super.initState();
    // Không gọi trong initState vì context chưa sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookingDetails();
    });
  }
  
  // Tải thông tin chi tiết đặt vé từ các provider
  void _loadBookingDetails() {
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    
    try {
      // Thiết lập tên rạp mặc định
      _theaterName = 'CineNow';
      
      // Lấy tên phòng từ RoomProvider nếu có
      if (roomProvider.roomId != null && roomProvider.roomName != null) {
        _roomName = roomProvider.roomName ?? 'Phòng chiếu';
      } else {
        _roomName = 'Phòng chiếu';
      }
      
      setState(() {});
    } catch (e) {
      print('Lỗi khi tải thông tin đặt vé: $e');
    }
  }

  Future<void> _processVnpayPayment() async {
    // Đặt loading state
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Thông tin thanh toán
      final String orderInfo = "Thanh toan ve xem phim ${widget.movieTitle}";
      final double amount = widget.totalAmount;
      
      // Sử dụng phương thức với VNPAYFlutter package
      await _paymentService.processVNPayFlutterPayment(
        context: context,
        amount: amount,
        orderInfo: orderInfo,
        movieTitle: widget.movieTitle,
        bookingId: widget.bookingId,
        onSuccess: (params) {
          // Xử lý khi thanh toán thành công
          print('Thanh toán VNPay thành công với params: $params');
          setState(() {
            _isLoading = false;
          });
          
          // Chuyển đổi Map<String, dynamic> thành Map<String, String>
          final Map<String, String> stringParams = {};
          params.forEach((key, value) {
            stringParams[key] = value.toString();
          });
          
          // Chuyển đến màn hình kết quả
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentResultScreen(
                queryParams: stringParams,
              ),
            ),
          );
        },
        onError: (params) {
          // Xử lý khi thanh toán thất bại
          print('Thanh toán VNPay thất bại với params: $params');
          setState(() {
            _isLoading = false;
          });
          
          // Chuyển đổi Map<String, dynamic> thành Map<String, String>
          final Map<String, String> stringParams = {};
          params.forEach((key, value) {
            stringParams[key] = value.toString();
          });
          
          // Vẫn chuyển đến màn hình kết quả để hiển thị lỗi
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentResultScreen(
                queryParams: stringParams,
              ),
            ),
          );
        },
      );
    } catch (e) {
      // Xử lý lỗi
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildOrderSummary(),
                  const SizedBox(height: 24),
                  
                  // Hiển thị logo VNPay
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, color: Colors.blue, size: 36),
                            const SizedBox(width: 16),
                            const Text(
                              'VNPay',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Thanh toán an toàn qua cổng VNPay'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Nút thanh toán ngay với VNPay
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _processVnpayPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Thanh toán ngay với VNPay',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Thông báo sandbox (nhỏ gọn hơn)
                  // Container(
                  //   padding: const EdgeInsets.all(12),
                  //   decoration: BoxDecoration(
                  //     color: Colors.amber[50],
                  //     borderRadius: BorderRadius.circular(8),
                  //     border: Border.all(color: Colors.amber.shade200),
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
                  //       const SizedBox(width: 8),
                  //       Expanded(
                  //         child: Text(
                  //           'Đây là môi trường sandbox dùng để test thanh toán',
                  //           style: TextStyle(fontSize: 13, color: Colors.amber[800]),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderSummary() {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final seatProvider = Provider.of<SeatProvider>(context);
    final comboProvider = Provider.of<ComboProvider>(context);
    
    // Tổng giá trị các combo
    final comboAmount = comboProvider.totalAmount;
    // Tổng giá vé (từ SeatProvider)
    final ticketAmount = seatProvider.totalAmount;
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin thanh toán',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Divider(height: 24),
            
            // Thông tin phim và rạp
            _buildInfoRow('Phim:', widget.movieTitle),
            _buildInfoRow('Rạp:', _theaterName),
            _buildInfoRow('Phòng:', _roomName),
            _buildInfoRow('Ghế:', seatProvider.selectedSeats.isNotEmpty 
              ? seatProvider.selectedSeats.map((s) => s.seatName).join(', ')
              : 'Chưa chọn ghế'),
            _buildInfoRow('Mã đặt vé:', 'BK${widget.bookingId}'),
            
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            // Thông tin combo (nếu có)
            if (comboProvider.selectedCombos.isNotEmpty) ...[  
              const Text(
                'Combo đồ ăn/nước uống',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              ...comboProvider.selectedCombos.map((combo) => _buildComboRow(
                combo.name, 
                combo.quantity, 
                formatter.format(combo.price * combo.quantity),
              )),
            ],
            
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            
            // Chi tiết thanh toán
            const Text(
              'Chi tiết thanh toán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Giá vé:', formatter.format(ticketAmount)),
            if (comboAmount > 0)
              _buildInfoRow('Combo:', formatter.format(comboAmount)),
            const Divider(height: 24),
            _buildInfoRow('Tổng cộng:', formatter.format(widget.totalAmount), isTotal: true),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label, 
              style: TextStyle(
                color: isTotal ? Colors.black : Colors.grey[700],
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                fontSize: isTotal ? 18 : 14,
                color: isTotal ? Colors.blue.shade800 : Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildComboRow(String name, int quantity, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              'x$quantity',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              price,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }


}