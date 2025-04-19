// lib/screens/colleagues_screen.dart
import 'package:flutter/material.dart';
import '../services/colleagues_service.dart';
import '../services/departments_service.dart';
import '../screens/colleague_card_screen.dart';
import '../models/department.dart'; // Импортируем модель Department
import '../services/auth_service.dart'; // Импортируем AuthService

class ColleaguesScreen extends StatefulWidget {
  @override
  _ColleaguesScreenState createState() => _ColleaguesScreenState();
}

class _ColleaguesScreenState extends State<ColleaguesScreen> {
  List<Map<String, dynamic>> _colleagues = [];
  int _offset = 0;
  bool _isLoading = false;
  final int _limit = 50;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = "";
  String? _selectedOrganization;
  String? _selectedDepartment;
  List<Map<String, dynamic>> _organizations = []; // Изменяем тип на List<Map<String, dynamic>>
  List<Department> _departments = [];
  String? _mainOrganizationGuid; // GUID основной организации

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _fetchUserData();
    await _fetchDepartments();
    _loadMoreColleagues();
  }

  Future<void> _fetchUserData() async {
    try {
      final authService = AuthService();
      final userData = await authService.getUserData();
      if (userData != null && userData.isNotEmpty) {
        setState(() {
          _organizations = userData['employment']
              ?.where((job) => job['organization_name'] != null)
              .map((job) => {
            'guid': job['organization_guid'],
            'name': job['organization_name'],
          })
              .toList() ?? [];

          final mainJob = userData['employment']
              ?.firstWhereOrNull((job) => job['type'] == 'Основное место работы');

          _mainOrganizationGuid = mainJob?['organization_guid'];
          _selectedOrganization = _mainOrganizationGuid; // Устанавливаем основную организацию по умолчанию
        });
        print('Список организаций: $_organizations'); // Добавляем лог
        print('GUID основной организации: $_mainOrganizationGuid'); // Добавляем лог
      } else {
        print('Данные пользователя отсутствуют или некорректны');
      }
    } catch (e) {
      print('Ошибка при загрузке данных пользователя: $e');
    }
  }

  Future<void> _fetchDepartments() async {
    try {
      final service = DepartmentsService();
      final departments = await service.getDepartments(limit: 100, offset: 0);
      setState(() {
        _departments = departments;
      });
      print('Список подразделений: $_departments'); // Добавляем лог
    } catch (e) {
      print('Ошибка при загрузке подразделений: $e');
    }
  }

  Future<void> _loadMoreColleagues() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final colleaguesService = ColleaguesService();
      final newColleagues = await colleaguesService.getColleagues(
        guidOrg: _selectedOrganization,
        guidSub: _selectedDepartment,
        limit: _limit,
        offset: _offset,
      );
      print('Полученные коллеги: $newColleagues'); // Добавляем лог
      if (newColleagues.isEmpty) {
        setState(() => _hasMore = false);
        return;
      }
      final uniqueColleagues = <String, Map<String, dynamic>>{};
      for (var colleague in [..._colleagues, ...newColleagues]) {
        final guid = colleague['guid'];
        if (guid != null && !uniqueColleagues.containsKey(guid)) {
          uniqueColleagues[guid] = colleague;
        }
      }
      setState(() {
        _colleagues = uniqueColleagues.values.toList();
        _offset += _limit;
        _hasMore = newColleagues.length == _limit;
      });
    } catch (e) {
      print('Ошибка при загрузке коллег: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading) {
      _loadMoreColleagues();
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedOrganization,
                hint: Text("Организация"),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedOrganization = newValue;
                    _selectedDepartment = null; // Сбрасываем выбор подразделения при изменении организации
                    _resetColleaguesList();
                  });
                },
                items: _organizations.map<DropdownMenuItem<String>>((org) {
                  return DropdownMenuItem<String>(
                    value: org['guid'],
                    child: Container(
                      width: 320,
                      child: Text(
                        org['name'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  );
                }).toList(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                selectedItemBuilder: (BuildContext context) {
                  return _organizations.map<Widget>((org) {
                    return Container(
                      width: 320,
                      child: Text(
                        org['name'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList();
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                hint: Text("Подразделение"),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDepartment = newValue;
                    _resetColleaguesList();
                  });
                },
                items: _departments
                    .where((dep) => dep.organizationGuid == _selectedOrganization) // Фильтруем подразделения по организации
                    .map<DropdownMenuItem<String>>((dep) {
                  return DropdownMenuItem<String>(
                    value: dep.guid,
                    child: Container(
                      width: 320,
                      child: Text(
                        dep.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  );
                }).toList(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                selectedItemBuilder: (BuildContext context) {
                  return _departments
                      .where((dep) => dep.organizationGuid == _selectedOrganization) // Фильтруем подразделения по организации
                      .map<Widget>((dep) {
                    return Container(
                      width: 320,
                      child: Text(
                        dep.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList();
                },
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedOrganization = _mainOrganizationGuid; // Устанавливаем основную организацию по умолчанию
                          _selectedDepartment = null;
                          _searchQuery = "";
                          _offset = 0;
                          _colleagues.clear();
                          _hasMore = true;
                          _loadMoreColleagues();
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Очистить фильтр'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _offset = 0;
                          _colleagues.clear();
                          _hasMore = true;
                          _loadMoreColleagues();
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Применить фильтр'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _resetColleaguesList() {
    _colleagues.clear();
    _offset = 0;
    _hasMore = true;
    _loadMoreColleagues();
  }

  @override
  Widget build(BuildContext context) {
    var filteredColleagues = _colleagues.where((colleague) {
      final name = colleague['name']?.toLowerCase() ?? "";
      final department = colleague['department'] ?? "";
      final organization = colleague['organization'] ?? "";
      bool matchesName = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
      bool matchesDepartment = _selectedDepartment == null || department == _selectedDepartment;
      bool matchesOrganization = _selectedOrganization == null || organization == _selectedOrganization;
      return matchesName && matchesDepartment && matchesOrganization;
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Коллеги'),
        backgroundColor: Colors.yellow,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Поиск по имени',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: filteredColleagues.isEmpty
                ? Center(child: Text('Нет сотрудников'))
                : ListView.builder(
              controller: _scrollController,
              itemCount: filteredColleagues.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < filteredColleagues.length) {
                  final colleague = filteredColleagues[index];
                  return ListTile(
                    leading: Text('${index + 1}.'),
                    title: Text(
                      colleague['name']?.toString().trim() ?? 'Без имени',
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${colleague['position'] ?? "null"}, ${colleague['department'] ?? "null"}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ColleagueCardScreen(
                            colleagueGuid: colleague['guid'] ?? '',
                          ),
                        ),
                      );
                    },
                  );
                } else if (_hasMore) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: Text('Больше данных нет')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}