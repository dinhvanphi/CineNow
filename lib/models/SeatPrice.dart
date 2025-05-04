class SeatPrice {
  final int priceId;
  final String seatType;
  final double price;

  SeatPrice({
    required this.priceId,
    required this.seatType,
    required this.price,
  });

  factory SeatPrice.fromMap(Map<String, dynamic> map) {
    return SeatPrice(
      priceId: map['price_id'],
      seatType: map['seat_type'] ?? 'Không xác định',
      price: (map['price'] is int) 
          ? (map['price'] as int).toDouble() 
          : (map['price'] ?? 0.0),
    );
  }
} 