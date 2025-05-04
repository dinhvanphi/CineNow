class User {
  final int? id;
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final DateTime createdAt;
  final String? avatarUrl;

  User({
    this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    DateTime? createdAt,
    this.avatarUrl,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'created_at': createdAt.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      fullName: map['full_name'],
      email: map['email'],
      phone: map['phone'],
      password: map['password'],
      createdAt: DateTime.parse(map['created_at']),
      avatarUrl: map['avatar_url'],
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Xử lý ID người dùng - có thể là int hoặc string
    int? userId;
    if (json['id'] != null) {
      if (json['id'] is int) {
        userId = json['id'];
      } else {
        try {
          userId = int.parse(json['id'].toString());
        } catch (e) {
          print('Lỗi chuyển đổi ID người dùng: $e');
          // Giữ null nếu không thể chuyển đổi
        }
      }
    }
    
    // Xử lý tên người dùng
    String userName = '';
    // Thêm trường fullname vào danh sách kiểm tra
    if (json['fullname'] != null) {
      userName = json['fullname'];
    } else if (json['name'] != null) {
      userName = json['name'];
    } else if (json['fullName'] != null) {
      userName = json['fullName'];
    } else if (json['full_name'] != null) {
      userName = json['full_name'];
    }
    
    print('Tên người dùng từ API: $userName');
    
    return User(
      id: userId,
      fullName: userName,
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'created_at': createdAt.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }
} 