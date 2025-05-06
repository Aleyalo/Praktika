import 'package:flutter/material.dart';
import '../services/phone_edit_service.dart';

class ConfirmPhoneScreen extends StatefulWidget {
  final String newPhone;
  const ConfirmPhoneScreen({Key? key, required this.newPhone}) : super(key: key);

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
      final result = await PhoneEditService.editPhoneNumber(
        newPhone: widget.newPhone,
        step: 2,
      );

      if (result['success'] == true) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Номер телефона успешно изменен')),
        );
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Ошибка подтверждения номера';
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
            SizedBox(height: 20),
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      childAspectRatio: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(9, (index) {
        return ElevatedButton(
          onPressed: () {
            if (_codeController.text.length < 4) {
              _codeController.text += (index + 1).toString();
            }
          },
          child: Text('${index + 1}'),
        );
      })
        ..addAll([
          ElevatedButton(
            onPressed: () {
              if (_codeController.text.isNotEmpty) {
                _codeController.text = _codeController.text
                    .substring(0, _codeController.text.length - 1);
              }
            },
            child: Icon(Icons.backspace),
          ),
          ElevatedButton(
            onPressed: () {
              if (_codeController.text.length < 4) {
                _codeController.text += '0';
              }
            },
            child: Text('0'),
          ),
          ElevatedButton(
            onPressed: _confirmCode,
            child: Text('OK'),
          ),
        ]),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
