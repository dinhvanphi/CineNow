import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cinenow/config/AppConfig.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cinenow/providers/CinemaProvider.dart';
import 'package:cinenow/providers/MovieProvider.dart';
import 'package:cinenow/providers/RoomProvider.dart';
import 'ShowtimeScreen.dart';
import 'package:intl/intl.dart';

class RoomListScreen extends StatefulWidget {
  @override
  _RoomListScreenState createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  List<dynamic> rooms = [];
  bool isLoading = true;
  String errorMessage = '';
  String? movieTitle;
  String? cinemaName;

  @override
  void initState() {
    super.initState();
    _loadCinemaData();
    fetchRooms();
    _loadMovieData();
  }

  // Lấy thông tin rạp từ API
  Future<void> _loadCinemaData() async {
    try {
      final cinemaId = Provider.of<CinemaProvider>(context, listen: false).cinemaId;
      if (cinemaId != null) {
        final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/api/cinemas/$cinemaId'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            cinemaName = data['name'] ?? 'Rạp đang chọn';
          });
        }
      }
    } catch (error) {
      print('Lỗi khi tải thông tin rạp: $error');
    }
  }

  // Lấy thông tin phim từ API
  Future<void> _loadMovieData() async {
    try {
      final movieId = Provider.of<MovieProvider>(context, listen: false).selectedMovieId;
      if (movieId != null) {
        final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/api/movies/$movieId'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            movieTitle = data['title'] ?? 'Phim đang chọn';
          });
        }
      }
    } catch (error) {
      print('Lỗi khi tải thông tin phim: $error');
    }
  }

  Future<void> fetchRooms() async {
    try {
      int? cinemaId = Provider.of<CinemaProvider>(context, listen: false).cinemaId;
      if (cinemaId != null) {
        final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/api/rooms/$cinemaId'));
        if (response.statusCode == 200) {
          setState(() {
            rooms = jsonDecode(response.body);
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Lỗi khi tải danh sách phòng';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Không tìm thấy ID rạp chiếu phim';
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Lỗi kết nối: $error';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin từ provider
    final cinemaProvider = Provider.of<CinemaProvider>(context);
    // Sử dụng biến movieTitle và cinemaName từ state hoặc giá trị mặc định
    final title = movieTitle ?? 'Phim đang chọn';
    final cinema = cinemaName ?? 'Rạp đang chọn';
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Chọn phòng chiếu', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần thông tin phim và rạp
          Container(
            color: Color(0xFF121212),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Tại: $cinema',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Tiêu đề danh sách
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Chọn phòng chiếu phim',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Phần danh sách phòng
          Expanded(
            child: isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Colors.amber,
                  ),
                )
              : errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          errorMessage, 
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: fetchRooms,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Thử lại',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : rooms.isEmpty
                  ? Center(
                      child: Text(
                        'Không có phòng chiếu nào',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                if (rooms[index] != null && 
                                    rooms[index]['room_id'] != null && 
                                    rooms[index]['room_id'] is int) {
                                  
                                  // Thiết lập ID phòng
                                  Provider.of<RoomProvider>(context, listen: false)
                                      .setRoom(
                                          rooms[index]['room_id'],
                                          name: rooms[index]['name'],
                                          capacity: rooms[index]['capacity']
                                      );
                                  
                                  // Điều hướng đến màn hình suất chiếu
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ShowtimeScreen(
                                        movieId: Provider.of<MovieProvider>(context, listen: false).selectedMovieId ?? 0,
                                        movieTitle: title,
                                      )
                                    )
                                  );
                                } else {
                                  // Hiển thị thông báo lỗi chi tiết hơn
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Không thể xác định phòng chiếu. Dữ liệu không hợp lệ.'),
                                      backgroundColor: Colors.red,
                                    )
                                  );
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Icon phòng
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.meeting_room,
                                          color: Colors.amber,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                    
                                    SizedBox(width: 16),
                                    
                                    // Thông tin phòng
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            rooms[index]['name'] ?? 'Phòng không xác định',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.chair,
                                                color: Colors.grey[400],
                                                size: 16,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                '${rooms[index]['capacity'] ?? 0} ghế',
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              if (rooms[index]['room_type'] != null) ...[
                                                Icon(
                                                  Icons.movie,
                                                  color: Colors.grey[400],
                                                  size: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  rooms[index]['room_type'],
                                                  style: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Icon mũi tên
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.arrow_forward,
                                          color: Colors.amber,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}