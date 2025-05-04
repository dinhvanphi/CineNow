class ApiConstants {
  // URL cơ sở cho tất cả các API calls 
  // Thay đổi URL này khi chuyển từ môi trường phát triển sang staging hoặc production
  
  // Sử dụng địa chỉ IP thay vì localhost để iOS có thể kết nối
  // static const String baseUrl = 'http://10.0.2.2:3000'; // Cho Android Emulator
  static const String baseUrl = 'http://127.0.0.1:3000'; // Cho iOS Simulator
  
  // Số lượng tối đa ghế có thể chọn cùng lúc
  static const int maxSeatsPerBooking = 8;
  
  // Thời gian khóa ghế tạm thời (phút)
  static const int lockSeatDurationMinutes = 10;
  
  // In URL trong quá trình phát triển
  static void printBaseUrl() {
    print('===== API Base URL =====');
    print('Using API URL: $baseUrl');
    print('=======================');
  }
} 