import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart'; // 삭제
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
// import 'package:table_calendar/table_calendar.dart'; // 삭제
// import 'package:fl_chart/fl_chart.dart'; // 삭제
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart'; // API 서비스 import 추가

// 전역 변수로 일기 데이터 관리
List<Map<String, dynamic>> globalDiaries = [];

// 일기 데이터 저장 함수
Future<void> saveDiariesToLocal() async {
  final prefs = await SharedPreferences.getInstance();
  final diariesJson = globalDiaries.map((diary) {
    return {
      ...diary,
      'date': diary['date'].toIso8601String(), // DateTime을 문자열로 변환
    };
  }).toList();
  await prefs.setString('saved_diaries', jsonEncode(diariesJson));
  print('💾 일기 데이터 저장 완료: ${globalDiaries.length}개');
}

// 일기 데이터 로드 함수
Future<void> loadDiariesFromLocal() async {
  final prefs = await SharedPreferences.getInstance();
  final diariesString = prefs.getString('saved_diaries');

  if (diariesString != null) {
    final diariesJson = jsonDecode(diariesString) as List;
    globalDiaries = diariesJson.map<Map<String, dynamic>>((diary) {
      // emotions 필드 처리 - 파이썬에서 자동 제공하므로 기본값 설정
      Map<String, dynamic> emotions = {'좋음': 33, '평범함': 34, '나쁨': 33};
      if (diary['emotions'] != null) {
        final rawEmotions = diary['emotions'] as Map<String, dynamic>;
        emotions = rawEmotions.map((k, v) => MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? 0));
      }
      return {
        ...diary,
        'date': DateTime.parse(diary['date']),
        'emotions': emotions,
      };
    }).toList();
    print('📂 일기 데이터 로드 완료: ${globalDiaries.length}개');
  } else {
    // 더미 데이터 최초 1회만
    globalDiaries = [
      {
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'title': '어제의 일기',
        'summary': '오늘은 정말 좋은 하루였습니다. 새로운 것을 배우고 성장하는 느낌이 들었어요.',
        'emotions': {'좋음': 70, '평범함': 20, '나쁨': 10},
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'title': '2일 전의 일기',
        'summary': '평범한 하루였지만, 작은 기쁨들을 발견할 수 있었습니다.',
        'emotions': {'좋음': 30, '평범함': 60, '나쁨': 10},
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'title': '3일 전의 일기',
        'summary': '오늘은 기분이 좋지 않았지만, 친구들과의 대화로 위로를 받았습니다.',
        'emotions': {'좋음': 20, '평범함': 30, '나쁨': 50},
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 4)),
        'title': '4일 전의 일기',
        'summary': '새로운 프로젝트를 시작해서 설렘과 긴장이 교차하는 하루였습니다.',
        'emotions': {'좋음': 80, '평범함': 15, '나쁨': 5},
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'title': '5일 전의 일기',
        'summary': '일상적인 하루였지만, 차분히 마음을 다스릴 수 있었습니다.',
        'emotions': {'좋음': 25, '평범함': 65, '나쁨': 10},
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 6)),
        'title': '6일 전의 일기',
        'summary': '스트레스가 많았지만, 운동을 통해 기분을 전환할 수 있었습니다.',
        'emotions': {'좋음': 40, '평범함': 35, '나쁨': 25},
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'title': '7일 전의 일기',
        'summary': '가족들과 함께한 시간이 정말 소중하고 행복했습니다.',
        'emotions': {'좋음': 90, '평범함': 8, '나쁨': 2},
      },
      {
        'date': DateTime.now().subtract(const Duration(days: 8)),
        'title': '8일 전의 일기',
        'summary': '오늘은 기분이 좋지 않았지만, 음악을 들으며 마음을 진정시켰습니다.',
        'emotions': {'좋음': 15, '평범함': 25, '나쁨': 60},
      },
    ];
    await saveDiariesToLocal();
    print('📝 더미 데이터로 초기화');
  }
  sortDiariesByDate();
}

void sortDiariesByDate() {
  globalDiaries.sort((a, b) => b['date'].compareTo(a['date']));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadDiariesFromLocal(); // 앱 시작 시 저장된 일기 로드
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: '감성 일기',
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
        brightness: Brightness.light,
      ),
      home: const SplashScreen(),
    );
  }
}

