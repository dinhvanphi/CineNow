import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'Login.dart';
import 'Signup.dart';
import 'HomePage.dart';
import 'services/UserService.dart';

class IntroView extends StatefulWidget {
  const IntroView({super.key});
  
  @override
  State<IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<IntroView> with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkLogin();
    
    // Thêm animation
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkLogin() async {
    try {
      final isLoggedIn = await _userService.isLoggedIn();
      
      setState(() {
        _isLoading = false;
      });
      
      if (isLoggedIn && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      print('Lỗi kiểm tra đăng nhập: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.amber,
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  // Phần đầu trang (Logo + Ngôn ngữ)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "CineNow",
                          style: TextStyle(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.amberAccent.withOpacity(0.5),
                                blurRadius: 5,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: Colors.amber.withOpacity(0.7), width: 1),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.language, color: Colors.white, size: 18),
                            label: const Text("Tiếng Việt", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Logo và phần chính
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    child: Container(
                      width: 320.w,
                      height: 350.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25.r),
                        color: Color(0xFF151515),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 1,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25.r),
                        child: Stack(
                          children: [
                            // Background overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25.r),
                                  border: Border.all(
                                    color: Colors.amber.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Logo content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.amber.withOpacity(0.3),
                                          blurRadius: 25,
                                          spreadRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/image/Logo.png',
                                      width: 200.sp,
                                      height: 200.sp,
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

                  // Nội dung chào mừng
                  Text(
                    "Chào mừng đến với CineNow!",
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Thưởng thức những bộ phim yêu thích của bạn",
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[300],
                      letterSpacing: 0.3,
                    ),
                  ),
                  
                  // Chỉ báo trang (Dot Indicator)
                  // Padding(
                  //   padding: EdgeInsets.symmetric(vertical: 15.h),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       buildDot(true),
                  //       buildDot(false),
                  //       buildDot(false),
                  //     ],
                  //   ),
                  // ),

                  // Thêm Expanded để đẩy nút xuống
                  SizedBox(height: 25.h),
                  
                  // Nút Đăng nhập và Đăng ký
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 25.w),
                    child: Column(
                      children: [
                        // Nút Đăng nhập (Primary)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              minimumSize: Size(double.infinity, 55.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Đăng nhập",
                              style: TextStyle(
                                fontSize: 18.sp, 
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 15.h),
                        // Nút Đăng ký (Secondary)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 5,
                                spreadRadius: 1,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SignupScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              minimumSize: Size(double.infinity, 55.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                                side: BorderSide(color: Colors.amber, width: 2),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Đăng ký",
                              style: TextStyle(
                                fontSize: 18.sp, 
                                color: Colors.amber,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Điều khoản dịch vụ
                  Padding(
                    padding: EdgeInsets.only(top: 20.h, bottom: 8.h, left: 25.w, right: 25.w),
                    child: Text(
                      "Bằng cách đăng nhập hoặc đăng ký, bạn đồng ý với Điều khoản dịch vụ và Chính sách bảo mật của chúng tôi",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[400],
                        height: 1.5,
                      ),
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

  Widget buildDot(bool isActive) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      width: isActive ? 25.w : 10.w,
      height: 10.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.r),
        color: isActive ? Colors.amber : Colors.grey.withOpacity(0.5),
        boxShadow: isActive ? [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          )
        ] : null,
      ),
    );
  }
}
