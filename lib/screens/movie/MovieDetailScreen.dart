import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import '../../models/Movie.dart';
import 'dart:convert';
import 'RoomListScreen.dart'; 
import 'package:provider/provider.dart';
import 'package:cinenow/providers/CinemaProvider.dart';
import 'package:cinenow/providers/MovieProvider.dart';


class Cinema {
  final String id;
  final String name;
  final String address;
  final String city;

  Cinema({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
  });

  factory Cinema.fromJson(Map<String, dynamic> json) {
    return Cinema(
      id: json['id'].toString(),
      name: json['name'].toString(),
      address: json['address'].toString(),
      city: json['city'].toString(),
    );
  }
}

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({Key? key, required this.movie}) : super(key: key);

  @override
  _MovieDetailScreenState createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  Future<void> _handleBooking() async {
    final city = await showDialog<String>(
      context: context,
      builder: (context) => CityInputDialog(),
    );

    if (city != null && city.isNotEmpty) {
      final cinemas = await fetchCinemas(city);
      if (cinemas != null && cinemas.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CinemaListScreen(cinemas: cinemas),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy rạp nào ở $city')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(),
                  SizedBox(height: 12.h),
                  _buildInfo(),
                  SizedBox(height: 16.h),
                  _buildGenres(),
                  SizedBox(height: 16.h),
                  _buildOverview(),
                  SizedBox(height: 16.h),
                  _buildCast(),
                  SizedBox(height: 24.h),
                  _buildBookButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300.h,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hình ảnh phim
            Image.network(
              widget.movie.image,
              fit: BoxFit.cover,
            ),
            // Gradient overlay để text hiển thị rõ hơn
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.share, color: Colors.white),
          ),
          onPressed: () {
            // Chia sẻ phim
          },
        ),
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_border, color: Colors.white),
          ),
          onPressed: () {
            // Thêm vào yêu thích
          },
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.movie.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            if (widget.movie.rating != null) ...[
              Icon(Icons.star, color: Colors.amber, size: 20.sp),
              SizedBox(width: 4.w),
              Text(
                '${widget.movie.rating}/10',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(width: 16.w),
            ],
            if (widget.movie.duration != null) ...[
              Icon(Icons.access_time, color: Colors.grey, size: 18.sp),
              SizedBox(width: 4.w),
              Text(
                widget.movie.duration!,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poster phim
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Image.network(
            widget.movie.image,
            width: 120.w,
            height: 180.h,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: 16.w),
        // Thông tin phim
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.movie.director != null) _buildInfoRow("Đạo diễn", widget.movie.director!),
              if (widget.movie.language != null) _buildInfoRow("Ngôn ngữ", widget.movie.language!),
              if (widget.movie.releaseDate != null) _buildInfoRow("Khởi chiếu", widget.movie.releaseDate!),
              if (widget.movie.ageRating != null) _buildInfoRow("Độ tuổi", widget.movie.ageRating!),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenres() {
    if (widget.movie.genres == null || widget.movie.genres!.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Thể loại",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: widget.movie.genres!.map((genre) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                genre,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOverview() {
    if (widget.movie.overview == null || widget.movie.overview!.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Nội dung",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          widget.movie.overview!,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14.sp,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCast() {
    if (widget.movie.cast == null || widget.movie.cast!.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Diễn viên",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          widget.movie.cast!,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14.sp,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    if (widget.movie.status == "coming_soon") {
      return Container(
        width: double.infinity,
        height: 50.h,
        child: OutlinedButton(
          onPressed: () {
            // Đặt nhắc nhở khi phim ra rạp
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.amber),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.r),
            ),
          ),
          child: Text(
            "Đặt nhắc nhở",
            style: TextStyle(
              color: Colors.amber,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: () async {
          final city = await showDialog<String>(
            context: context,
            builder: (context) => CityInputDialog(),
          );
          
          if (city != null && city.isNotEmpty) {
            final cinemas = await fetchCinemas(city);
            if (cinemas != null && cinemas.isNotEmpty) {
              if(widget.movie.id != null){
                Provider.of<MovieProvider>(context, listen: false).setMovieId(widget.movie.id!);
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CinemaListScreen(cinemas: cinemas),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Không tìm thấy rạp nào ở $city')),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.r),
          ),
        ),
        child: Text(
          "Đặt vé ngay",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 
class CityInputDialog extends StatelessWidget {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black, // Nền tối
      title: Text("Nhập tỉnh thành của bạn", style: TextStyle(color: Colors.white)),
      content: TextFormField(
        controller: _controller,
        style: TextStyle(color: Colors.white), // Chữ trắng
        decoration: InputDecoration(
          hintText: "Ví dụ: Hà Nội, TP.HCM",
          hintStyle: TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[900], // Nền nhập màu xám đậm
          border: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Hủy", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text("Xác nhận", style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}



class CinemaListScreen extends StatelessWidget {
  final List<Cinema> cinemas;

  const CinemaListScreen({required this.cinemas});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Chọn rạp chiếu phim",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần thông tin
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Chọn rạp chiếu phim gần bạn",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
          
          // Danh sách rạp
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: cinemas.length,
              itemBuilder: (context, index) {
                final cinema = cinemas[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Provider.of<CinemaProvider>(context, listen: false)
                            .setCinemaId(int.tryParse(cinema.id) ?? 0);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RoomListScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Icon rạp
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.movie_creation_outlined,
                                  color: Colors.amber,
                                  size: 30,
                                ),
                              ),
                            ),
                            
                            SizedBox(width: 16),
                            
                            // Thông tin rạp
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cinema.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    cinema.address,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: Colors.grey[600],
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        cinema.city,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Icon mũi tên
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.amber,
                              size: 16,
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
        ],
      ),
    );
  }
}
// Hàm gọi API
Future<List<Cinema>?> fetchCinemas(String city) async {
  try {
    final response = await http.get(
      Uri.parse('https://67c7-171-251-30-227.ngrok-free.app/api/cinemas?city=$city'),
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((e) => Cinema.fromJson(e))
          .toList();
    } else {
      return null;
    }
  } catch (e) {
    print('Lỗi kết nối: $e');
    return null;
  }
}