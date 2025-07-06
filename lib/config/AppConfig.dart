import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode;

class AppConfig {
  // API URLs
  static String get apiBaseUrl {
    if (kDebugMode) {
      if (Platform.isAndroid) {
        // Sử dụng ngrok URL cho thiết bị Android khi debug
        return 'https://e650-103-156-46-86.ngrok-free.app';
      } else if (Platform.isIOS) {
        // Sử dụng ngrok URL cho thiết bị iOS khi debug
        return 'https://e650-103-156-46-86.ngrok-free.app';
      }
    }
    // Đường dẫn production hoặc debug trên thiết bị thật
    return 'https://e650-103-156-46-86.ngrok-free.app';
  }
  
  // URL thanh toán VNPay
  static const String vnpayApiUrl = 'https://e650-103-156-46-86.ngrok-free.app';
  static const String vnpayReturnUrl = vnpayApiUrl + '/api/payment/vnpay/return';

  // API Endpoints
  static const String registerEndpoint = '/api/register';
  static const String verifyAccountEndpoint = '/api/verify-account';
  static const String resendOtpEndpoint = '/api/resend-otp';
  static const String loginEndpoint = '/api/login';
  static const String userEndpoint = '/api/users';
  
  // OAuth Endpoints
  static const String googleAuthEndpoint = '/api/auth/google';
  static const String facebookAuthEndpoint = '/api/auth/facebook';
  
  // OTP Settings
  static const int otpExpiryMinutes = 10;
  static const int maxSeatsPerBooking = 8;
} 