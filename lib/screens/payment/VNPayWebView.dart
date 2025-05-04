// lib/screens/VNPayWebView.dart

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'QuickSaveTicket.dart';
import 'PaymentResultScreen.dart';

class VNPayWebView extends StatefulWidget {
  final String paymentUrl;
  final Function(bool success, String? orderCode) onPaymentComplete;

  const VNPayWebView({
    Key? key, 
    required this.paymentUrl,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  _VNPayWebViewState createState() => _VNPayWebViewState();
}

class _VNPayWebViewState extends State<VNPayWebView> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize WebViewController
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('VNPay WebView started loading: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            print('VNPay WebView finished loading: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('VNPay WebView navigation request: ${request.url}');
            
            // Kiểm tra nếu URL chứa thông tin kết quả thanh toán
            if (request.url.contains('vnp_ResponseCode=')) {
              _handlePaymentCallback(request.url);
              return NavigationDecision.prevent;
            }
            
            // Bắt Deep Link khi quay lại ứng dụng
            if (request.url.startsWith('cinenow://payment/vnpay')) {
              // Xử lý kết quả thanh toán từ URL
              Uri uri = Uri.parse(request.url);
              String result = uri.queryParameters['result'] ?? '';
              String orderCode = uri.queryParameters['orderCode'] ?? '';
              
              // Thông báo kết quả
              widget.onPaymentComplete(result == '00', orderCode);
              
              // Đóng WebView
              Navigator.of(context).pop();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('VNPay WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
      
    print('Loading VNPay URL: ${widget.paymentUrl}');
  }
  
  // Xử lý kết quả thanh toán từ callback URL
  void _handlePaymentCallback(String url) {
    print('Processing payment callback: $url');
    
    try {
      final uri = Uri.parse(url);
      
      // Lấy tất cả các tham số từ URL và chuyển thành Map<String, String>
      Map<String, String> allParams = {};
      uri.queryParameters.forEach((key, value) {
        allParams[key] = value;
        print('Param: $key = $value');
      });
      
      final responseCode = allParams['vnp_ResponseCode'] ?? '';
      final txnRef = allParams['vnp_TxnRef'] ?? '';
      
      print('Response code: $responseCode, TxnRef: $txnRef');
      print('VNPay thanh toán thành công: $allParams');
      
      // THAY ĐỔI: thay vì gọi callback, chuyển đến QuickSaveTicket
      if (responseCode == '00') {
        print('Thanh toán VNPay thành công với params: $allParams');
        
        // Thay đổi: Chuyển đến màn hình QuickSaveTicket 
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => QuickSaveTicket(paymentParams: allParams),
          ),
        );
      } else {
        // Nếu không thành công, vẫn sử dụng callback và đóng
        widget.onPaymentComplete(false, txnRef);
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error processing payment callback: $e');
      // Xử lý lỗi - trả về thất bại
      widget.onPaymentComplete(false, null);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán VNPay'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Khi người dùng đóng WebView thì coi như thanh toán thất bại
            widget.onPaymentComplete(false, null);
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}