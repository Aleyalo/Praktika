import 'package:flutter/material.dart';
import './screens/login_screen.dart'; // Импорт экрана входа
import './screens/main_screen.dart'; // Импорт главного экрана
import './services/auth_service.dart'; // Импорт AuthService
import './services/moderation_service.dart'; // Импорт ModerationService
import 'package:intl/intl.dart'; // Для форматирования даты
import 'package:intl/date_symbol_data_local.dart'; // Для локализации даты
import 'package:flutter_localizations/flutter_localizations.dart'; // Для локализации

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isBackgroundAuthAttempted = false;
  bool _isLoggedIn = false;
  bool _isModerationPending = false; // Добавляем состояние для модерации
  String _moderationMessage = ''; // Добавляем сообщение о модерации

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized(); // Убедимся, что Flutter binding инициализирован
    initializeDateFormatting('ru_RU', null); // Инициализируем русскую локаль для дат
    _checkModerationStatus(); // Добавляем вызов метода проверки модерации
    _performBackgroundAuth();
  }

  Future<void> _checkModerationStatus() async {
    final moderationService = ModerationService();
    final moderationGuid = await AuthService.getModerationGUID();
    if (moderationGuid != null) {
      try {
        final moderationStatus = await moderationService.checkModerationStatus(moderationGuid);
        if (moderationStatus['success'] == true) {
          final status = moderationStatus['status'];
          if (status == 'На модерации') {
            setState(() {
              _isModerationPending = true; // Устанавливаем флаг модерации
              _moderationMessage = 'Ваша заявка на регистрацию находится на модерации. Ожидайте около 3 дней.';
            });
          } else {
            await AuthService.clearModerationGUID(); // Удаляем GUID модерации, если статус не "На модерации"
          }
        }
      } catch (e) {
        print('Ошибка при проверке статуса модерации: $e');
      }
    }
  }

  Future<void> _performBackgroundAuth() async {
    final authService = AuthService();
    final isLoggedIn = await authService.backgroundLogin();
    setState(() {
      _isLoggedIn = isLoggedIn;
      _isBackgroundAuthAttempted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AuthService.navigatorKey, // Устанавливаем навигационный ключ
      debugShowCheckedModeBanner: false,
      title: 'Company App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      supportedLocales: [Locale('ru', 'RU')], // Поддерживаемая локаль
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // Добавляем Cupertino локализацию
      ],
      localeResolutionCallback: (Locale? locale, Iterable<Locale> supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode &&
              supportedLocale.countryCode == locale?.countryCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      home: _isModerationPending
          ? LoginScreen(isModerationPending: _isModerationPending, moderationMessage: _moderationMessage)
          : _isBackgroundAuthAttempted
          ? _isLoggedIn
          ? MainScreen()
          : LoginScreen()
          : Center(child: CircularProgressIndicator()),
    );
  }
}