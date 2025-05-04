import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/Seat.dart';
import '../../providers/SeatProvider.dart';
import 'package:intl/intl.dart'; // Để định dạng số tiền
import '../../screens/movie/ComboSelectionScreen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final int showtimeId;
  final String movieTitle;

  const SeatSelectionScreen({
    Key? key,
    required this.showtimeId,
    required this.movieTitle,
  }) : super(key: key);

  @override
  _SeatSelectionScreenState createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final moneyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSeats();
    });
  }

  // Lưu trữ provider để sử dụng trong dispose
  SeatProvider? _seatProvider;
  
  @override
  void didChangeDependencies() {
    // Lấy provider từ context khi widget được gắn kết với cây widget
    _seatProvider = Provider.of<SeatProvider>(context, listen: false);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    
    try {
      // Giải phóng ghế khi rời khỏi màn hình nếu chưa tiếp tục
      // Sử dụng provider đã lưu trữ trước đó
      if (_seatProvider != null && _seatProvider!.selectedSeats.isNotEmpty) {
        _seatProvider!.unlockSeats(widget.showtimeId);
      }
    } catch (e) {
      print('Lỗi khi giải phóng ghế trong dispose: $e');
    }
    
    super.dispose();
  }

  Future<void> _loadSeats() async {
    await Provider.of<SeatProvider>(context, listen: false)
        .loadSeats(widget.showtimeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Chọn ghế', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SeatProvider>(
        builder: (context, seatProvider, _) {
          if (seatProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          if (seatProvider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    seatProvider.errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadSeats,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    child: Text('Thử lại', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            );
          }

          final showtimeInfo = seatProvider.showtimeSeats?.showtime;
          if (showtimeInfo == null) {
            return Center(
              child: Text(
                'Không có thông tin ghế',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            );
          }

          return Column(
            children: [
              // Phần thông tin phim và màn hình
              Container(
                color: Colors.black,
                child: Column(
                  children: [
                    _buildMovieInfo(seatProvider),
                    _buildScreenView(),
                  ],
                ),
              ),
              
              // Phần khung chọn ghế có thể cuộn
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 80), // Thêm padding dưới để không bị che khuất
                    child: _buildSeatGrid(seatProvider),
                  ),
                ),
              ),
              
              // Phần chú thích và thanh thanh toán
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegend(),
                  _buildCheckoutBar(seatProvider),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMovieInfo(SeatProvider seatProvider) {
    final showtimeInfo = seatProvider.showtimeSeats?.showtime;
    if (showtimeInfo == null) return SizedBox();

    String startTime = 'N/A';
    if (showtimeInfo['start_time'] != null) {
      final dateTime = DateTime.parse(showtimeInfo['start_time']);
      startTime = "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.movieTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.meeting_room, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text(
                'Phòng ${showtimeInfo['room_name'] ?? 'N/A'}',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(width: 16),
              Icon(Icons.access_time, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text(
                startTime,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScreenView() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            'MÀN HÌNH',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              letterSpacing: 4,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: 280,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(100),
                topRight: Radius.circular(100),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSeat(Seat seat, SeatProvider seatProvider) {
    // Xác định màu sắc dựa trên loại ghế và trạng thái
    Color seatColor;
    IconData? seatIcon;
    
    // Nếu ghế không khả dụng
    if (!seat.isAvailable) {
      seatColor = Colors.grey;
    } 
    // Nếu ghế đã được chọn
    else if (seat.isSelected) {
      seatColor = Colors.amber;
    } 
    // Màu dựa trên loại ghế
    else {
      switch (seat.seatType.toLowerCase()) {
        case 'ghế đôi':
          seatColor = Colors.pinkAccent;
          seatIcon = Icons.favorite;
          break;
        case 'ghế imax':
          seatColor = Colors.purpleAccent;
          break;
        case 'ghế 4dx':
          seatColor = Colors.tealAccent;
          break;
        case 'ghế lamour':
          seatColor = Colors.redAccent;
          seatIcon = Icons.king_bed;
          break;
        default:
          seatColor = Colors.lightBlueAccent;
      }
    }

    // Hiển thị tooltip với thông tin giá ghế
    String tooltipMessage = seat.isSelected 
        ? '${seat.seatName}: ${moneyFormat.format(seat.actualPrice ?? 0)}'
        : '${seat.seatName} - ${seat.getTypeDisplay()}';

    return GestureDetector(
      onTap: () {
        if (seat.isAvailable && !seat.isLocked) {
          seatProvider.toggleSeatSelection(seat);
        }
      },
      child: Tooltip(
        message: tooltipMessage,
        child: Container(
          width: 28,
          height: 28,
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: seatColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: seatIcon != null 
              ? Icon(seatIcon, size: 16, color: Colors.white)
              : Text(
                  seat.rowNumber.toString(),
                  style: TextStyle(
                    color: seat.isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeatGrid(SeatProvider seatProvider) {
    final seatsByRow = seatProvider.seatsByRow;
    
    // Log để debug
    print('SeatSelectionScreen._buildSeatGrid - Rows: ${seatsByRow.keys.toList()}');
    
    if (seatsByRow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat, color: Colors.grey[700], size: 48),
            SizedBox(height: 16),
            Text(
              'Không có dữ liệu ghế cho suất chiếu này',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Vui lòng thử lại sau hoặc chọn suất chiếu khác',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSeats,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: Text('Tải lại dữ liệu'),
            ),
          ],
        ),
      );
    }

    // Sắp xếp các hàng theo thứ tự chữ cái
    final sortedRows = seatsByRow.keys.toList()..sort();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: sortedRows.map((rowKey) {
              final seats = seatsByRow[rowKey] ?? [];
              
              return Padding(
                padding: EdgeInsets.only(bottom: 12), // Tăng khoảng cách giữa các hàng
                child: Row(
                  children: [
                    // Hiển thị chữ cái hàng
                    SizedBox(
                      width: 20,
                      child: Text(
                        rowKey,
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Hiển thị các ghế trong hàng
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...seats.map((seat) => _buildSeat(seat, seatProvider)).toList(),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    // Hiển thị chữ cái hàng (bên phải)
                    SizedBox(
                      width: 20,
                      child: Text(
                        rowKey,
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        
        // Thêm khoảng trống dưới cùng để đảm bảo có thể cuộn đến hàng cuối cùng
        SizedBox(height: 60),
      ],
    );
  }

  Widget _buildLegend() {
    final legendItems = [
      {'color': Colors.lightBlueAccent, 'label': 'Ghế thường'},
      {'color': Colors.pinkAccent, 'label': 'Ghế đôi'},
      {'color': Colors.purpleAccent, 'label': 'Ghế IMAX'},
      {'color': Colors.tealAccent, 'label': 'Ghế 4DX'},
      {'color': Colors.redAccent, 'label': 'Ghế Lamour'},
      {'color': Colors.amber, 'label': 'Đã chọn'},
      {'color': Colors.grey, 'label': 'Đã đặt'},
    ];

    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[900],
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: legendItems.map((item) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: item['color'] as Color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 4),
              Text(
                item['label'] as String,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCheckoutBar(SeatProvider seatProvider) {
    final selectedSeats = seatProvider.selectedSeats;
    final totalAmount = seatProvider.totalAmount;
    
    // Format tiền Việt Nam
    final formattedAmount = moneyFormat.format(totalAmount);

    // Nhóm ghế theo loại để hiển thị chi tiết
    Map<String, List<Seat>> seatsByType = {};
    for (var seat in selectedSeats) {
      if (!seatsByType.containsKey(seat.seatType)) {
        seatsByType[seat.seatType] = [];
      }
      seatsByType[seat.seatType]!.add(seat);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedSeats.isNotEmpty) ...[
              // Sử dụng SingleChildScrollView ngang để hiển thị danh sách ghế đã chọn
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  'Ghế đã chọn: ${selectedSeats.map((s) => s.seatName).join(', ')}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 8),
              
              // Nếu có nhiều loại ghế, sử dụng SingleChildScrollView
              if (seatsByType.length > 2) 
                Container(
                  height: 70, // Giới hạn chiều cao 
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Hiển thị chi tiết giá theo loại ghế
                        ...seatsByType.entries.map((entry) {
                          final seatType = entry.key;
                          final seats = entry.value;
                          final typeTotal = seats.fold<double>(
                            0, (sum, seat) => sum + (seat.actualPrice ?? 0));
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${seats.length} × ${seats[0].getTypeDisplay()}:',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  moneyFormat.format(typeTotal),
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                )
              else
                // Hiển thị chi tiết giá theo loại ghế
                ...seatsByType.entries.map((entry) {
                  final seatType = entry.key;
                  final seats = entry.value;
                  final typeTotal = seats.fold<double>(
                    0, (sum, seat) => sum + (seat.actualPrice ?? 0));
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${seats.length} × ${seats[0].getTypeDisplay()}:',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          moneyFormat.format(typeTotal),
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              
              SizedBox(height: 8),
              Divider(color: Colors.grey[800]),
              SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng tiền:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formattedAmount,
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedSeats.isEmpty
                    ? null
                    : () async {
                        // Khóa ghế và chuyển đến màn hình combo
                        final success = await seatProvider.lockSelectedSeats(widget.showtimeId);
                        if (success) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ComboSelectionScreen(
                                showtimeId: widget.showtimeId,
                                movieTitle: widget.movieTitle,
                                seatTotalAmount: seatProvider.totalAmount,
                                selectedSeats: seatProvider.selectedSeats.map((seat) => seat.seatName).toList(),
                                sessionId: seatProvider.sessionId,
                              ),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  disabledBackgroundColor: Colors.grey[800],
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  selectedSeats.isEmpty ? 'Vui lòng chọn ghế' : 'Tiếp tục',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}