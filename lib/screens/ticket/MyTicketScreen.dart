import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/Ticket.dart';
import '../../services/TicketService.dart';
import 'MockBarcodeImage.dart';

class MyTicketScreen extends StatefulWidget {
  const MyTicketScreen({Key? key}) : super(key: key);

  @override
  _MyTicketScreenState createState() => _MyTicketScreenState();
}

class _MyTicketScreenState extends State<MyTicketScreen> {
  final TicketService _ticketService = TicketService();
  List<Ticket> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('===== MY TICKET SCREEN: Đang tải vé =====');
      // Phương pháp chính: lấy danh sách vé từ TicketService
      final tickets = await _ticketService.getTickets();
      print('Tải được ${tickets.length} vé từ TicketService');
      
      if (tickets.isNotEmpty) {
        setState(() {
          _tickets = tickets;
          _isLoading = false;
        });
        return;
      }
      
      // Phương pháp dự phòng: Kiểm tra trực tiếp các key lưu trữ
      final prefs = await SharedPreferences.getInstance();
      
      // Kiểm tra vé mới nhất
      final latestTicketJson = prefs.getString('latest_ticket');
      if (latestTicketJson != null) {
        print('Tìm thấy vé gần nhất');
        try {
          final ticket = Ticket.fromJson(jsonDecode(latestTicketJson));
          setState(() {
            _tickets = [ticket];
            _isLoading = false;
          });
          return;
        } catch (e) {
          print('Lỗi khi chuyển đổi vé gần nhất: $e');
        }
      }
      
      // Kiểm tra vé khẩn cấp
      final emergencyTicketJson = prefs.getString('emergency_ticket');
      if (emergencyTicketJson != null) {
        print('Tìm thấy vé khẩn cấp');
        try {
          final ticket = Ticket.fromJson(jsonDecode(emergencyTicketJson));
          setState(() {
            _tickets = [ticket];
            _isLoading = false;
          });
          return;
        } catch (e) {
          print('Lỗi khi chuyển đổi vé khẩn cấp: $e');
        }
      }
      
      // Kiểm tra vé khẩn cấp cuối cùng
      final superEmergencyTicketJson = prefs.getString('super_emergency_ticket');
      if (superEmergencyTicketJson != null) {
        print('Tìm thấy vé khẩn cấp cuối cùng');
        try {
          final ticket = Ticket.fromJson(jsonDecode(superEmergencyTicketJson));
          setState(() {
            _tickets = [ticket];
            _isLoading = false;
          });
          return;
        } catch (e) {
          print('Lỗi khi chuyển đổi vé khẩn cấp cuối cùng: $e');
        }
      }
      
      // Không tìm thấy vé nào
      print('Không tìm thấy vé nào');
      setState(() {
        _tickets = [];
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi tải vé: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('My tickets', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _tickets.isEmpty
              ? _buildEmptyState()
              : _buildTicketList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number_outlined, size: 80.sp, color: Colors.grey[600]),
          SizedBox(height: 16.h),
          Text(
            'Bạn chưa có vé nào',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.grey[400],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Vé sẽ xuất hiện ở đây sau khi bạn đặt vé xem phim',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'VND');
    final formattedPrice = formatter.format(ticket.price);

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Movie info section
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Movie poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    ticket.imageUrl,
                    width: 80.w,
                    height: 120.h,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80.w,
                      height: 120.h,
                      color: Colors.grey[800],
                      child: Icon(Icons.movie, color: Colors.grey[600], size: 30.sp),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                // Movie details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.movieTitle,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14.sp, color: Colors.grey[400]),
                          SizedBox(width: 4.w),
                          Text(
                            ticket.duration,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        ticket.genres,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[400],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14.sp, color: Colors.grey[400]),
                          SizedBox(width: 4.w),
                          Text(
                            '${ticket.showDate} - ${ticket.showtime}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Dashed line divider
          Container(
            height: 1.h,
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: List.generate(
                30,
                (index) => Expanded(
                  child: Container(
                    color: index % 2 == 0 ? Colors.grey[800] : Colors.transparent,
                    height: 1.h,
                  ),
                ),
              ),
            ),
          ),
          
          // Ticket details section
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16.r),
                bottomRight: Radius.circular(16.r),
              ),
            ),
            child: Column(
              children: [
                _buildTicketInfoRow('Order ID:', ticket.id),
                SizedBox(height: 8.h),
                _buildTicketInfoRow('Seat:', ticket.seats.join(', ')),
                SizedBox(height: 8.h),
                _buildTicketInfoRow('Section:', ticket.section),
                SizedBox(height: 8.h),
                _buildTicketInfoRow('Theater:', ticket.theater),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      formattedPrice,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.qr_code,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Show this QR code to the ticket counter to receive your ticket',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // Barcode - Sử dụng MockBarcodeImage thay vì hình ảnh
                Container(
                  height: 50.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: Colors.white,
                  ),
                  child: MockBarcodeImage(
                    code: ticket.id,
                    height: 50.h,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[400],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
