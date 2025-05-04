import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Room.dart';

class RoomService {
  static Future<List<Room>> fetchRooms(int cinemaId) async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/rooms/$cinemaId'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Room.fromJson(json)).toList();
    } else {
      throw Exception('Lỗi khi tải danh sách phòng');
    }
  }
}
