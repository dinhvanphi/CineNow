import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

class AppConfig {
  // API URLs
  static String get apiBaseUrl {
    // On web, Platform from dart:io is unsupported; use kIsWeb instead
    if (kIsWeb) {
      return 'https://fe4a72bfae8b.ngrok-free.app';
    }
    if (kDebugMode) {
      // Debug base URL for non-web platforms
      return 'https://fe4a72bfae8b.ngrok-free.app';
    }
    // Production base URL (update when deploying)
    return 'https://fe4a72bfae8b.ngrok-free.app';
  }
  
  // URL thanh toán VNPay
  static String get vnpayApiUrl => apiBaseUrl;
  static String get vnpayReturnUrl => '$vnpayApiUrl/api/payment/vnpay/return';

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