// 스플래시 화면
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => const PasswordScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: CupertinoColors.systemBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                CupertinoIcons.book_fill,
                size: 60,
                color: CupertinoColors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '감성 일기',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.systemBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 비밀번호 입력 화면
class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordSet = false;
  String _storedPassword = '';

  @override
  void initState() {
    super.initState();
    _checkPasswordStatus();
  }

  Future<void> _checkPasswordStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _storedPassword = prefs.getString('user_password') ?? '';
    setState(() {
      _isPasswordSet = _storedPassword.isNotEmpty;
    });
  }

  void _checkPassword() {
    if (_passwordController.text == _storedPassword) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => const TutorialScreen()),
      );
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('오류'),
          content: const Text('비밀번호가 올바르지 않습니다.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('확인'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isPasswordSet ? '당신이 맞나요?' : '비밀번호 설정'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.lock_fill,
                size: 80,
                color: CupertinoColors.systemBlue,
              ),
              const SizedBox(height: 30),
              Text(
                _isPasswordSet 
                    ? '4자리 비밀번호를 입력하세요'
                    : '4자리 비밀번호를 설정하세요',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: '로그인',
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _isPasswordSet ? _checkPassword : _setPassword,
                  child: Text(_isPasswordSet ? '로그인' : '설정'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setPassword() async {
    if (_passwordController.text.length == 4) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_password', _passwordController.text);
      
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('설정 완료'),
          content: const Text('비밀번호가 설정되었습니다.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('확인'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  CupertinoPageRoute(builder: (context) => const TutorialScreen()),
                );
              },
            ),
          ],
        ),
      );
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('오류'),
          content: const Text('4자리 비밀번호를 입력해주세요.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('확인'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }
}

// 튜토리얼 화면
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _tutorialData = [
    {
      'title': '환영합니다!',
      'description': '감성 일기 앱에 오신 것을 환영합니다.\n이 앱으로 당신의 감정을 기록하고 분석해보세요.',
      'image': 'assets/tutorial1.png',
    },
    {
      'title': '카카오톡 대화 가져오기',
      'description': '불러오실 카카오톡 대화방의 설정 탭을 누르시고 [대화내용 관리]에서 텍스트 파일로 저장 또는 텍스트 메세지만 보내기를 누르시면 됩니다.',
      'image': 'assets/tutorial2.png',
    },
    {
      'title': '일기 쓸 파일 업로드 하기',
      'description': '이메일에서 파일을 다운받고 압축을 푸셔야 합니다',
      'image': 'assets/tutorial3.png',
    },
    {
      'title': '일기 작성하기',
      'description': '일기쓰기 탭에서 날짜를 선택하고 파일을 업로드하면 AI가 자동으로 감성 일기를 작성해드립니다.\n\n• TXT 파일: 텍스트 내용을 직접 입력\n• ZIP 파일: 여러 파일을 압축하여 업로드',
      'image': 'assets/tutorial4.png',
    },
    {
      'title': '감정 분석',
      'description': '작성된 일기를 바탕으로 감정을 분석하고 시각화해드립니다.\n\n• 홈 화면: 월별 감정 변화 그래프\n• 일기보기: 상세한 감정 분석 결과',
      'image': 'assets/tutorial5.png',
    },
   
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _tutorialData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              _tutorialData[index]['image']!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  CupertinoIcons.photo,
                                  size: 80,
                                  color: CupertinoColors.systemGrey,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          _tutorialData[index]['title']!,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _tutorialData[index]['description']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _tutorialData.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? CupertinoColors.systemBlue
                              : CupertinoColors.systemGrey4,
                        ),
                      ),
                    ),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      if (_currentPage < _tutorialData.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          CupertinoPageRoute(builder: (context) => const MainScreen()),
                        );
                      }
                    },
                    child: Text(
                      _currentPage < _tutorialData.length - 1 ? '다음' : '시작하기',
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
}

