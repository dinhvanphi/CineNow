import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'Signup.dart';
import 'services/UserService.dart';
import 'services/AuthService.dart';
import 'HomePage.dart';
import 'screens/movie/ForgotPasswordScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSocialLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Xác thực form
  bool _validateForm() {
    if (_emailController.text.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập email hoặc số điện thoại');
      return false;
    }
    
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mật khẩu');
      return false;
    }
    
    setState(() => _errorMessage = '');
    return true;
  }
  
  // Xử lý đăng nhập
  Future<void> _login() async {
    if (!_validateForm()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final user = await _userService.login(
        _emailController.text,
        _passwordController.text,
      );
      
      setState(() => _isLoading = false);
      
      if (user == null) {
        setState(() => _errorMessage = 'Email/số điện thoại hoặc mật khẩu không đúng');
        return;
      }
      
      // Đăng nhập thành công - chuyển đến màn hình HomePage
      if (mounted) {
        // Hiển thị thông báo đăng nhập thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thành công! Chào mừng ${user.fullName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Chuyển hướng đến HomePage và xóa stack điều hướng để người dùng không quay lại màn hình đăng nhập khi nhấn nút Back
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi đăng nhập: ${e.toString()}';
      });
    }
  }

  // Đăng nhập bằng Google
  Future<void> _signInWithGoogle() async {
    try {
      setState(() {
        _isSocialLoading = true;
        _errorMessage = '';
      });

      final user = await _authService.signInWithGoogle();
      
      setState(() => _isSocialLoading = false);
      
      if (user == null) {
        // Người dùng hủy đăng nhập
        return;
      }
      
      // Đăng nhập thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập Google thành công! Chào mừng ${user.fullName}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _isSocialLoading = false;
        _errorMessage = 'Lỗi đăng nhập Google: ${e.toString()}';
      });
    }
  }

  // // Đăng nhập bằng Facebook
  // Future<void> _signInWithFacebook() async {
  //   try {
  //     setState(() {
  //       _isSocialLoading = true;
  //       _errorMessage = '';
  //     });

  //     final user = await _authService.signInWithFacebook();
      
  //     setState(() => _isSocialLoading = false);
      
  //     if (user == null) {
  //       // Người dùng hủy đăng nhập
  //       return;
  //     }
      
  //     // Đăng nhập thành công
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Đăng nhập Facebook thành công! Chào mừng ${user.fullName}'),
  //           backgroundColor: Colors.green,
  //           duration: const Duration(seconds: 2),
  //         ),
  //       );
        
  //       Navigator.of(context).pushAndRemoveUntil(
  //         MaterialPageRoute(builder: (context) => const HomePage()),
  //         (route) => false,
  //       );
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _isSocialLoading = false;
  //       _errorMessage = 'Lỗi đăng nhập Facebook: ${e.toString()}';
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  
                  // Logo và tiêu đề
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.movie_outlined,
                          size: 60.sp,
                          color: Colors.amber,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          "CineNow",
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 50.h),
                  
                  // Tiêu đề đăng nhập
                  Text(
                    "Đăng Nhập",
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  
                  SizedBox(height: 16.h),
                  Text(
                    "Vui lòng đăng nhập để tiếp tục",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey,
                    ),
                  ),
                  
                  // Hiển thị lỗi nếu có
                  if (_errorMessage.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 20.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 30.h),
                  
                  // Form đăng nhập
                  // Email/Số điện thoại
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Email hoặc số điện thoại',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      prefixIcon: const Icon(Icons.email, color: Colors.amber),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Mật khẩu
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Mật khẩu',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      prefixIcon: const Icon(Icons.lock, color: Colors.amber),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword 
                              ? Icons.visibility_off 
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                    ),
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Quên mật khẩu
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Chuyển đến màn hình quên mật khẩu
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Quên mật khẩu?",
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 30.h),
                  
                  // Nút đăng nhập
                  _isLoading 
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          minimumSize: Size(double.infinity, 50.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 5,
                          shadowColor: Colors.amberAccent.withOpacity(0.5),
                        ),
                        child: Text(
                          "Đăng Nhập",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  
                  SizedBox(height: 30.h),
                  
                  // Hoặc đăng nhập với
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey[800], thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          "Hoặc đăng nhập với",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Colors.grey[800], thickness: 1),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Đăng nhập bằng Google/Facebook
                  _isSocialLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google
                          socialLoginButton(
                            icon: Icons.g_mobiledata,
                            label: "Google",
                            onPressed: _signInWithGoogle,
                          ),
                          
                          SizedBox(width: 16.w),
                          
                          // Facebook
                          // socialLoginButton(
                          //   icon: Icons.facebook,
                          //   label: "Facebook",
                          //   // onPressed: _signInWithFacebook,
                          // ),
                        ],
                      ),
                  
                  SizedBox(height: 30.h),
                  
                  // Chưa có tài khoản? Đăng ký
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Chưa có tài khoản? ",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.sp,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupScreen()),
                            );
                          },
                          child: Text(
                            "Đăng ký",
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget socialLoginButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: TextStyle(color: Colors.white)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[900],
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: BorderSide(color: Colors.grey[800]!),
          ),
        ),
      ),
    );
  }
} 