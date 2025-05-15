import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/main_screen.dart';

class ConfirmPhoneScreen extends StatefulWidget {
  final String newPhone;
  final String? guid; // Добавляем параметр guid
  final String? deviceId; // Добавляем параметр deviceId
  final bool isRecovery; // Добавляем параметр isRecovery для восстановления доступа
  final Function(String code)? onConfirm; // Добавляем функцию для подтверждения номера телефона
  const ConfirmPhoneScreen({
    Key? key,
    required this.newPhone,
    required this.guid, // Делаем обязательным
    required this.deviceId, // Делаем обязательным
    this.isRecovery = false, // По умолчанию false
    this.onConfirm, // Добавляем функцию для подтверждения номера телефона
  }) : super(key: key);

  @override
  _ConfirmPhoneScreenState createState() => _ConfirmPhoneScreenState();
}

class _ConfirmPhoneScreenState extends State<ConfirmPhoneScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _confirmCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      if (widget.onConfirm != null) {
        await widget.onConfirm!(_codeController.text);
      } else {
        final authService = AuthService();
        final result = await authService.confirmDevice(
          code: _codeController.text,
          login: '', // Логин не нужен для подтверждения номера
          password: '', // Пароль не нужен для подтверждения номера
          deviceId: widget.deviceId!,
          context: context,
        );
        if (result) {
          print('Код подтверждения успешно подтвержден');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Номер телефона успешно подтвержден')),
          );
          Navigator.pop(context, true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen()),
          );
        } else {
          print('Код подтверждения неверен');
          setState(() {
            _errorMessage = 'Код подтверждения неверен';
          });
        }
      }
    } catch (e) {
      print('Произошла ошибка при подтверждении кода: $e');
      setState(() {
        _errorMessage = 'Произошла ошибка: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Подтверждение номера')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'На указанный номер будет совершен звонок. Введите последние 4 цифры номера, с которого поступил звонок:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: InputDecoration(
                  labelText: 'Код подтверждения',
                  border: OutlineInputBorder(),
                  errorText: _errorMessage,
                ),
              ),
              SizedBox(height: 20),
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmCode,
                    child: Text('Подтвердить'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}