import 'package:flutter/material.dart';

class CinemaProvider with ChangeNotifier {
  int? _cinemaId;

  int? get cinemaId => _cinemaId;

  void setCinemaId(int id) {
    _cinemaId = id;
    notifyListeners();
  }
}
// lưu id rạp được chọn . 

