import 'package:flutter/material.dart';
import '../services//colleague_card_service.dart';

class ColleagueCardScreen extends StatefulWidget {
  final String colleagueGuid;

  const ColleagueCardScreen({required this.colleagueGuid});

  @override
  _ColleagueCardScreenState createState() => _ColleagueCardScreenState();
}

class _ColleagueCardScreenState extends State<ColleagueCardScreen> {
  late Future<Map<String, dynamic>> _colleagueFuture;

  @override
  void initState() {
    super.initState();
    _colleagueFuture = _fetchColleagueData();
  }

  Future<Map<String, dynamic>> _fetchColleagueData() async {
    try {
      final service = ColleagueCardService();
      final data = await service.getColleagueCard(widget.colleagueGuid);
      print('Данные карточки коллеги: $data');
      return data;
    } catch (e) {
      print('Ошибка при загрузке данных коллеги: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Карточка коллеги'),
        backgroundColor: Colors.yellow,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _colleagueFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки данных'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Данные не найдены'));
          } else {
            final colleague = snapshot.data!;
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: colleague['photo']?.isNotEmpty == true
                          ? NetworkImage(colleague['photo']) as ImageProvider
                          : AssetImage('assets/default_avatar.png'),
                      backgroundColor: Colors.grey[300],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '${colleague['lastName'] ?? ''} ${colleague['firstName'] ?? ''} ${colleague['patronymic'] ?? ''}'.trim(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.phone),
                    title: Text(colleague['phone'] ?? 'Номер телефона не указан'),
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