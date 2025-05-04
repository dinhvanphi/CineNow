import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'IntroView.dart';
import 'services/UserService.dart';
import 'services/MovieService.dart';
import 'models/User.dart';
import 'models/Movie.dart';
import 'screens/movie/MovieDetailScreen.dart';
import 'screens/movie/MovieListScreen.dart';
import 'screens/movie/MovieSearchScreen.dart';
import 'screens/user/UserProfileScreen.dart';
import 'screens/ticket/MyTicketScreen.dart';
import 'screens/payment/DirectTicketCreationScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentBanner = 0;
  final UserService _userService = UserService();
  final MovieService _movieService = MovieService();
  User? _currentUser;
  bool _isLoading = true;
  
  // Dữ liệu phim từ API
  List<Movie> _featuredMovies = [];
  List<Movie> _nowShowingMovies = [];
  List<Movie> _comingSoonMovies = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  // Tải tất cả dữ liệu cần thiết
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Tải song song cả thông tin người dùng và dữ liệu phim
      final results = await Future.wait([
        _userService.getCurrentUser(),
        _movieService.getFeaturedMovies(),
        _movieService.getNowShowingMovies(),
        _movieService.getComingSoonMovies(),
      ]);
      
      if (mounted) {
        setState(() {
          _currentUser = results[0] as User?;
          _featuredMovies = results[1] as List<Movie>;
          _nowShowingMovies = results[2] as List<Movie>;
          _comingSoonMovies = results[3] as List<Movie>;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Lỗi tải dữ liệu: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Xử lý đăng xuất
  Future<void> _logout() async {
    try {
      await _userService.logout();
      
      // Chuyển về màn hình intro
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const IntroView()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Lỗi đăng xuất: $e');
      
      // Hiển thị thông báo lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng xuất: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hiển thị loading trong khi tải dữ liệu
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.amber,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                SizedBox(height: 10.h),
                _buildBannerSlider(),
                SizedBox(height: 20.h),
                _buildNowShowingSection(),
                SizedBox(height: 20.h),
                _buildComingSoonSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAppBar() {
    // Lấy chữ cái đầu tiên của tên người dùng để hiển thị trong avatar
    String avatarText = _currentUser?.fullName.isNotEmpty == true
        ? _currentUser!.fullName[0].toUpperCase()
        : "?";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "CineNow",
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MovieSearchScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.search, color: Colors.white),
              ),
              GestureDetector(
                onTap: () {
                  // Hiển thị menu người dùng khi nhấn vào avatar
                  _showUserMenu(context);
                },
                child: CircleAvatar(
                  radius: 15.r,
                  backgroundColor: Colors.amber,
                  child: Text(
                    avatarText,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Hiển thị menu người dùng
  Future<void> _showUserMenu(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar và tên người dùng
              CircleAvatar(
                radius: 40.r,
                backgroundColor: Colors.amber,
                child: Text(
                  _currentUser?.fullName?.isNotEmpty == true
                      ? _currentUser!.fullName![0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                _currentUser?.fullName ?? 'Người dùng',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                _currentUser?.email ?? '',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 20.h),
              const Divider(color: Colors.grey),
              
              // Danh sách các tùy chọn menu
              ListTile(
                leading: Icon(Icons.person, color: Colors.amber),
                title: Text(
                  'Thông tin tài khoản',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(),
                    ),
                  );
                },
              ),
              
              ListTile(
                leading: Icon(Icons.confirmation_number, color: Colors.amber),
                title: Text(
                  'Vé của tôi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyTicketScreen(),
                    ),
                  );
                },
              ),
              
              // Thêm tùy chọn tạo vé thủ công từ thông tin thanh toán VNPay
              ListTile(
                leading: Icon(Icons.add_circle, color: Colors.green),
                title: Text(
                  'Tạo vé từ giao dịch VNPay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                ),
                subtitle: Text(
                  'Dùng khi thanh toán thành công nhưng không thấy vé',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12.sp,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DirectTicketCreationScreen(),
                    ),
                  );
                },
              ),
              
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'Đăng xuất',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildBannerSlider() {
    // Nếu không có phim nổi bật, hiển thị banner trống
    if (_featuredMovies.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Text(
            "Không có phim nổi bật",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16.sp,
            ),
          ),
        ),
      );
    }
    
    return Column(
      children: [
        SizedBox(
          height: 200.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _featuredMovies.length,
            onPageChanged: (index) {
              setState(() {
                _currentBanner = index;
              });
            },
            itemBuilder: (context, index) {
              final movie = _featuredMovies[index];
              
              return GestureDetector(
                onTap: () {
                  // Chuyển đến trang chi tiết phim
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailScreen(movie: movie),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15.r),
                    image: DecorationImage(
                      image: NetworkImage(movie.image),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {
                        // Xử lý lỗi khi tải hình ảnh
                        print('Lỗi tải hình ảnh: $exception');
                      },
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.r),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(15.r),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Row(
                            children: [
                              if (movie.rating != null) ...[
                                Icon(Icons.star, color: Colors.amber, size: 16.sp),
                                SizedBox(width: 5.w),
                                Text(
                                  movie.rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(width: 15.w),
                              ],
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: Chuyển đến trang đặt vé
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
                                ),
                                child: Text(
                                  "Đặt vé",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _featuredMovies.length,
            (index) => Container(
              width: 8.w,
              height: 8.h,
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentBanner == index ? Colors.amber : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNowShowingSection() {
    // Nếu không có phim đang chiếu, hiển thị thông báo
    if (_nowShowingMovies.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16.r),
        child: Center(
          child: Text(
            "Không có phim đang chiếu",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16.sp,
            ),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Đang chiếu",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Chuyển đến trang danh sách phim đang chiếu
                },
                child: Text(
                  "Xem tất cả",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 260.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            scrollDirection: Axis.horizontal,
            itemCount: _nowShowingMovies.length,
            itemBuilder: (context, index) {
              final movie = _nowShowingMovies[index];
              
              return GestureDetector(
                onTap: () {
                  // Chuyển đến trang chi tiết phim
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailScreen(movie: movie),
                    ),
                  );
                },
                child: Container(
                  width: 150.w,
                  margin: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 200.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          image: DecorationImage(
                            image: NetworkImage(movie.image),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              // Xử lý lỗi khi tải hình ảnh
                              print('Lỗi tải hình ảnh: $exception');
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        movie.title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14.sp),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              movie.rating != null ? movie.rating!.toStringAsFixed(1) : "N/A",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComingSoonSection() {
    // Nếu không có phim sắp chiếu, hiển thị thông báo
    if (_comingSoonMovies.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16.r),
        child: Center(
          child: Text(
            "Không có phim sắp chiếu",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16.sp,
            ),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sắp chiếu",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Chuyển đến trang danh sách phim sắp chiếu
                },
                child: Text(
                  "Xem tất cả",
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          height: 280.h,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            scrollDirection: Axis.horizontal,
            itemCount: _comingSoonMovies.length,
            itemBuilder: (context, index) {
              final movie = _comingSoonMovies[index];
              
              return GestureDetector(
                onTap: () {
                  // Chuyển đến trang chi tiết phim
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailScreen(movie: movie),
                    ),
                  );
                },
                child: Container(
                  width: 150.w,
                  margin: EdgeInsets.symmetric(horizontal: 5.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 200.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.r),
                              image: DecorationImage(
                                image: NetworkImage(movie.image),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  // Xử lý lỗi khi tải hình ảnh
                                  print('Lỗi tải hình ảnh: $exception');
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 5.h,
                            right: 5.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(5.r),
                              ),
                              child: Text(
                                "Sắp chiếu",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        movie.title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey, size: 12.sp),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              movie.releaseDate ?? "N/A",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14.sp),
                          SizedBox(width: 5.w),
                          Expanded(
                            child: Text(
                              movie.rating != null ? movie.rating!.toStringAsFixed(1) : "N/A",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, "Trang chủ", true, () {
            // Đã ở trang chủ, không cần làm gì
          }),
          _buildNavItem(Icons.movie, "Phim", false, () {
            // Chuyển đến trang danh sách phim
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MovieListScreen(),
              ),
            );
          }),
          _buildNavItem(Icons.confirmation_number, "Vé", false, () {
            // Chuyển đến trang vé của người dùng
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyTicketScreen(),
              ),
            );
          }),
          _buildNavItem(Icons.person, "Tài khoản", false, () {
            // Hiển thị menu người dùng
            _showUserMenu(context);
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.amber : Colors.grey,
            size: 24.sp,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isSelected ? Colors.amber : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
} 