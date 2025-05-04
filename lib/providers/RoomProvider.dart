import 'package:flutter/material.dart';

class RoomProvider extends ChangeNotifier {
  int? roomId; // Đổi tên từ selectedRoomId sang roomId để thống nhất
  String? roomName;
  int? roomCapacity;

  void setRoom(int id, {String? name, int? capacity}) {
    roomId = id;
    roomName = name;
    roomCapacity = capacity;
    notifyListeners();
  }

  void clearRoom() {
    roomId = null;
    roomName = null;
    roomCapacity = null;
    notifyListeners();
  }

  bool get isRoomSelected => roomId != null;
}