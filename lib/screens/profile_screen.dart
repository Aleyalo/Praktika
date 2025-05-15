import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  Future<Map<String, dynamic>> _fetchProfileData(BuildContext context) async {
    try {
      print('Fetching profile data...');
      final authService = AuthService();
      final userData = await authService.getUserData();
      print('User data from auth service: $userData');
      final profileService = ProfileService();
      final profileData = await profileService.getProfile(context); // Передаем контекст
      print('Profile data from profile service: $profileData');
      // Combine data with priority to profile data
      final combinedData = {
        ...userData,
        ...profileData,
        'fullName': profileData['fullName'] ??
            '${userData['surname']} ${userData['name']} ${userData['patronymic']}'.trim(),
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
    _profileFuture = _fetchProfileData(context); // Передаем контекст
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
    if (label.toLowerCase() == 'vk' && !url.startsWith('https://vk.com/ ')) {
      uri = Uri.parse('https://vk.com/ ${url.replaceAll('@', '')}');
    } else if (label.toLowerCase() == 'telegram' && !url.startsWith('tg://')) {
      uri = Uri.parse('tg://resolve?domain=${url.replaceAll('@', '')}');
    } else if (label.toLowerCase() == 'whatsapp' && !url.startsWith('https://')) {
      uri = Uri.parse('https://wa.me/ ${url.replaceAll('+', '')}');
    } else if (url.startsWith('www.') || url.contains('.com') || url.contains('.ru')) {
      uri = Uri.parse('https://$url');
    } else {
      uri = Uri.tryParse(url);
    }
    if (uri != null) {
      if (label.toLowerCase() == 'vk') {
        // Попытка открыть ссылку в приложении ВКонтакте
        final vkAppUri = Uri.parse('vk://vk.com/${url.replaceAll('@', '')}');
        if (await canLaunchUrl(vkAppUri)) {
          await launchUrl(vkAppUri, mode: LaunchMode.externalApplication);
        } else {
          // Если приложение ВКонтакте не установлено, открываем ссылку в браузере
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Не удалось открыть ссылку')),
            );
          }
        }
      } else {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось открыть ссылку')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть ссылку')),
      );
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
                  const SizedBox(height: 20),
                  Text(
                    'Места работы',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._buildEmploymentList(userData['employment']),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  List<Widget> _buildEmploymentList(List<dynamic>? employment) {
    if (employment == null || employment.isEmpty) {
      return [Text('Нет информации о местах работы')];
    }
    // Находим основное место работы
    final mainJob = employment.firstWhere(
          (job) => job['type'] == 'Основное место работы',
      orElse: () => null,
    );
    // Создаём список всех мест работы
    final allJobs = employment.toList();
    // Если основное место работы найдено, удаляем его из списка всех мест работы
    if (mainJob != null) {
      allJobs.remove(mainJob);
    }
    // Добавляем основное место работы в начало списка
    if (mainJob != null) {
      allJobs.insert(0, mainJob);
    }
    return allJobs.map((job) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${job['organization_name']} - ${job['department_name']} (${job['type']})',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            job['post'],
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 10),
        ],
      );
    }).toList();
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