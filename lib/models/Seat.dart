class Seat {
  final int seatId;
  final String seatName;
  final String rowLetter;
  final int rowNumber;
  final String seatType;
  final String? status;
  final double? actualPrice;
  final int? reservationId;
  final bool isLocked;
  final int? priceId;
  bool isSelected; // Biến local để theo dõi ghế đã chọn

  Seat({
    required this.seatId,
    required this.seatName,
    required this.rowLetter,
    required this.rowNumber,
    required this.seatType,
    this.status,
    this.actualPrice,
    this.reservationId,
    this.isLocked = false,
    this.priceId,
    this.isSelected = false,
  });

  factory Seat.fromMap(Map<String, dynamic> map) {
    return Seat(
      seatId: map['seat_id'],
      seatName: map['seat_name'],
      rowLetter: map['row_letter'],
      rowNumber: map['row_number'],
      seatType: map['seat_type'],
      status: map['status'],
      actualPrice: map['actual_price'] != null ? double.parse(map['actual_price'].toString()) : null,
      reservationId: map['reservation_id'],
      isLocked: map['is_locked'] == true,
      priceId: map['price_id'],
      isSelected: false,
    );
  }

  // Tạo bản sao của ghế với trạng thái chọn đã cập nhật
  Seat copyWith({bool? isSelected, double? actualPrice}) {
    return Seat(
      seatId: seatId,
      seatName: seatName,
      rowLetter: rowLetter,
      rowNumber: rowNumber,
      seatType: seatType,
      status: status,
      actualPrice: actualPrice ?? this.actualPrice,
      reservationId: reservationId,
      isLocked: isLocked,
      priceId: priceId,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  // Kiểm tra ghế có khả dụng không
  bool get isAvailable => status == null || status == 'available';

  // Trả về màu sắc dựa trên loại ghế
  String getTypeDisplay() {
    switch (seatType.toLowerCase()) {
      case 'ghế thường':
        return 'Thường';
      case 'ghế đôi':
        return 'Couple';
      case 'ghế imax':
        return 'IMAX';
      case 'ghế 4dx':
        return '4DX';
      case 'ghế lamour':
        return 'Lamour';
      default:
        return seatType;
    }
  }
}