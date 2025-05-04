import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/Ticket.dart';
import '../../HomePage.dart';

class DirectTicketCreationScreen extends StatefulWidget {
  const DirectTicketCreationScreen({Key? key}) : super(key: key);
  
  @override
  _DirectTicketCreationScreenState createState() => _DirectTicketCreationScreenState();
}

class _DirectTicketCreationScreenState extends State<DirectTicketCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Thông tin vé
  String _movieTitle = "Avengers: Infinity War";
  String _duration = "2 hours 29 minutes";
  String _genres = "Action, adventure, sci-fi";
  String _showtime = "14:15";
  String _showDate = "18.04.2025";
  String _theater = "Vincom Ocean Park CGV";
  String _section = "Section 4";
  String _seats = "H7, H8";
  double _price = 159000.0;
  String _imageUrl = "https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg";
  
  Future<void> _createAndSaveTicket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('===== TIẾN HÀNH TẠO VÉ THỦ CÔNG =====');
      
      // Parse seats string to list
      List<String> seatsList = _seats.split(',').map((s) => s.trim()).toList();
      
      // Create new ticket
      final ticket = Ticket(
        id: 'MANUAL_${DateTime.now().millisecondsSinceEpoch}',
        movieTitle: _movieTitle,
        duration: _duration,
        genres: _genres,
        showtime: _showtime,
        showDate: _showDate,
        theater: _theater,
        section: _section,
        seats: seatsList,
        price: _price,
        imageUrl: _imageUrl,
        purchaseDate: DateTime.now(),
      );
      
      print('Đã tạo vé: ${ticket.id}, ${ticket.movieTitle}');
      
      // Save ticket directly
      final ticketJson = jsonEncode(ticket.toJson());
      
      // Get SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Save in multiple ways for redundancy
      await prefs.setString('emergency_ticket', ticketJson);
      await prefs.setString('latest_ticket', ticketJson);
      await prefs.setString('super_emergency_ticket', ticketJson);
      
      // Save to user_tickets list
      final ticketKey = 'ticket_${ticket.id}';
      await prefs.setString(ticketKey, ticketJson);
      
      List<String> ticketKeys = prefs.getStringList('user_tickets') ?? [];
      if (!ticketKeys.contains(ticketKey)) {
        ticketKeys.add(ticketKey);
        await prefs.setStringList('user_tickets', ticketKeys);
      }
      
      print('===== VÉ ĐÃ ĐƯỢC LƯU THÀNH CÔNG =====');
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vé đã được tạo và lưu thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate back to home after 2 seconds
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => HomePage()),
              (route) => false,
            );
          }
        });
      }
    } catch (e) {
      print('LỖI KHI TẠO VÉ: $e');
      print(e.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi lưu vé: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo vé thủ công'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tạo vé từ thông tin thanh toán VNPay',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              
              // Movie info fields
              TextFormField(
                initialValue: _movieTitle,
                decoration: InputDecoration(
                  labelText: 'Tên phim',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên phim' : null,
                onChanged: (value) => _movieTitle = value,
              ),
              SizedBox(height: 12),
              
              TextFormField(
                initialValue: _duration,
                decoration: InputDecoration(
                  labelText: 'Thời lượng',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _duration = value,
              ),
              SizedBox(height: 12),
              
              TextFormField(
                initialValue: _theater,
                decoration: InputDecoration(
                  labelText: 'Rạp',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên rạp' : null,
                onChanged: (value) => _theater = value,
              ),
              SizedBox(height: 12),
              
              TextFormField(
                initialValue: _section,
                decoration: InputDecoration(
                  labelText: 'Phòng',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _section = value,
              ),
              SizedBox(height: 12),
              
              // Showtimes
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _showtime,
                      decoration: InputDecoration(
                        labelText: 'Giờ chiếu',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _showtime = value,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _showDate,
                      decoration: InputDecoration(
                        labelText: 'Ngày chiếu',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => _showDate = value,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              // Seats and price
              TextFormField(
                initialValue: _seats,
                decoration: InputDecoration(
                  labelText: 'Ghế (cách nhau bằng dấu phẩy)',
                  border: OutlineInputBorder(),
                  hintText: 'VD: H7, H8',
                ),
                validator: (value) => value!.isEmpty ? 'Vui lòng nhập ghế' : null,
                onChanged: (value) => _seats = value,
              ),
              SizedBox(height: 12),
              
              TextFormField(
                initialValue: _price.toString(),
                decoration: InputDecoration(
                  labelText: 'Giá tiền',
                  border: OutlineInputBorder(),
                  suffixText: 'VND',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Vui lòng nhập giá';
                  if (double.tryParse(value) == null) return 'Giá không hợp lệ';
                  return null;
                },
                onChanged: (value) {
                  _price = double.tryParse(value) ?? 0;
                },
              ),
              SizedBox(height: 20),
              
              // Submit button
              Center(
                child: _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _createAndSaveTicket,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Tạo và Lưu Vé',
                          style: TextStyle(fontSize: 18),
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
