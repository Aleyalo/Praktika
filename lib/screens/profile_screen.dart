import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  Future<Map<String, dynamic>> _fetchProfileData() async {
    try {
      print('Fetching profile data...');
      final authService = AuthService();
      final userData = await authService.getUserData();
      print('User data from auth service: $userData');
      final profileService = ProfileService();
      final profileData = await profileService.getProfile();
      print('Profile data from profile service: $profileData');

      // Find main job
      final employment = List<Map<String, dynamic>>.from(userData['employment'] ?? []);
      print('Employment data: $employment');
      Map<String, dynamic> mainJob = {};
      try {
        mainJob = employment.firstWhere(
              (job) => job['type'] == 'Основное место работы',
          orElse: () => {},
        );
      } catch (e) {
        print('Error finding main job: $e');
      }

      // Combine data with priority to profile data
      final combinedData = {
        ...userData,
        ...profileData,
        'fullName': profileData['fullName'] ??
            '${userData['surname']} ${userData['name']} ${userData['patronymic']}'.trim(),
        'position': mainJob['post'] ?? '',
        'organization': mainJob['organization_name'] ?? '',
        'department': mainJob['department_name'] ?? '',
        'mainJob': mainJob,
      };
      print('Combined profile data: $combinedData');
      return combinedData;
    } catch (e) {
      print('Error fetching profile data: $e');
      return widget.user;
    }
  }

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfileData();
  }

  Future<void> _launchUrl(String label, String url) async {
    if (url.isEmpty || url == label || url == '1') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Нет доступной ссылки для $label')),
      );
      return;
    }

    Uri? uri;

    // Автоматическое определение типа ссылки и её коррекция
    if (label.toLowerCase() == 'vk' && !url.startsWith('http')) {
      uri = Uri.parse('https://vk.com/$url');
    } else if (label.toLowerCase() == 'telegram' && !url.startsWith('tg://')) {
      uri = Uri.parse('tg://resolve?domain=$url');
    } else if (label.toLowerCase() == 'whatsapp' && !url.startsWith('https')) {
      uri = Uri.parse('https://wa.me/$url');
    } else if (url.startsWith('www.') || url.contains('.com') || url.contains('.ru')) {
      uri = Uri.parse('https://$url');
    } else {
      uri = Uri.tryParse(url);
    }

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final fallbackUri = uri ?? Uri.parse('https://$url');
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось открыть ссылку')),
        );
      }
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
            return Center(child: Text('Ошибка загрузки данных: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Данные пользователя недоступны'));
          } else {
            final userData = snapshot.data!;
            print('Building profile with data: $userData');
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: userData['photo'] != null && userData['photo'].isNotEmpty
                          ? MemoryImage(base64Decode(userData['photo']))
                          : null,
                      child: userData['photo'] == null || userData['photo'].isEmpty
                          ? Icon(Icons.person, size: 50, color: Colors.grey.shade700)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ProfileField(label: 'ФИО', value: userData['fullName']?.toString() ?? ''),
                  ProfileField(label: 'Пол', value: userData['gender']?.toString() ?? ''),
                  ProfileField(label: 'Дата рождения', value: userData['birthday']?.split('T')[0] ?? ''),
                  if (userData['email']?.toString().isNotEmpty == true)
                    ProfileField(label: 'Email', value: userData['email']?.toString() ?? ''),
                  if (userData['phone']?.toString().isNotEmpty == true)
                    ProfileField(label: 'Телефон', value: userData['phone']?.toString() ?? ''),
                  const SizedBox(height: 20),
                  Text(
                    'Основное место работы',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ProfileField(
                    label: 'Организация',
                    value: userData['organization']?.toString() ?? 'Не указано',
                  ),
                  ProfileField(
                    label: 'Подразделение',
                    value: userData['department']?.toString() ?? 'Не указано',
                  ),
                  ProfileField(
                    label: 'Должность',
                    value: userData['position']?.toString() ?? 'Не указано',
                  ),
                  const SizedBox(height: 20),
                  if (userData['links'] != null && userData['links'] is Map<String, dynamic>)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ссылки',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ...userData['links'].entries.map((entry) =>
                            ProfileLink(label: entry.key, url: entry.value, launchUrl: (l, u) => _launchUrl(l, u))).toList(),
                      ],
                    ),
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

  const ProfileField({Key? key, required this.label, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text('$label:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class ProfileLink extends StatelessWidget {
  final String label;
  final String url;
  final Function(String, String) launchUrl;

  const ProfileLink({
    Key? key,
    required this.label,
    required this.url,
    required this.launchUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text('$label:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () => launchUrl(label, url),
              child: Text(
                url,
                style: TextStyle(fontSize: 16, color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
