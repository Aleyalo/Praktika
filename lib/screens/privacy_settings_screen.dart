import 'package:flutter/material.dart';
import '../services/privacy_service.dart';
import '../utils/error_handler.dart';
import 'package:collection/collection.dart';

class PrivacySettingsScreen extends StatefulWidget {
  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late Future<Map<String, bool>> _settingsFuture;
  late Map<String, bool> _currentSettings;
  late Map<String, bool> _editedSettings;

  @override
  void initState() {
    super.initState();
    _settingsFuture = _fetchPrivacySettings().then((settings) {
      setState(() {
        _currentSettings = settings;
        _editedSettings = Map.from(settings);
      });
      return settings;
    });
  }

  Future<Map<String, bool>> _fetchPrivacySettings() async {
    try {
      final settings = await PrivacyService().getPrivacySettings();
      return settings;
    } catch (e) {
      handleError(context, e.toString());
      return {};
    }
  }

  Future<void> _saveSettings() async {
    // Сравниваем значения вручную
    bool settingsEqual = MapEquality().equals(_currentSettings, _editedSettings);
    if (settingsEqual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Настройки не изменились')),
      );
      return;
    }
    try {
      final success = await PrivacyService().updatePrivacySettings(
        settings: _editedSettings,
        context: context, // Передаем контекст
      );
      if (success) {
        setState(() {
          _currentSettings = Map.from(_editedSettings);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Настройки сохранены')),
        );
      } else {
        throw Exception('Не удалось сохранить настройки');
      }
    } catch (e) {
      handleError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Приватность'), backgroundColor: Colors.yellow),
      body: FutureBuilder(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки'));
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSettingTile("Скрыть дату рождения", "birthday"),
                  _buildSettingTile("Скрыть номер телефона", "number"),
                  _buildSettingTile("Скрыть почту", "mail"),
                  _buildSettingTile("Скрыть ссылки", "links"),
                  // Кнопка "Сохранить" — справа, на уровне других пунктов
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: Size(100, 40),
                      ),
                      onPressed: _saveSettings,
                      child: Text("Сохранить"),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSettingTile(String label, String key) {
    return ListTile(
      title: Text(label),
      trailing: Switch(
        value: _editedSettings[key] ?? false,
        onChanged: (value) {
          setState(() {
            _editedSettings[key] = value;
          });
        },
      ),
    );
  }
}