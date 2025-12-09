import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'providers/SeatProvider.dart';
import 'providers/UserProvider.dart'; 
import 'IntroView.dart';
import 'providers/CinemaProvider.dart';
import 'providers/MovieProvider.dart';
import 'providers/RoomProvider.dart';
import 'providers/ShowtimeProvider.dart';
import 'providers/ComboProvider.dart';
import 'screens/payment/PaymentResultScreen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
 
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('vi', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CinemaProvider()),
        ChangeNotifierProvider(create: (context) => MovieProvider()),
        ChangeNotifierProvider(create: (context) => RoomProvider()),
        ChangeNotifierProvider(create: (context) => ShowtimeProvider()),
        ChangeNotifierProvider(create: (context) => SeatProvider()),
        ChangeNotifierProvider(create: (context) => ComboProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinkHandling();
  }

  Future<void> _initDeepLinkHandling() async {

    
    print('Khởi tạo xử lý deep link');
  }

  void _handleDeepLink(String link) {
    print('Handling deep link: $link');
    
    if (link.startsWith('cinenow://payment-result')) {
      // Parse query parameters
      final uri = Uri.parse(link);
      final queryParams = uri.queryParameters;
      
      // Điều hướng đến màn hình kết quả thanh toán
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => PaymentResultScreen(
            queryParams: Map<String, String>.from(queryParams),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'CineNow',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          navigatorKey: navigatorKey,
          home: const IntroView(),
        );
      },
    );
  }
}