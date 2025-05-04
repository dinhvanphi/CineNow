import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cinenow/providers/ShowtimeProvider.dart';
import 'package:cinenow/providers/SeatProvider.dart';
import 'package:cinenow/providers/MovieProvider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'SeatSelectionScreen.dart';

class ShowtimeScreen extends StatefulWidget {
  final int movieId;
  final String movieTitle;

  const ShowtimeScreen({
    Key? key,
    required this.movieId,
    required this.movieTitle,
  }) : super(key: key);

  @override
  _ShowtimeScreenState createState() => _ShowtimeScreenState();
}

class _ShowtimeScreenState extends State<ShowtimeScreen> {
  String formatDateTime(String isoDateTime) {
    try {
      DateTime dateTime = DateTime.parse(isoDateTime);
      dateTime = dateTime.toLocal();
      final vietnameseDateFormat = DateFormat('HH:mm', 'vi');
      return vietnameseDateFormat.format(dateTime);
    } catch (e) {
      print('Lỗi định dạng ngày giờ: $e');
      return isoDateTime;
    }
  }

  String formatFullDateTime(String isoDateTime) {
    try {
      DateTime dateTime = DateTime.parse(isoDateTime);
      dateTime = dateTime.toLocal();
      final vietnameseDateFormat = DateFormat('dd/MM/yyyy HH:mm', 'vi');
      return vietnameseDateFormat.format(dateTime);
    } catch (e) {
      print('Lỗi định dạng ngày giờ: $e');
      return isoDateTime;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShowtimeProvider>(context, listen: false)
          .fetchShowtimesByMovie(widget.movieId, context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suất Chiếu'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Consumer<ShowtimeProvider>(
        builder: (context, showtimeProvider, child) {
          // Trạng thái đang tải
          if (showtimeProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }

          // Trạng thái lỗi
          if (showtimeProvider.errorMessage.isNotEmpty) {
            return Center(
              child: Text(
                showtimeProvider.errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          // Không có suất chiếu
          if (showtimeProvider.showtimes.isEmpty) {
            return Center(
              child: Text(
                'Không có suất chiếu',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // Danh sách suất chiếu
          return ListView.builder(
            itemCount: showtimeProvider.showtimes.length,
            itemBuilder: (context, index) {
              var showtime = showtimeProvider.showtimes[index];
              return Container(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: Colors.yellow,
                        size: 30,
                      ),
                    ],
                  ),
                  title: Text(
                    'Bắt đầu: ${formatDateTime(showtime['start_time'])}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngày: ${formatFullDateTime(showtime['start_time'])}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kết thúc: ${formatDateTime(showtime['end_time'])}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.yellow,
                  ),
                  onTap: () {
                    // Reset trạng thái SeatProvider
                    Provider.of<SeatProvider>(context, listen: false).reset();
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeatSelectionScreen(
                          showtimeId: showtime['showtime_id'],
                          movieTitle: widget.movieTitle,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}