import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/Seat.dart';
import '../models/SeatPrice.dart';
import '../models/ShowtimeSeats.dart';
import '../services/SeatService.dart';
import '../constants/api_constants.dart';

class SeatProvider with ChangeNotifier {
  final SeatService _seatService = SeatService();
  ShowtimeSeats? _showtimeSeats;
  List<Seat> _selectedSeats = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _sessionId = const Uuid().v4(); // Tạo ID phiên ngẫu nhiên
  Map<int, SeatPrice> _seatPrices = {}; // Cache giá ghế theo price_id

  SeatProvider() {
    // Kiểm tra URL khi khởi tạo
    ApiConstants.printBaseUrl();
  }

  // Giá mặc định cho các loại ghế (VND) - sử dụng khi không thể lấy được giá từ API
  final Map<String, double> _defaultPrices = {
    'ghế thường': 80000,
    'ghế đôi': 150000,
    'ghế imax': 120000,
    'ghế 4dx': 200000,
    'ghế lamour': 180000,
    'default': 100000,
  };

  // Getters
  ShowtimeSeats? get showtimeSeats => _showtimeSeats;
  List<Seat> get selectedSeats => _selectedSeats;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  String get sessionId => _sessionId;
  
  // Lấy giá ghế dựa trên loại ghế (dùng khi không có price_id hoặc không thể lấy giá từ API)
  double getDefaultPrice(String seatType) {
    final type = seatType.toLowerCase();
    return _defaultPrices[type] ?? _defaultPrices['default']!;
  }
  
  // Lấy tổng số tiền cho ghế đã chọn
  double get totalAmount {
    return _selectedSeats.fold(0, (sum, seat) {
      // Sử dụng giá mặc định nếu actualPrice là null
      final price = seat.actualPrice ?? getDefaultPrice(seat.seatType);
      return sum + price;
    });
  }
  
  // Lấy thông tin ghế theo hàng
  Map<String, List<Seat>> get seatsByRow {
    return _showtimeSeats?.seatsByRow ?? {};
  }

  // Lấy danh sách ghế theo suất chiếu
  Future<void> loadSeats(int showtimeId) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      // Tải dữ liệu ghế 
      _showtimeSeats = await _seatService.getSeatsByShowtime(showtimeId);
      
