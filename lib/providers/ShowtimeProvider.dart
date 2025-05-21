import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cinenow/providers/CinemaProvider.dart';
import 'package:cinenow/providers/MovieProvider.dart';
import 'package:cinenow/providers/RoomProvider.dart'; // Thêm import RoomProvider

class ShowtimeProvider extends ChangeNotifier {
  List<dynamic> showtimes = [];
  bool isLoading = false;
  String errorMessage = '';

  Future<void> fetchShowtimes(BuildContext context) async {
    // Lấy room_id từ RoomProvider
    final roomProvider = Provider.of<RoomProvider>(context, listen: false);
    // Lấy movie_id từ MovieProvider 
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);

    // Kiểm tra điều kiện
    if (roomProvider.roomId == null || movieProvider.selectedMovieId == null) {
      errorMessage = 'Chưa chọn phòng hoặc phim';
      notifyListeners();
      return;
    }

    // Đặt trạng thái đang tải
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
          'https://67c7-171-251-30-227.ngrok-free.app/api/showtimes?room_id=${roomProvider.roomId}&movie_id=${movieProvider.selectedMovieId}'
        )
      );

      if (response.statusCode == 200) {
        showtimes = jsonDecode(response.body);
        isLoading = false;
        notifyListeners();
      } else {
        errorMessage = 'Không thể tải suất chiếu';
        isLoading = false;
        notifyListeners();
      }
    } catch (error) {
      errorMessage = 'Lỗi kết nối: $error';
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchShowtimesByMovie(int movieId, BuildContext context) async {
    // Đặt trạng thái đang tải
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      // Lấy room_id từ RoomProvider
      final roomProvider = Provider.of<RoomProvider>(context, listen: false);
      if (roomProvider.roomId == null) {
        errorMessage = 'Chưa chọn phòng';
        isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse(
          'https://67c7-171-251-30-227.ngrok-free.app/api/showtimes?room_id=${roomProvider.roomId}&movie_id=$movieId'
        )
      );

      if (response.statusCode == 200) {
        showtimes = jsonDecode(response.body);
        isLoading = false;
        notifyListeners();
      } else {
        errorMessage = 'Không thể tải suất chiếu';
        isLoading = false;
        notifyListeners();
      }
    } catch (error) {
      errorMessage = 'Lỗi kết nối: $error';
      isLoading = false;
      notifyListeners();
    }
  }
}