class Room {
  final int id;
  final String name;
  final int seatCount;

  Room({required this.id, required this.name, required this.seatCount});

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      seatCount: json['seat_count'],
    );
  }
}
