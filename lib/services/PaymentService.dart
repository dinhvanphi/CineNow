// lib/services/PaymentService.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:vnpay_flutter/vnpay_flutter.dart';
import 'package:crypto/crypto.dart' as crypto;
import '../config/AppConfig.dart';
import '../screens/payment/VNPayWebView.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  final String baseUrl = AppConfig.apiBaseUrl;

  // Phương thức cũ sử dụng API server-side
  Future<Map<String, dynamic>> createVNPayPayment({
    required double amount,
    required String orderCode,
    required String orderInfo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/payment/vnpay/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'orderCode': orderCode,
          'orderInfo': orderInfo,
          'ipAddr':'127.0.0.1',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Lỗi tạo thanh toán: ${response.body}');
      }
    } catch (e) {
      print('Lỗi khi tạo thanh toán VNPay: $e');
      throw Exception('Không thể kết nối đến server thanh toán');
    }
  }

  // Định dạng ngày giờ theo chuẩn VNPay yêu cầu (yyyyMMddHHmmss)
  String formatDateTime(DateTime dt) {
    return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}';
  }

  // Phương thức mới sử dụng VNPAYFlutter package
  Future<void> processVNPayFlutterPayment({
    required BuildContext context,
    required double amount,
    required String orderInfo,
    required String movieTitle,
    required int bookingId,
    required Function(Map<String, dynamic>) onSuccess,
    required Function(Map<String, dynamic>) onError,
  }) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String orderCode = 'CINENOW${bookingId}_$timestamp';
      
      print('Tạo giao dịch VNPay với: $orderCode, $orderInfo, ${amount.toStringAsFixed(0)} VND');
      
      // Tạo ngày hết hạn cho thanh toán VNPay (15 phút từ hiện tại)
      final DateTime now = DateTime.now();
      
      // Thay vì sử dụng generatePaymentUrl, chúng ta tự tạo URL để có thể kiểm soát được các tham số
      // Cấu trúc URL cơ bản
      final Uri baseUri = Uri.parse('https://sandbox.vnpayment.vn/paymentv2/vpcpay.html');
      
      // Tham số thanh toán - đúng thứ tự theo tài liệu VNPay
      final Map<String, String> params = {
        'vnp_Version': '2.1.0',
        'vnp_Command': 'pay',
        'vnp_TmnCode': 'X86Y3DHE',  // Terminal ID từ email VNPay
        'vnp_Locale': 'vn',
        'vnp_CurrCode': 'VND',
        'vnp_TxnRef': orderCode,
        'vnp_OrderInfo': 'thanh toán cho đơn hàng', // Siêu đơn giản hóa để test
        'vnp_OrderType': 'other',  // Dùng 'other' theo tài liệu VNPay
        'vnp_Amount': (amount * 100).toInt().toString(),  // Nhân 100 và chuyển sang kiểu int
        'vnp_ReturnUrl': 'cinenow://payment/vnpay',
        'vnp_IpAddr': '127.0.0.1',
        'vnp_CreateDate': formatDateTime(now),
        // Theo tài liệu v2.1.0 cần truyền kèm loại hash trong URL (loại HmacSHA512)
        // Lưu ý: tham số này KHÔNG được đưa vào dữ liệu ký (hashData)
        'vnp_SecureHashType': 'HmacSHA512',
      };
      
      // B1: Sort và encode các tham số
      // Tạo danh sách key dùng để ký: loại bỏ vnp_SecureHash và vnp_SecureHashType
      final List<String> sortedKeysForHash = params.keys
          .where((k) => k != 'vnp_SecureHash' && k != 'vnp_SecureHashType')
          .toList()
        ..sort();
      
      // Và danh sách key cho URL (bao gồm cả vnp_SecureHashType, ngoại trừ vnp_SecureHash)
      final List<String> sortedKeysForUrl = params.keys
          .where((k) => k != 'vnp_SecureHash')
          .toList()
        ..sort();
      
      // Tạo map đã encode value theo chuẩn VNPay (encodeURIComponent và thay %20 bằng +)
      String encodeVNPayValue(String value) => Uri.encodeComponent(value).replaceAll('%20', '+');
      final Map<String, String> encodedParams = {
        for (final entry in params.entries) entry.key: encodeVNPayValue(entry.value)
      };
      
      // B2: Tạo chuỗi hashData từ các key dùng để ký
      final StringBuffer hashData = StringBuffer();
      bool firstParam = true;
      for (String key in sortedKeysForHash) {
        if (!firstParam) {
          hashData.write('&');
        } else {
          firstParam = false;
        }
        hashData.write('$key=${encodedParams[key]}');
      }
      
      print('=====>[RAW HASH DATA]: ${hashData.toString()}'); // Log dữ liệu trước khi hash
      
      // B3: Tạo chữ ký HMAC-SHA512 theo đúng cách VNPay yêu cầu
      final String secret = dotenv.env['VNPAY_HASH_SECRET'] ?? '';
      final key = utf8.encode(secret);
      final bytes = utf8.encode(hashData.toString());
      final hmacSha512 = crypto.Hmac(crypto.sha512, key);
      final digest = hmacSha512.convert(bytes);
      // Chuyển đổi digest thành chuỗi hex và viết hoa
      final hash = digest.bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('').toUpperCase();
      print('=====>[FINAL HASH]: $hash'); // Log hash cuối cùng
      
      // B4: Tạo URL với các tham số (đã được encode trong encodedParams)
      final StringBuffer queryBuilder = StringBuffer(baseUri.toString());
      queryBuilder.write('?');
      
      // Thêm các tham số đã được encode (bao gồm vnp_SecureHashType)
      bool firstUrlParam = true;
      for (String key in sortedKeysForUrl) {
        if (!firstUrlParam) {
          queryBuilder.write('&');
        } else {
          firstUrlParam = false;
        }
        queryBuilder.write('$key=${encodedParams[key]}');
      }
      
      // Thêm chữ ký vào URL
      queryBuilder.write('&vnp_SecureHash=$hash');
      final String paymentUrl = queryBuilder.toString();
      
      print('=====>[PAYMENT URL]: $paymentUrl');
      print('=====>[HASH DATA]: ${hashData.toString()}');
      
      // Sử dụng VNPayWebView để hiển thị URL thanh toán (thay vì sử dụng VNPAYFlutter.show)
      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => VNPayWebView(
            paymentUrl: paymentUrl,
            onPaymentComplete: (success, orderCode) {
              // Tạo map cho kết quả thanh toán tương tự với kết quả trả về từ VNPay
              final Map<String, String> resultParams = {
                'vnp_ResponseCode': success ? '00' : '24',
                'vnp_TxnRef': orderCode ?? '',
                'vnp_Amount': (amount * 100).toString(),
                'vnp_OrderInfo': 'thanh toán cho đơn hàng', // Đồng bộ với params
                'vnp_PayDate': DateTime.now().toString(),
              };
              
              if (success) {
                print('VNPay thanh toán thành công: $resultParams');
                onSuccess(resultParams);
              } else {
                print('VNPay thanh toán thất bại: $resultParams');
                onError(resultParams);
              }
            },
          ),
        ),
      );
    } catch (e) {
      print('Lỗi khi tạo thanh toán VNPay Flutter: $e');
      throw Exception('Không thể kết nối đến server thanh toán');
    }
  }
}