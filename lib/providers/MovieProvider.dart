import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

class MovieProvider extends ChangeNotifier {
  int? selectedMovieId;

  void setMovieId(int id) {
    selectedMovieId = id;
    notifyListeners();
  }

  int get movieId => selectedMovieId ?? 0;
}
// mục này dùng để lưu trữ id phim được chọn , sau khi chọn phòng , roomid và movieid sẽ được dùng để truy vấn lấy ra thông tin phòng chiếu