// 메인 화면
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // 저장된 데이터가 없을 때만 더미 데이터 초기화
    if (globalDiaries.isEmpty) {
      globalDiaries = [
        {
          'date': DateTime.now().subtract(const Duration(days: 1)),
          'title': '어제의 일기',
          'summary': '오늘은 정말 좋은 하루였습니다. 새로운 것을 배우고 성장하는 느낌이 들었어요.',
          'emotions': {'좋음': 70, '평범함': 20, '나쁨': 10},
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 2)),
          'title': '2일 전의 일기',
          'summary': '평범한 하루였지만, 작은 기쁨들을 발견할 수 있었습니다.',
          'emotions': {'좋음': 30, '평범함': 60, '나쁨': 10},
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 3)),
          'title': '3일 전의 일기',
          'summary': '오늘은 기분이 좋지 않았지만, 친구들과의 대화로 위로를 받았습니다.',
          'emotions': {'좋음': 20, '평범함': 30, '나쁨': 50},
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 4)),
          'title': '4일 전의 일기',
          'summary': '새로운 프로젝트를 시작해서 설렘과 긴장이 교차하는 하루였습니다.',
          'emotions': {'좋음': 80, '평범함': 15, '나쁨': 5},
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 5)),
          'title': '5일 전의 일기',
          'summary': '일상적인 하루였지만, 차분히 마음을 다스릴 수 있었습니다.',
          'emotions': {'좋음': 25, '평범함': 65, '나쁨': 10},
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 6)),
          'title': '6일 전의 일기',
          'summary': '스트레스가 많았지만, 운동을 통해 기분을 전환할 수 있었습니다.',
          'emotions': {'좋음': 40, '평범함': 35, '나쁨': 25},
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 7)),
          'title': '7일 전의 일기',
          'summary': '가족들과 함께한 시간이 정말 소중하고 행복했습니다.',
          'emotions': {'좋음': 90, '평범함': 8, '나쁨': 2},
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 8)),
          'title': '8일 전의 일기',
          'summary': '오늘은 기분이 좋지 않았지만, 음악을 들으며 마음을 진정시켰습니다.',
          'emotions': {'좋음': 15, '평범함': 25, '나쁨': 60},
        },
      ];
      // 더미 데이터도 로컬에 저장
      saveDiariesToLocal();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.book),
            label: '일기보기',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.pencil),
            label: '일기쓰기',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const HomeTab();
          case 1:
            return const DiaryViewTab();
          case 2:
            return const DiaryWriteTab();
          default:
            return const HomeTab();
        }
      },
    );
  }
}