      // Tải dữ liệu giá ghế nếu chưa có trong cache
      await _loadSeatPrices();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Không thể tải thông tin ghế: $e';
      notifyListeners();
    }
  }

  // Tải dữ liệu giá ghế
  Future<void> _loadSeatPrices() async {
    try {
      // Nếu cache trống, tải tất cả giá ghế
      if (_seatPrices.isEmpty) {
        final prices = await _seatService.getAllSeatPrices();
        for (var price in prices) {
          _seatPrices[price.priceId] = price;
        }
      }
    } catch (e) {
      print('Lỗi khi tải giá ghế: $e');
      // Không báo lỗi cho người dùng, chỉ log và tiếp tục sử dụng giá mặc định
    }
  }

  // Lấy giá ghế từ price_id
  Future<double> getPriceFromPriceId(int? priceId, String seatType) async {
    // Nếu không có price_id, sử dụng giá mặc định
    if (priceId == null) {
      return getDefaultPrice(seatType);
    }

    // Nếu đã có trong cache, sử dụng giá từ cache
    if (_seatPrices.containsKey(priceId)) {
      return _seatPrices[priceId]!.price;
    }

    // Nếu chưa có trong cache, tải từ API
    try {
      final seatPrice = await _seatService.getSeatPrice(priceId);
      _seatPrices[priceId] = seatPrice; // Cập nhật cache
      return seatPrice.price;
    } catch (e) {
      print('Lỗi khi lấy giá ghế từ API: $e');
      return getDefaultPrice(seatType); // Sử dụng giá mặc định nếu không lấy được từ API
    }
  }

  // Chọn hoặc bỏ chọn ghế
  void toggleSeatSelection(Seat seat) async {
    if (!seat.isAvailable || seat.isLocked) {
      return; // Không thể chọn ghế đã đặt hoặc đang khóa
    }

    // Giới hạn số lượng ghế có thể chọn (ví dụ: tối đa 8 ghế)
    if (_selectedSeats.length >= 8 && !_selectedSeats.any((s) => s.seatId == seat.seatId)) {
      _hasError = true;
      _errorMessage = 'Bạn chỉ có thể chọn tối đa 8 ghế';
      notifyListeners();
      return;
    }

    // Xử lý chọn/bỏ chọn ghế đã chọn
    if (_selectedSeats.any((s) => s.seatId == seat.seatId)) {
      _selectedSeats.removeWhere((s) => s.seatId == seat.seatId);
    } else {
      try {
        // Lấy giá ghế từ API mới
        print('Đang lấy giá cho ghế ID: ${seat.seatId}');
        final seatPriceData = await _seatService.getSeatPriceById(seat.seatId);
        print('Dữ liệu giá ghế nhận được: $seatPriceData');
        
        // Chuyển đổi giá an toàn
        double actualPrice = 0;
        if (seatPriceData.containsKey('price')) {
          var priceValue = seatPriceData['price'];
          if (priceValue is int) {
            actualPrice = priceValue.toDouble();
          } else if (priceValue is double) {
            actualPrice = priceValue;
          } else if (priceValue is String) {
            try {
              actualPrice = double.parse(priceValue);
            } catch (e) {
              print('Không thể chuyển đổi giá từ string: $priceValue');
              actualPrice = getDefaultPrice(seat.seatType);
            }
          } else {
            print('Kiểu dữ liệu giá không hỗ trợ: ${priceValue.runtimeType}');
            actualPrice = getDefaultPrice(seat.seatType);
          }
        } else {
          print('Không tìm thấy key "price" trong dữ liệu API');
          actualPrice = getDefaultPrice(seat.seatType);
        }
        
        // Tạo bản sao ghế với giá và trạng thái chọn
        final seatWithPrice = seat.copyWith(
          isSelected: true,
          actualPrice: actualPrice,
        );
        
        _selectedSeats.add(seatWithPrice);
        
        print('Ghế ${seat.seatName} có giá: ${actualPrice.toStringAsFixed(0)} VND');
      } catch (e) {
        print('Lỗi khi lấy giá ghế: $e');
        // Sử dụng giá mặc định nếu không lấy được từ API
        double defaultPrice = getDefaultPrice(seat.seatType);
        
        final seatWithPrice = seat.copyWith(
          isSelected: true,
          actualPrice: defaultPrice,
        );
        
        _selectedSeats.add(seatWithPrice);
        print('Sử dụng giá mặc định cho ghế ${seat.seatName}: ${defaultPrice.toStringAsFixed(0)} VND');
      }
    }

    // Cập nhật trạng thái isSelected trong danh sách ghế
    if (_showtimeSeats != null) {
      final updatedSeats = _showtimeSeats!.seats.map((s) {
        if (s.seatId == seat.seatId) {
          return s.copyWith(isSelected: !s.isSelected);
        }
        return s;
      }).toList();

      // Cập nhật trạng thái isSelected trong seatsByRow
      final updatedSeatsByRow = Map<String, List<Seat>>.from(_showtimeSeats!.seatsByRow);
      updatedSeatsByRow.forEach((rowKey, seats) {
        final updatedRowSeats = seats.map((s) {
          if (s.seatId == seat.seatId) {
            return s.copyWith(isSelected: !s.isSelected);
          }
          return s;
        }).toList();
        updatedSeatsByRow[rowKey] = updatedRowSeats;
      });

      _showtimeSeats = ShowtimeSeats(
        showtime: _showtimeSeats!.showtime,
        seatsSummary: _showtimeSeats!.seatsSummary,
        seatsByRow: updatedSeatsByRow,
        seats: updatedSeats,
      );
    }

    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }

  // Khóa ghế tạm thời
  Future<bool> lockSelectedSeats(int showtimeId) async {
    if (_selectedSeats.isEmpty) {
      _hasError = true;
      _errorMessage = 'Vui lòng chọn ít nhất một ghế';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final List<int> seatIds = _selectedSeats.map((seat) => seat.seatId).toList();
      await _seatService.lockSeats(showtimeId, seatIds, _sessionId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Không thể khóa ghế: $e';
      notifyListeners();
      return false;
    }
  }

  // Giải phóng ghế đã khóa
  Future<void> unlockSeats(int showtimeId) async {
    if (_selectedSeats.isEmpty) return;

    try {
      final List<int> seatIds = _selectedSeats.map((seat) => seat.seatId).toList();
      await _seatService.unlockSeats(showtimeId, seatIds, _sessionId);
      
      // Reset trạng thái
      _selectedSeats = [];
      await loadSeats(showtimeId); // Tải lại danh sách ghế
    } catch (e) {
      print('Lỗi giải phóng ghế: $e');
    }
  }

  // Xóa toàn bộ trạng thái
  void reset() {
    _showtimeSeats = null;
    _selectedSeats = [];
    _isLoading = false;
    _hasError = false;
    _errorMessage = '';
    _sessionId = const Uuid().v4(); // Tạo ID phiên mới
    // Không xóa cache giá ghế để có thể tái sử dụng
    notifyListeners();
  }
}