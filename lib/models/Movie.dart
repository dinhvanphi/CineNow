class Movie {
  final int? id;
  final String title;
  final String? originalTitle;
  final String? originalLanguage;
  final String? posterPath;  // Trong database là poster_path
  final String? backdropPath; // Trong database là backdrop_path
  final String image;  // URL đầy đủ cho ảnh poster (https://image.tmdb.org/t/p/w500 + poster_path)
  final String? backdropImage; // URL đầy đủ cho ảnh backdrop
  final double? rating; // vote_average từ TMDB
  final String? overview; // Mô tả phim từ TMDB
  final String? releaseDate;
  final String? status; // "now_showing" hoặc "coming_soon"
  final bool? featured; // Phim có được hiển thị ở banner không
  
  // Thông tin bổ sung có thể không có trong database
  final String? director;
  final String? cast;
  final List<String>? genres;
  final String? duration;
  final String? language;
  final String? ageRating;

  Movie({
    this.id,
    required this.title,
    this.originalTitle,
    this.originalLanguage,
    this.posterPath,
    this.backdropPath,
    required this.image,
    this.backdropImage,
    this.rating,
    this.overview,
    this.director,
    this.cast,
    this.genres,
    this.duration,
    this.language,
    this.ageRating,
    this.releaseDate,
    this.status,
    this.featured,
  });

  // Tạo Movie từ Map (JSON)
  factory Movie.fromMap(Map<String, dynamic> map) {
    final String posterUrl = map['poster_path'] != null 
        ? 'https://image.tmdb.org/t/p/w500${map['poster_path']}' 
        : map['image'] ?? '';
        
    final String backdropUrl = map['backdrop_path'] != null 
        ? 'https://image.tmdb.org/t/p/original${map['backdrop_path']}' 
        : map['backdrop_image'] ?? '';
        
    return Movie(
      id: map['id'],
      title: map['title'] ?? '',
      originalTitle: map['original_title'],
      originalLanguage: map['original_language'],
      posterPath: map['poster_path'],
      backdropPath: map['backdrop_path'],
      image: posterUrl,
      backdropImage: backdropUrl,
      rating: map['vote_average'] != null 
          ? (map['vote_average'] is double 
            ? map['vote_average'] 
            : double.tryParse(map['vote_average'].toString()) ?? 0.0) 
          : null,
      overview: map['overview'],
      director: map['director'],
      cast: map['cast'],
      genres: map['genres'] is List 
          ? List<String>.from(map['genres']) 
          : map['genres']?.toString().split(',').map((e) => e.trim()).toList(),
      duration: map['runtime']?.toString() ?? map['duration']?.toString(),
      language: map['language'] ?? map['original_language'],
      ageRating: map['age_rating'],
      releaseDate: map['release_date']?.toString(),
      status: map['status'],
      featured: map['featured'] is bool ? map['featured'] : map['featured'] == 'true',
    );
  }

  // Chuyển Movie thành Map (JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'original_title': originalTitle,
      'original_language': originalLanguage,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'image': image,
      'backdrop_image': backdropImage,
      'vote_average': rating,
      'overview': overview,
      'director': director,
      'cast': cast,
      'genres': genres,
      'runtime': duration,
      'language': language,
      'age_rating': ageRating,
      'release_date': releaseDate,
      'status': status,
      'featured': featured,
    };
  }
} 