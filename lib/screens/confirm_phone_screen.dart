// lib/screens/confirm_phone_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/main_screen.dart';

class ConfirmPhoneScreen extends StatefulWidget {
  final String newPhone;
  final String? deviceId;
  final String? guid; // Добавляем параметр guid
  const ConfirmPhoneScreen({
    Key? key,
    required this.newPhone,
    this.deviceId, // Делаем необязательным
    this.guid, // Делаем необязательным
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
      final result = await AuthService().confirmDevice(
        code: _codeController.text,
        deviceId: widget.deviceId!,
        context: context,
      );
      if (result) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Номер телефона успешно подтверждён')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Код подтверждения неверен';
        });
      }
    } catch (e) {
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