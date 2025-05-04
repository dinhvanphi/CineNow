class Ticket {
  final String id;
  final String movieTitle;
  final String duration;
  final String genres;
  final String showtime;
  final String showDate;
  final String theater;
  final String section;
  final List<String> seats;
  final double price;
  final String imageUrl;
  final DateTime purchaseDate;
  final bool isUsed;

  Ticket({
    required this.id,
    required this.movieTitle,
    required this.duration,
    required this.genres,
    required this.showtime,
    required this.showDate,
    required this.theater,
    required this.section,
    required this.seats,
    required this.price,
    required this.imageUrl,
    required this.purchaseDate,
    this.isUsed = false,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      movieTitle: json['movie_title'],
      duration: json['duration'],
      genres: json['genres'],
      showtime: json['showtime'],
      showDate: json['show_date'],
      theater: json['theater'],
      section: json['section'],
      seats: List<String>.from(json['seats']),
      price: json['price'].toDouble(),
      imageUrl: json['image_url'],
      purchaseDate: DateTime.parse(json['purchase_date']),
      isUsed: json['is_used'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movie_title': movieTitle,
      'duration': duration,
      'genres': genres,
      'showtime': showtime,
      'show_date': showDate,
      'theater': theater,
      'section': section,
      'seats': seats,
      'price': price,
      'image_url': imageUrl,
      'purchase_date': purchaseDate.toIso8601String(),
      'is_used': isUsed,
    };
  }
}
