# CineNow - Ứng dụng đặt vé xem phim


## Giới thiệu

CineNow là ứng dụng di động đặt vé xem phim hiện đại, tiện lợi được phát triển bằng Flutter. Ứng dụng cho phép người dùng dễ dàng tìm kiếm phim, chọn suất chiếu, đặt ghế và thanh toán trực tuyến.

## Tính năng chính

- **Xác thực đa dạng**: Đăng ký, đăng nhập bằng email/số điện thoại, Google và Facebook
- **Xác thực OTP**: Bảo mật tài khoản thông qua mã OTP gửi qua email
- **Quản lý phim**: Hiển thị phim đang chiếu, sắp chiếu, và phim nổi bật
- **Tìm kiếm phim**: Tìm kiếm theo tên phim
- **Chọn rạp/phòng chiếu**: Hiển thị danh sách rạp theo thành phố, phòng chiếu và suất chiếu
- **Đặt ghế**: Giao diện trực quan cho việc chọn ghế, hỗ trợ nhiều loại ghế khác nhau
- **Đặt combo**: Chọn bắp nước và thức ăn kèm theo
- **Lịch sử đặt vé**: Quản lý thông tin vé đã đặt
- **Thanh toán trực tuyến**: Hỗ trợ nhiều phương thức thanh toán (VNPay, Momo)

## Công nghệ sử dụng

### Frontend
- **Flutter**: Framework phát triển ứng dụng di động đa nền tảng
- **Provider**: Quản lý state
- **http/dio**: Thực hiện các API requests
- **flutter_facebook_auth, google_sign_in**: Tích hợp đăng nhập mạng xã hội
- **shared_preferences**: Lưu trữ cục bộ

### Backend
- **Node.js**: Server runtime
- **Express**: Web framework
- **PostgreSQL**: Cơ sở dữ liệu
- **JSON Web Token (JWT)**: Xác thực và phân quyền
- **Nodemailer/Brevo**: Gửi email OTP

## Cài đặt và chạy ứng dụng

### Yêu cầu hệ thống
- Flutter SDK (2.10.0 trở lên)
- Dart SDK (2.16.0 trở lên)
- Android Studio hoặc Visual Studio Code
- Node.js (14.0.0 trở lên)
- PostgreSQL (12.0 trở lên)

### Cài đặt frontend
1. Clone repository
   ```bash
   git clone https://github.com/your-username/cinenow.git
   cd cinenow
   ```

2. Cài đặt dependencies
   ```bash
   flutter pub get
   ```

3. Cấu hình OAuth (Google, Facebook)
   - Chỉnh sửa file `android/app/src/main/res/values/strings.xml` với Facebook App ID
   - Cập nhật file `ios/Runner/Info.plist` với cấu hình Facebook và Google
     ```xml
     <key>FacebookAppID</key>
     <string>3046712248827470</string>
     <key>FacebookClientToken</key>
     <string>3046712248827470|d153a8e5401a49d46d8808a88eb2f64b</string>
     <key>FacebookDisplayName</key>
     <string>CineNow</string>
     ```

4. Chạy ứng dụng
   ```bash
   flutter run
   ```

### Cài đặt backend
1. Truy cập thư mục server
   ```bash
   cd path/to/server_folder
   ```

2. Cài đặt dependencies
   ```bash
   npm install
   ```

3. Cấu hình biến môi trường
   - Tạo file `.env` với nội dung sau:
   ```
   # Cấu hình Database
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=ticket_cinema
   DB_USER=your_db_user
   DB_PASSWORD=your_db_password

   # Cấu hình Email
   EMAIL_USER=your_email@gmail.com
   EMAIL_APP_PASSWORD=your_app_password

   # JWT Configuration
   JWT_SECRET=your_jwt_secret_key
   JWT_EXPIRES_IN=7d

   # Google OAuth
   GOOGLE_CLIENT_ID=your_google_client_id
   GOOGLE_CLIENT_SECRET=your_google_client_secret

   # Facebook OAuth
   FACEBOOK_APP_ID=your_facebook_app_id
   FACEBOOK_APP_SECRET=
   

   # Port
   PORT=3000
   ```

4. Khởi động server
   ```bash
   node server.js
   ```

## Cấu hình xác thực

### Google Sign-In
1. Truy cập [Google Cloud Console](https://console.cloud.google.com/)
2. Tạo project mới và cấu hình OAuth consent screen
3. Tạo OAuth 2.0 Client IDs cho Android, iOS
4. Cập nhật các file cấu hình tương ứng

### Facebook Login
1. Truy cập [Facebook Developer Console](https://developers.facebook.com/)
2. Tạo ứng dụng mới
3. Thêm Facebook Login vào Products
4. Cấu hình các settings của Facebook Login:
   - Thêm OAuth Redirect URLs
   - Cấu hình App Domains
   - Thêm platform iOS/Android với Bundle ID/Package Name tương ứng

## Khắc phục sự cố

### Lỗi đăng nhập Google
- Kiểm tra Google Client ID đã được cấu hình đúng
- Đảm bảo đã cấu hình JWT_SECRET trong file .env của server
- Đảm bảo server đã khởi động lại sau khi cập nhật biến môi trường

### Lỗi đăng nhập Facebook
- Kiểm tra Facebook App ID và Client Token đã được cấu hình đúng trong Info.plist
- Đảm bảo đã sử dụng đúng thuộc tính `tokenString` thay vì `token` trong AccessToken
- Cấu hình đúng URL redirect trong Facebook Developer Console

### Lỗi kết nối đến server
- Kiểm tra đường dẫn API base URL trong config của ứng dụng
- Đảm bảo server Node.js đang chạy và cổng không bị chặn
- Kiểm tra kết nối mạng và firewall

## Liên hệ

Nếu có bất kỳ câu hỏi hoặc góp ý, vui lòng liên hệ:
- Email: dinhvanphi01478965@gmail.com

---

© 2024 CineNow. All rights reserved.
