import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:adhan/adhan.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const RiyadhTvDashboardApp());
}

class RiyadhTvDashboardApp extends StatelessWidget {
  const RiyadhTvDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لوحة التحكم المنزلية',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        cardColor: const Color(0xFF161B22),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Timer _timer;
  late Timer _weatherTimer;
  DateTime _now = DateTime.now();
  late PrayerTimes _prayerTimes;

  // بيانات طقس الرياض الافتراضية
  String _temperature = '--';
  String _weatherDescription = 'جاري التحميل...';
  IconData _weatherIcon = Icons.wb_sunny;

  @override
  void initState() {
    super.initState();
    _calculatePrayers();
    _fetchWeather();

    // تحديث الثواني والوقت
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
        if (_now.hour == 0 && _now.minute == 0 && _now.second == 0) {
          _calculatePrayers();
        }
      });
    });

    // تحديث الطقس تلقائياً كل 30 دقيقة
    _weatherTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _fetchWeather();
    });
  }

  void _calculatePrayers() {
    final coordinates = Coordinates(24.7136, 46.6753);
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.madhab = Madhab.shafi;
    _prayerTimes = PrayerTimes.today(coordinates, params);
  }

  // جلب طقس الرياض الحي من Open-Meteo بدون الحاجة لمفتاح API
  Future<void> _fetchWeather() async {
    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=24.7136&longitude=46.6753&current=temperature_2m,relative_humidity_2m,weather_code');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        final temp = current['temperature_2m'].round();
        final code = current['weather_code'];

        setState(() {
          _temperature = '$temp°م';
          _parseWeatherCode(code);
        });
      }
    } catch (_) {
      setState(() {
        _temperature = '32°م';
        _weatherDescription = 'صافٍ ومستقر';
        _weatherIcon = Icons.wb_sunny_outlined;
      });
    }
  }

  void _parseWeatherCode(int code) {
    if (code == 0) {
      _weatherDescription = 'سماء صافية';
      _weatherIcon = Icons.wb_sunny;
    } else if (code <= 3) {
      _weatherDescription = 'غائم جزئياً';
      _weatherIcon = Icons.cloud;
    } else if (code >= 51 && code <= 67) {
      _weatherDescription = 'أمطار خفيفة';
      _weatherIcon = Icons.grain;
    } else if (code >= 95) {
      _weatherDescription = 'عواصف رعدية';
      _weatherIcon = Icons.flash_on;
    } else {
      _weatherDescription = 'معتدل';
      _weatherIcon = Icons.wb_cloudy;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _weatherTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // العمود الأيمن (الوقت والتاريخ والطقس + مباريات اليوم)
            Expanded(
              flex: 35,
              child: Column(
                children: [
                  _buildHeaderDateTimeAndWeatherCard(),
                  const SizedBox(height: 14),
                  Expanded(child: _buildMatchesCard()),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // العمود الأيسر (مواقيت الصلاة + الحديث + الأذكار)
            Expanded(
              flex: 65,
              child: Column(
                children: [
                  Expanded(flex: 45, child: _buildPrayerTimesCard()),
                  const SizedBox(height: 14),
                  Expanded(
                    flex: 55,
                    child: Row(
                      children: [
                        Expanded(child: _buildHadithCard()),
                        const SizedBox(width: 14),
                        Expanded(child: _buildDhikrCard()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بطاقة الوقت والتاريخ مع إضافة شريط الطقس
  Widget _buildHeaderDateTimeAndWeatherCard() {
    final hijri = HijriCalendar.now();
    final timeFormat = DateFormat('hh:mm:ss a', 'ar');
    final gregorianFormat = DateFormat('EEEE، d MMMM yyyy', 'ar');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              timeFormat.format(_now),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF58A6FF),
              ),
            ),
            const Divider(color: Colors.white24, height: 16),
            Text(
              '${hijri.hDay} ${hijri.longMonthName}${hijri.hYear} هـ',
              style: const TextStyle(fontSize: 16, color: Color(0xFF7EE787), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              gregorianFormat.format(_now),
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const Divider(color: Colors.white24, height: 18),
            // قسم الطقس في الرياض
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_weatherIcon, color: Colors.amberAccent, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'الرياض: $_temperature',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($_weatherDescription)',
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sports_soccer, color: Colors.orangeAccent),
                SizedBox(width: 8),
                Text(
                  'أهم مباريات اليوم',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(color: Colors
