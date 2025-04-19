// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import 'dart:convert'; // Для base64Decode
import 'package:url_launcher/url_launcher.dart'; // Для canLaunchUrl и launchUrl
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ProfileScreen({required this.user});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfileData();
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    try {
      final authService = AuthService();
      final userData = await authService.getUserData();
      final profileService = ProfileService();
      final profileData = await profileService.getProfile();
      // Объединяем данные из двух источников
      final combinedData = {
        ...userData,
        ...profileData,
        'fullName': profileData['fullName'] ?? '${userData['surname']} ${userData['name']} ${userData['patronymic']}'.trim(),
      };
      return combinedData;
    } catch (e) {
      print('Ошибка при получении данных профиля: $e');
      return widget.user; // Возвращаем существующие данные пользователя, если произошла ошибка
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Профиль'), backgroundColor: Colors.yellow),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки данных'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Данные пользователя недоступны'));
          } else {
            final userData = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: userData['photo'] != null && userData['photo'].isNotEmpty
                        ? MemoryImage(base64Decode(userData['photo']))
                        : null,
                    child: userData['photo'] == null || userData['photo'].isEmpty
                        ? Icon(Icons.person, size: 50, color: Colors.grey.shade700)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  ProfileField(label: 'ФИО', value: userData['fullName']?.toString() ?? ''),
                  ProfileField(label: 'Гендер', value: userData['gender']?.toString() ?? ''),
                  ProfileField(label: 'Дата рождения', value: userData['birthday']?.split('T')[0] ?? ''),
                  ProfileField(label: 'Email', value: userData['email']?.toString() ?? ''),
                  ProfileField(label: 'Телефон', value: userData['phone']?.toString() ?? ''),
                  ProfileField(label: 'Организация', value: userData['organization']?.toString() ?? ''),
                  ProfileField(label: 'Подразделение', value: userData['department']?.toString() ?? ''),
                  ProfileField(label: 'Должность', value: userData['position']?.toString() ?? ''),
                  ProfileField(label: 'СНИЛС', value: userData['snils']?.toString() ?? ''),
                  const SizedBox(height: 20),
                  Text(
                    'Ссылки',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (userData['links'] != null && userData['links'] is Map<String, dynamic>)
                    ...userData['links'].entries.map((entry) {
                      return ProfileLink(label: entry.key, url: entry.value);
                    }).toList(),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final String value;
  const ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text('$label:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class ProfileLink extends StatelessWidget {
  final String label;
  final String url;
  const ProfileLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text('$label:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          GestureDetector(
            onTap: () async {
              try {
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Не удалось открыть ссылку')),
                  );
                }
              } catch (e) {
                print('Ошибка при открытии ссылки: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка при открытии ссылки')),
                );
              }
            },
            child: Text(
              url,
              style: TextStyle(fontSize: 16, color: Colors.blue, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}