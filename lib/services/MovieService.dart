import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Movie.dart';

class MovieService {
  // URL API lấy từ server, thay đổi IP tùy theo môi trường
  // Thay thế bằng IP máy chủ của bạn
  final String baseUrl = 'https://d623-116-105-212-66.ngrok-free.app/api';

  // Lấy danh sách phim đang chiếu
  Future<List<Movie>> getNowShowingMovies() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/movies?status=now_showing'));
      print('Đang lấy phim đang chiếu: ${response.request?.url}');
      
      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        final List<dynamic> data = json.decode(response.body);
        return data.map((movie) => Movie.fromMap(movie)).toList();
      } else {
        print('Lỗi lấy phim đang chiếu: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception khi lấy phim đang chiếu: $e');
      return [];
    }
  }

  // Lấy danh sách phim sắp chiếu
  Future<List<Movie>> getComingSoonMovies() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/movies?status=coming_soon'));
      print('Đang lấy phim sắp chiếu: ${response.request?.url}');
      
      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        final List<dynamic> data = json.decode(response.body);
        return data.map((movie) => Movie.fromMap(movie)).toList();
      } else {
        print('Lỗi lấy phim sắp chiếu: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception khi lấy phim sắp chiếu: $e');
      return [];
    }
  }

  // Lấy phim nổi bật (featured) cho banner
  Future<List<Movie>> getFeaturedMovies() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/movies?featured=true'));
      print('Đang lấy phim nổi bật: ${response.request?.url}');
      
      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        final List<dynamic> data = json.decode(response.body);
        return data.map((movie) => Movie.fromMap(movie)).toList();
      } else {
        print('Lỗi lấy phim nổi bật: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception khi lấy phim nổi bật: $e');
      return [];
    }
  }

  // Lấy chi tiết phim theo ID
  Future<Movie?> getMovieById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/movies/$id'));
      print('Đang lấy chi tiết phim: ${response.request?.url}');
      
      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        final dynamic data = json.decode(response.body);
        return Movie.fromMap(data);
      } else {
        print('Lỗi lấy chi tiết phim: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception khi lấy chi tiết phim: $e');
      return null;
    }
  }

  // Lấy tất cả phim
  Future<List<Movie>> getAllMovies() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/movies'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((movie) => Movie.fromMap(movie)).toList();
      } else {
        throw Exception('Failed to load all movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching all movies: $e');
    }
  }
  
  // Tìm kiếm phim theo title
  Future<List<Movie>> searchMovies(String query) async {
    try {
      // Mã hóa query để tránh các vấn đề với ký tự đặc biệt
      final encodedQuery = Uri.encodeComponent(query);
      final response = await http.get(
        Uri.parse('$baseUrl/movies/search?query=$encodedQuery'),
        headers: {'Content-Type': 'application/json'},
      );
      
      print('Đang tìm kiếm phim: ${response.request?.url}');
      
      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        final List<dynamic> data = json.decode(response.body);
        return data.map((movie) => Movie.fromMap(movie)).toList();
      } else {
        print('Lỗi tìm kiếm phim: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception khi tìm kiếm phim: $e');
      return [];
    }
  }
} 