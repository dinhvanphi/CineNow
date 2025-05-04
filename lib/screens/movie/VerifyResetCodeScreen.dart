import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/AppConfig.dart';
import 'ResetPasswordScreen.dart';

class VerifyResetCodeScreen extends StatefulWidget {
  final String email;
  
  const VerifyResetCodeScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen> {
  final _otpController = TextEditingController();
  Timer? _timer;
  int _remainingTime = 60;
  bool _isVerifying = false;
  bool _isResending = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingTime = 60;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime <= 0) {
        timer.cancel();
      } else {
        setState(() {
          _remainingTime--;
        });
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length < 6) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đủ 6 chữ số OTP';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      print('Verifying OTP: ${_otpController.text} for email: ${widget.email}');
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'token': _otpController.text,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      setState(() {
        _isVerifying = false;
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;

        // Chuyển đến màn hình đặt lại mật khẩu
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              email: widget.email,
              token: _otpController.text,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Mã OTP không đúng';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Lỗi kết nối: $e';
      });
    }
  }

  Future<void> _resendOTP() async {
    if (_isResending || _remainingTime > 0) {
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    try {
      print('Resending OTP for email: ${widget.email}');
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/resend-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      setState(() {
        _isResending = false;
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;

        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mã OTP mới đã được gửi đến email của bạn'),
            backgroundColor: Colors.green,
          ),
        );

        // Khởi động lại bộ đếm thời gian
        _startTimer();
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Không thể gửi lại mã OTP';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isResending = false;
        _errorMessage = 'Lỗi kết nối: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Xác nhận mã OTP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Text(
                'Xác nhận mã OTP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Vui lòng nhập mã OTP 6 chữ số vừa được gửi đến ${widget.email}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 40.h),
              
              // OTP input field
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                backgroundColor: Colors.transparent,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10.r),
                  fieldHeight: 50.h,
                  fieldWidth: 45.w,
                  activeFillColor: Colors.grey[900],
                  inactiveFillColor: Colors.grey[900],
                  selectedFillColor: Colors.grey[800],
                  activeColor: Colors.amber,
                  inactiveColor: Colors.grey[700],
                  selectedColor: Colors.amber,
                ),
                textStyle: TextStyle(fontSize: 20.sp, color: Colors.white),
                enableActiveFill: true,
                onChanged: (value) {
                  // Xóa thông báo lỗi khi người dùng nhập mã mới
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
                  }
                },
                beforeTextPaste: (text) {
                  // Validate text bằng regex chỉ cho phép số
                  return RegExp(r'^\d+$').hasMatch(text ?? '');
                },
              ),
              
              // Error message
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 15.h),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              
              SizedBox(height: 30.h),
              
              // Resend OTP button and timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Không nhận được mã OTP? ',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14.sp,
                    ),
                  ),
                  _remainingTime > 0
                      ? Text(
                          'Gửi lại sau $_remainingTime giây',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 14.sp,
                          ),
                        )
                      : TextButton(
                          onPressed: _isResending ? null : _resendOTP,
                          child: _isResending
                              ? SizedBox(
                                  width: 12.w,
                                  height: 12.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                                  ),
                                )
                              : Text(
                                  'Gửi lại',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                        ),
                ],
              ),
              
              SizedBox(height: 40.h),
              
              // Verify button
              Container(
                width: double.infinity,
                height: 55.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                  ),
                  child: _isVerifying
                      ? CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'Xác nhận',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}