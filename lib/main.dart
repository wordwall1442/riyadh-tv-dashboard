import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:adhan/adhan.dart';

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
  DateTime _now = DateTime.now();
  late PrayerTimes _prayerTimes;

  @override
  void initState() {
    super.initState();
    _calculatePrayers();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
        if (_now.hour == 0 && _now.minute == 0 && _now.second == 0) {
          _calculatePrayers();
        }
      });
    });
  }

  void _calculatePrayers() {
    final coordinates = Coordinates(24.7136, 46.6753);
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.madhab = Madhab.shafi;
    _prayerTimes = PrayerTimes.today(coordinates, params);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 35,
              child: Column(
                children: [
                  _buildHeaderDateTimeCard(),
                  const SizedBox(height: 14),
                  Expanded(child: _buildMatchesCard()),
                ],
              ),
            ),
            const SizedBox(width: 16),
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

  Widget _buildHeaderDateTimeCard() {
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
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFF58A6FF),
              ),
            ),
            const Divider(color: Colors.white24, height: 20),
            Text(
              '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ',
              style: const TextStyle(fontSize: 18, color: Color(0xFF7EE787), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              gregorianFormat.format(_now),
              style: const TextStyle(fontSize: 14, color: Colors.white70),
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
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView(
                children: [
                  _matchItem('الهلال', 'النصر', '08:30 م', 'دوري روشن السعودي'),
                  _matchItem('ريال مدريد', 'برشلونة', '10:00 م', 'الدوري الإسباني'),
                  _matchItem('ليفربول', 'مانشستر سيتي', '06:00 م', 'الدوري الإنجليزي'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchItem(String team1, String team2, String time, String league) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(league, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(team1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(time, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              Text(team2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesCard() {
    final timeFmt = DateFormat('hh:mm a', 'ar');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_filled, color: Color(0xFF7EE787)),
                    SizedBox(width: 8),
                    Text(
                      'مواقيت الصلاة - الرياض (تقويم أم القرى)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text('تنبيه الأذان التلقائي: مُفعّل', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _prayerTimeColumn('الفجر', timeFmt.format(_prayerTimes.fajr), _prayerTimes.nextPrayer() == Prayer.fajr),
                _prayerTimeColumn('الشروق', timeFmt.format(_prayerTimes.sunrise), false),
                _prayerTimeColumn('الظهر', timeFmt.format(_prayerTimes.dhuhr), _prayerTimes.nextPrayer() == Prayer.dhuhr),
                _prayerTimeColumn('العصر', timeFmt.format(_prayerTimes.asr), _prayerTimes.nextPrayer() == Prayer.asr),
                _prayerTimeColumn('المغرب', timeFmt.format(_prayerTimes.maghrib), _prayerTimes.nextPrayer() == Prayer.maghrib),
                _prayerTimeColumn('العشاء', timeFmt.format(_prayerTimes.isha), _prayerTimes.nextPrayer() == Prayer.isha),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _prayerTimeColumn(String name, String time, bool isNext) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isNext ? const Color(0xFF238636) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: isNext ? Border.all(color: Colors.lightGreenAccent, width: 2) : null,
      ),
      child: Column(
        children: [
          Text(name, style: TextStyle(fontSize: 16, fontWeight: isNext ? FontWeight.bold : FontWeight.normal)),
          const SizedBox(height: 6),
          Text(time, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isNext ? Colors.white : const Color(0xFF58A6FF))),
          if (isNext)
            const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text('الصلاة القادمة', style: TextStyle(fontSize: 10, color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildHadithCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.black54, Colors.teal.shade900.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book, color: Colors.amberAccent),
                SizedBox(width: 8),
                Text('حديث اليوم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            Divider(color: Colors.white24),
            Expanded(
              child: Center(
                child: Text(
                  '«قال رسول الله ﷺ: مَن سَلَكَ طَرِيقاً يَلْتَمِسُ فِيهِ عِلْماً، سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقاً إِلَى الجَنَّةِ»',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.6, fontStyle: FontStyle.italic),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text('صحيح مسلم', style: TextStyle(fontSize: 12, color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDhikrCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.black54, Colors.indigo.shade900.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_border, color: Colors.pinkAccent),
                SizedBox(width: 8),
                Text('من أذكار اليوم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            Divider(color: Colors.white24),
            Expanded(
              child: Center(
                child: Text(
                  '«لا إلهَ إلاّ اللّهُ وحْـدَهُ لا شَـريكَ لهُ، لهُ المُـلْكُ ولهُ الحَمْـد، وهُوَ على كُلّ شَيءٍ قَدير»',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.6),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text('حصن المسلم (١٠٠ مرة)', style: TextStyle(fontSize: 12, color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}