// 홈 탭
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 표시될 때 데이터 새로고침
    setState(() {});
  }
  
  // 기분 상태에 따른 색상 반환
  Color _getMoodColor(String? mood) {
    switch (mood) {
      case '좋음':
        return CupertinoColors.systemGreen;
      case '평범함':
        return CupertinoColors.systemYellow;
      case '나쁨':
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.systemGrey5;
    }
  }
  
  // 날짜에 해당하는 기분 상태 가져오기
  String? _getMoodForDate(DateTime date) {
    // globalDiaries에서 해당 날짜의 일기 찾기
    final diary = globalDiaries.firstWhere(
      (diary) => diary['date'].year == date.year && 
                  diary['date'].month == date.month && 
                  diary['date'].day == date.day,
      orElse: () => <String, dynamic>{},
    );
    
    if (diary.isEmpty) return null;
    
    // 감정 데이터에서 가장 높은 비율의 감정을 기분으로 사용
    final emotions = parseEmotions(diary['emotions'] as Map<String, dynamic>?);
    if (emotions.isEmpty) return null;
    
    String? dominantMood;
    int maxPercentage = 0;
    
    emotions.forEach((emotion, percentage) {
      if (percentage > maxPercentage) {
        maxPercentage = percentage;
        dominantMood = emotion;
      }
    });
    
    return dominantMood;
  }
  
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('홈'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.settings),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 달력
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildCalendar(),
              ),
              const SizedBox(height: 30),
              // 기분 변화 그래프 (간단한 버전)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '일주일간 기분 변화',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _buildSimpleMoodChart(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    DateTime now = DateTime.now();
    DateTime currentMonth = DateTime(_focusedDay.year, _focusedDay.month);
    DateTime firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    int daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    int firstWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        // 달력 헤더
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBlue,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  color: CupertinoColors.white,
                ),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                  });
                },
              ),
              Text(
                '${_focusedDay.year}년 ${_focusedDay.month}월',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.white,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.white,
                ),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                  });
                },
              ),
            ],
          ),
        ),
        // 달력 그리드
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 요일 헤더
              Row(
                children: const [
                  Expanded(child: Center(child: Text('월', style: TextStyle(fontWeight: FontWeight.bold)))),
                  Expanded(child: Center(child: Text('화', style: TextStyle(fontWeight: FontWeight.bold)))),
                  Expanded(child: Center(child: Text('수', style: TextStyle(fontWeight: FontWeight.bold)))),
                  Expanded(child: Center(child: Text('목', style: TextStyle(fontWeight: FontWeight.bold)))),
                  Expanded(child: Center(child: Text('금', style: TextStyle(fontWeight: FontWeight.bold)))),
                  Expanded(child: Center(child: Text('토', style: TextStyle(fontWeight: FontWeight.bold)))),
                  Expanded(child: Center(child: Text('일', style: TextStyle(fontWeight: FontWeight.bold)))),
                ],
              ),
              const SizedBox(height: 16),
              // 날짜 그리드
              ..._buildCalendarDays(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCalendarDays() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday; // 월요일=1, 일요일=7
    final daysInMonth = lastDayOfMonth.day;
    
    List<Widget> rows = [];
    List<Widget> currentRow = [];
    
    // 이전 달의 마지막 날들 (월요일부터 시작하므로 firstWeekday-1만큼 빈칸)
    for (int i = 0; i < firstWeekday - 1; i++) {
      currentRow.add(const Expanded(
        child: SizedBox(height: 40),
      ));
    }
    
    // 현재 달의 날들
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      final isSelected = date.year == _selectedDay.year && 
                        date.month == _selectedDay.month && 
                        date.day == _selectedDay.day;
      final isToday = date.year == DateTime.now().year && 
                      date.month == DateTime.now().month && 
                      date.day == DateTime.now().day;
      
      // 일기가 작성된 날짜인지 확인
      final hasDiary = globalDiaries.any((diary) => 
        diary['date'].year == date.year && 
        diary['date'].month == date.month && 
        diary['date'].day == date.day
      );
      
      // 기분 상태 확인
      final mood = _getMoodForDate(date);
      final moodColor = _getMoodColor(mood);
      
      currentRow.add(
        Expanded(
          child: GestureDetector(
            onTap: isToday ? null : () {
              setState(() {
                _selectedDay = date;
              });
            },
            child: Container(
              height: 40,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? CupertinoColors.systemBlue 
                    : mood != null 
                        ? moodColor.withOpacity(0.3)
                        : CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(8),
                border: isToday 
                    ? Border.all(color: CupertinoColors.systemBlue, width: 2)
                    : mood != null
                        ? Border.all(color: moodColor, width: 2)
                        : hasDiary
                            ? Border.all(color: CupertinoColors.systemGreen, width: 2)
                            : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    color: isSelected 
                        ? CupertinoColors.white
                        : mood != null
                            ? moodColor
                            : CupertinoColors.label,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      
      if (currentRow.length == 7) {
        rows.add(Row(children: currentRow));
        currentRow = [];
      }
    }
    
    // 마지막 주 처리
    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) {
        currentRow.add(const Expanded(child: SizedBox(height: 40)));
      }
      rows.add(Row(children: currentRow));
    }
    
    return rows;
  }

  Widget _buildSimpleMoodChart() {
    const List<String> days = ['월', '화', '수', '목', '금', '토', '일'];
    const List<String> moodEmojis = ['😊', '🤔', '😡', '😊', '🤔', '😡', '😊']; // 기분 이모지

    return Column(
      children: [
        // 기분 이모지 표시
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            moodEmojis[index],
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        days[index],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),
        // 범례
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('😊', '좋음', CupertinoColors.systemGreen),
              _buildLegendItem('🤔', '평범함', CupertinoColors.systemYellow),
              _buildLegendItem('😡', '나쁨', CupertinoColors.systemRed),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String emoji, String label, Color color) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// 일기보기 탭
class DiaryViewTab extends StatefulWidget {
  const DiaryViewTab({super.key});

  @override
  State<DiaryViewTab> createState() => _DiaryViewTabState();
}

class _DiaryViewTabState extends State<DiaryViewTab> {
  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 표시될 때 데이터 새로고침
    setState(() {});
  }

  void _loadDiaries() {
    // 저장된 일기 데이터가 이미 로드되어 있으므로 setState만 호출
    setState(() {
      // globalDiaries는 이미 main()에서 로드되었으므로 추가 로드 불필요
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('일기보기'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.refresh),
              onPressed: () async {
                await loadDiariesFromLocal();
                setState(() {});
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: globalDiaries.isEmpty
            ? const Center(
                child: Text('저장된 일기가 없습니다.'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: globalDiaries.length,
                itemBuilder: (context, index) {
                  final diary = globalDiaries[index];
                  return _buildDiaryCard(diary, index);
                },
              ),
      ),
    );
  }

  Widget _buildDiaryCard(Map<String, dynamic> diary, int index) {
    final emotions = parseEmotions(diary['emotions'] as Map<String, dynamic>?);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${diary['date'].year}년 ${diary['date'].month}월 ${diary['date'].day}일',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.eye),
                      onPressed: () => _showDiaryDetail(diary),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.delete, color: CupertinoColors.systemRed),
                      onPressed: () => _confirmDeleteDiary(index),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              diary['summary'],
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            _buildEmotionIndicators(emotions),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionIndicators(Map<String, int> emotions) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: emotions.entries.map((entry) {
        return _buildEmotionIndicator(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildEmotionIndicator(String emotion, int percentage) {
    Color color;
    if (emotion == '좋음') {
      color = CupertinoColors.systemGreen;
    } else if (emotion == '평범함') {
      color = CupertinoColors.systemYellow;
    } else {
      color = CupertinoColors.systemRed;
    }

    return Column(
      children: [
        Text(
          emotion,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(percentage / 100),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDiaryDetail(Map<String, dynamic> diary) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('${diary['date'].year}년 ${diary['date'].month}월 ${diary['date'].day}일'),
        message: Text(diary['summary'] ?? ''),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('상세 보기'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => DiaryDetailScreen(diary: diary),
                ),
              );
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('감정 분석 보기'),
            onPressed: () {
              Navigator.pop(context);
              _showEmotionAnalysis(diary);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('닫기'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showEmotionAnalysis(Map<String, dynamic> diary) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('감정 분석'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            ...parseEmotions(diary['emotions'] as Map<String, dynamic>? ?? {}).entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey5,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: entry.value / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: entry.key == '나쁨' 
                                  ? CupertinoColors.systemRed
                                  : entry.key == '평범함'
                                      ? CupertinoColors.systemYellow
                                      : CupertinoColors.systemGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${entry.value}%', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDiary(int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('일기 삭제'),
        content: const Text('정말로 이 일기를 삭제하시겠습니까?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('삭제'),
            onPressed: () async {
              globalDiaries.removeAt(index);
              await saveDiariesToLocal();
              setState(() {});
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// 일기쓰기 탭
class DiaryWriteTab extends StatefulWidget {
  const DiaryWriteTab({super.key});

  @override
  State<DiaryWriteTab> createState() => _DiaryWriteTabState();
}

class _DiaryWriteTabState extends State<DiaryWriteTab> {
  DateTime _selectedDate = DateTime.now();
  String _diaryResult = '';
  bool _isLoading = false;
  bool _usePrompt = false;
  final TextEditingController _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 탭에 진입할 때 자동으로 서버 연결 테스트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _testServerConnection();
    });
  }

  // 서버 연결 테스트
  void _testServerConnection() async {
    try {
      print('🔍 서버 연결 상태를 확인합니다...');
      final result = await ApiService.checkModelStatus();
      
      // 연결 성공 시 상세 정보 출력
      print('✅ 서버 연결 성공!');
      print('📊 서버 정보: ${result['message']}');
      print('🔄 사용 가능한 엔드포인트: ${result['available_endpoints']}');
      
      // 연결 성공 알림 (선택적)
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('연결 성공'),
            content: const Text('파이썬 서버와 성공적으로 연결되었습니다!'),
            actions: [
              CupertinoDialogAction(
                child: const Text('확인'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ 서버 연결 실패: $e');
      
      // 연결 실패 시 상세한 오류 정보 제공
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('서버 연결 오류'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('파이썬 서버에 연결할 수 없습니다.'),
                const SizedBox(height: 8),
                Text(
                  '오류: $e',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '확인사항:\n'
                  '• 파이썬 서버가 실행 중인지 확인\n'
                  '• 포트 8000이 사용 가능한지 확인\n'
                  '• 방화벽 설정 확인',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('확인'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                child: const Text('다시 시도'),
                onPressed: () {
                  Navigator.pop(context);
                  _testServerConnection();
                },
              ),
            ],
          ),
        );
      }
    }
  }

  void _showDatePicker() {
    DateTime tempDate = _selectedDate; // 임시 날짜 변수
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.systemGrey5,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                    Text(
                      '날짜 선택',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        setState(() {
                          _selectedDate = tempDate;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ),
              // 캘린더
              Expanded(
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return _buildSimpleCalendar(tempDate, (newDate) {
                      setModalState(() {
                        tempDate = newDate;
                      });
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleCalendar(DateTime selectedDate, Function(DateTime) onDateChanged) {
    DateTime now = DateTime.now();
    DateTime currentMonth = DateTime(selectedDate.year, selectedDate.month);
    int daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    
    // 첫 번째 날의 요일 (일요일=1, 월요일=2, ..., 토요일=7)
    int firstWeekday = DateTime(selectedDate.year, selectedDate.month, 1).weekday;
    
    // 한국식 요일 순서로 변환 (월요일=0, 화요일=1, ..., 일요일=6)
    int koreanFirstWeekday = (firstWeekday + 5) % 7;
    
    return Column(
      children: [
        // 월 네비게이션
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                onPressed: () {
                  DateTime prevMonth = DateTime(
                    currentMonth.year,
                    currentMonth.month - 1,
                    selectedDate.day,
                  );
                  if (prevMonth.month != currentMonth.month) {
                    prevMonth = DateTime(prevMonth.year, prevMonth.month, 1);
                  }
                  onDateChanged(prevMonth);
                },
                child: const Icon(CupertinoIcons.left_chevron),
              ),
              Text(
                '${currentMonth.year}년 ${currentMonth.month}월',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CupertinoButton(
                onPressed: () {
                  DateTime nextMonth = DateTime(
                    currentMonth.year,
                    currentMonth.month + 1,
                    selectedDate.day,
                  );
                  if (nextMonth.month != currentMonth.month) {
                    nextMonth = DateTime(nextMonth.year, nextMonth.month, 1);
                  }
                  onDateChanged(nextMonth);
                },
                child: const Icon(CupertinoIcons.right_chevron),
              ),
            ],
          ),
        ),
        
        // 요일 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        // 날짜 그리드
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                int dayNumber = index - koreanFirstWeekday + 1;
                
                // 이전/다음 달의 날짜
                if (dayNumber <= 0 || dayNumber > daysInMonth) {
                  return Container();
                }
                
                DateTime currentDate = DateTime(currentMonth.year, currentMonth.month, dayNumber);
                bool isSelected = selectedDate.year == currentDate.year &&
                                selectedDate.month == currentDate.month &&
                                selectedDate.day == currentDate.day;
                bool isToday = now.year == currentDate.year &&
                              now.month == currentDate.month &&
                              now.day == currentDate.day;
                bool isFuture = currentDate.isAfter(now);
                
                return GestureDetector(
                  onTap: isFuture ? null : () {
                    onDateChanged(currentDate);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? CupertinoColors.systemBlue 
                          : isToday 
                              ? CupertinoColors.systemOrange.withOpacity(0.2)
                              : CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: CupertinoColors.systemBlue, width: 2)
                          : isToday 
                              ? Border.all(color: CupertinoColors.systemOrange, width: 1)
                              : null,
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                          color: isFuture 
                              ? CupertinoColors.systemGrey3
                              : isSelected 
                                  ? CupertinoColors.white
                                  : CupertinoColors.label,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'txt'],
      );

      if (result != null) {
        setState(() {
          _isLoading = true;
        });

        String filePath = result.files.single.path!;
        String fileExtension = result.files.single.extension?.toLowerCase() ?? '';

        if (fileExtension == 'txt') {
          _processTxtFile(filePath);
        } else if (fileExtension == 'zip') {
          _processZipFile(filePath);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('파일 처리 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _processTxtFile(String filePath) async {
    try {
      File file = File(filePath);
      String selectedDay = "${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일";
      final result = await ApiService.autoDiary(
        file: file,
        searchLog: '없음',
        userPrompt: _usePrompt ? _promptController.text : null,
        usePrompt: _usePrompt,
        useDateAnalysis: true,
        targetDate: selectedDay,
      );
      setState(() {
        _diaryResult = result['summary'] ?? '일기 요약';
        _isLoading = false;
      });
      final newDiary = {
        'date': _selectedDate,
        'title': '${_selectedDate.month}월 ${_selectedDate.day}일의 일기',
        'summary': result['summary'],
        'emotions': result['emotions'] ?? {'좋음': 33, '평범함': 34, '나쁨': 33},
        '상황설명': result['상황설명'],
        '감정표현': result['감정표현'],
        '공감과인정': result['공감과인정'],
        '따뜻한위로': result['따뜻한위로'],
        '실용적제안': result['실용적제안'],
        'kakao_text': result['kakao_text'],
      };
      globalDiaries.add(newDiary);
      sortDiariesByDate();
      await saveDiariesToLocal();
      if (mounted) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => DiaryDetailScreen(diary: newDiary),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('일기 생성 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _processZipFile(String filePath) async {
    try {
      File file = File(filePath);
      String selectedDay = "${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일";
      final result = await ApiService.autoDiary(
        file: file,
        searchLog: '없음',
        userPrompt: _usePrompt ? _promptController.text : null,
        usePrompt: _usePrompt,
        useDateAnalysis: true,
        targetDate: selectedDay,
      );
      setState(() {
        _diaryResult = result['summary'] ?? '일기 요약';
        _isLoading = false;
      });
      final newDiary = {
        'date': _selectedDate,
        'title': '${_selectedDate.month}월 ${_selectedDate.day}일의 일기',
        'summary': result['summary'],
        'emotions': result['emotions'] ?? {'좋음': 33, '평범함': 34, '나쁨': 33},
        '상황설명': result['상황설명'],
        '감정표현': result['감정표현'],
        '공감과인정': result['공감과인정'],
        '따뜻한위로': result['따뜻한위로'],
        '실용적제안': result['실용적제안'],
        'kakao_text': result['kakao_text'],
      };
      globalDiaries.add(newDiary);
      sortDiariesByDate();
      await saveDiariesToLocal();
      if (mounted) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => DiaryDetailScreen(diary: newDiary),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('일기 생성 중 오류가 발생했습니다: $e');
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CupertinoPageScaffold(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CupertinoActivityIndicator(radius: 20),
                const SizedBox(height: 20),
                const Text('일기를 작성하고 있습니다...'),
              ],
            ),
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('일기쓰기'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.settings),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 날짜 선택
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '날짜 선택',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CupertinoButton(
                      onPressed: _showDatePicker,
                      child: Text(
                        '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 사용자 프롬프트 옵션
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '일기 스타일 설정',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 사용자 프롬프트 토글
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('사용자 프롬프트 사용'),
                        CupertinoSwitch(
                          value: _usePrompt,
                          onChanged: (value) {
                            setState(() {
                              _usePrompt = value;
                              if (!value) _promptController.text = '';
                            });
                          },
                        ),
                      ],
                    ),
                    
                    if (_usePrompt) ...[
                      const SizedBox(height: 16),
                      CupertinoTextField(
                        placeholder: '원하는 일기 스타일이나 특별한 요청사항을 입력하세요',
                        controller: _promptController,
                        maxLines: 3,
                        onChanged: (value) {
                          setState(() {
                            _promptController.text = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 파일 업로드
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: _pickFile,
                  child: const Text('파일 업로드'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 설정 화면
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _fontSize = 16.0;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('설정'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            
            // 앱 정보
            _buildSettingsItem(
              icon: CupertinoIcons.info_circle,
              title: '앱 정보',
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => const AppInfoScreen()),
                );
              },
            ),
            
            // 폰트 크기
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CupertinoColors.systemGrey4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.textformat_size, color: CupertinoColors.systemBlue),
                      const SizedBox(width: 12),
                      const Text(
                        '폰트 크기',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('작게', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: CupertinoSlider(
                          value: _fontSize,
                          min: 12.0,
                          max: 20.0,
                          onChanged: (value) {
                            setState(() {
                              _fontSize = value;
                            });
                          },
                        ),
                      ),
                      const Text('크게', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Center(
                    child: Text(
                      '샘플 텍스트',
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  ),
                ],
              ),
            ),
            
            // 사용설명 다시보기
            _buildSettingsItem(
              icon: CupertinoIcons.question_circle,
              title: '사용설명 다시보기',
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  CupertinoPageRoute(builder: (context) => const TutorialScreen()),
                );
              },
            ),
            
            // 데이터 재설정
            _buildSettingsItem(
              icon: CupertinoIcons.refresh,
              title: '데이터 재설정',
              onTap: () {
                _showResetDataDialog();
              },
            ),
            
            // 비밀번호 초기화
            _buildSettingsItem(
              icon: CupertinoIcons.lock,
              title: '비밀번호 초기화',
              onTap: () {
                _showResetPasswordDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(16),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, color: CupertinoColors.systemBlue),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDataDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('데이터 재설정'),
        content: const Text('모든 일기 데이터가 삭제됩니다.\n정말로 재설정하시겠습니까?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('재설정'),
            onPressed: () async {
              globalDiaries.clear();
              // 로컬 저장소도 초기화
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('saved_diaries');
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('비밀번호 초기화'),
        content: const Text('비밀번호가 초기화됩니다.\n다음 앱 실행 시 새로운 비밀번호를 설정해야 합니다.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('초기화'),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_password');
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// 앱 정보 화면
class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('앱 정보'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 앱 아이콘
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  CupertinoIcons.book_fill,
                  size: 50,
                  color: CupertinoColors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 앱 소개
            _buildInfoSection(
              title: '앱 소개',
              content: '감성 일기는 AI를 활용하여 사용자의 감정을 분석하고 일기를 작성해주는 앱입니다. '
              '일상의 기록을 통해 자신의 감정을 더 잘 이해하고 관리할 수 있도록 도와줍니다.',
            ),
            
            // 앱 버전
            _buildInfoSection(
              title: '앱 버전',
              content: '1.0.0',
            ),
            
            // 개발자
            _buildInfoSection(
              title: '개발자',
              content: '감성 일기 개발팀\ncontact@emotiondiary.com',
            ),
            
            // 라이선스
            _buildInfoSection(
              title: '라이선스',
              content: 'MIT License\n\n이 앱은 오픈소스 라이선스 하에 배포됩니다.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// 일기 상세 화면 위젯
class DiaryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> diary;
  const DiaryDetailScreen({super.key, required this.diary});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${diary['date'].year}년 ${diary['date'].month}월 ${diary['date'].day}일의 일기'),
        previousPageTitle: '뒤로',
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('요약', diary['summary'], icon: '📝'),
            _buildSection('상황 설명', diary['상황설명'], icon: '📄'),
            _buildSection('감정 표현', diary['감정표현'], icon: '😊'),
            _buildSection('공감과 인정', diary['공감과인정'], icon: '👏'),
            _buildSection('따듯한 위로', diary['따뜻한위로'], icon: '🤗'),
            _buildSection('실용적 제안', diary['실용적제안'], icon: '💡'),
            _buildSection('카톡 원본', diary['kakao_text'], icon: '💬', isLongText: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String? content, {String? icon, bool isLongText = false}) {
    final displayContent = (content == null || content.trim().isEmpty) ? '내용 없음' : content;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          isLongText
              ? Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CupertinoColors.systemGrey4),
                  ),
                  child: SingleChildScrollView(
                    child: Text(displayContent, style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                  ),
                )
              : Text(displayContent, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

// emotions 변환 함수 추가
Map<String, int> parseEmotions(Map<String, dynamic>? raw) {
  if (raw == null) return {'좋음': 33, '평범함': 34, '나쁨': 33};
  return raw.map((k, v) => MapEntry(k, v is int ? v : int.tryParse(v.toString()) ?? 0));
}
