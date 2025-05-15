import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/colleagues_service.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/departments_service.dart';
import '../models/colleague.dart';
import '../models/department.dart';
import './colleague_card_screen.dart';
import 'package:collection/collection.dart';

class ColleaguesScreen extends StatefulWidget {
  @override
  _ColleaguesScreenState createState() => _ColleaguesScreenState();
}

class _ColleaguesScreenState extends State<ColleaguesScreen> {
  ValueNotifier<List<Colleague>> _colleaguesNotifier = ValueNotifier([]);
  String? _selectedOrganizationGuid;
  String? _selectedDepartmentGuid;
  List<Map<String, dynamic>> _userOrganizations = [];
  List<Department> _departments = [];
  String? _currentUserId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyAuthorized = false;

  @override
  void initState() {
    super.initState();
    print('Initializing ColleaguesScreen');
    _loadFilterSettings();
    _loadUserOrganizations();
    _searchController.addListener(_onSearchChanged);
    _loadDefaultColleagues();
  }

  Future<void> _loadFilterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showOnlyAuthorized = prefs.getBool('show_only_authorized') ?? false;
    });
    print('Loaded filter settings: showOnlyAuthorized=$_showOnlyAuthorized');
  }

  Future<void> _saveFilterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_only_authorized', _showOnlyAuthorized);
    print('Saved filter settings: showOnlyAuthorized=$_showOnlyAuthorized');
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _colleaguesNotifier.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
    _updateColleaguesList(_colleaguesNotifier.value);
  }

  Future<void> _loadUserOrganizations() async {
    try {
      print('Loading user data...');
      final userData = await AuthService().getUserData();
      print('User data loaded: $userData');
      final employment = List<Map<String, dynamic>>.from(userData['employment'] ?? []);
      print('Employment data: $employment');
      setState(() {
        _userOrganizations = employment
            .where((job) => job['organization_guid'] != null && job['organization_guid'].isNotEmpty)
            .fold<Map<String, Map<String, dynamic>>>({}, (acc, job) {
          acc[job['organization_guid']] = job;
          return acc;
        })
            .values
            .toList();
        print('Unique user organizations: $_userOrganizations');
        _currentUserId = userData['guid'];
      });
    } catch (e) {
      print('Error loading user organizations: $e');
    }
  }

  Future<void> _loadDefaultColleagues() async {
    print('Loading default colleagues list without params...');
    try {
      final service = ColleaguesService();
      final colleagues = await service.getColleagues();
      print('Default colleagues fetched: $colleagues');
      _updateColleaguesList(colleagues);
    } catch (e) {
      print('Error loading default colleagues: $e');
      _colleaguesNotifier.value = [];
    }
  }

  Future<void> _loadDepartments(String organizationGuid, BuildContext context) async {
    try {
      print('Loading departments for organization GUID: $organizationGuid');
      final service = DepartmentsService();
      final departments = await service.getDepartments(
        organizationGuid: organizationGuid,
        context: context, // Добавляем контекст
      );
      print('Departments loaded: $departments');
      if (departments.isEmpty) {
        print('No departments found for organization: $organizationGuid');
      }
      setState(() {
        _departments = departments;
        _selectedDepartmentGuid = null;
      });
      await _fetchColleagues(organizationGuid, null);
    } catch (e) {
      print('Error loading departments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке подразделений: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchColleagues(String? organizationGuid, String? departmentGuid) async {
    try {
      print('Fetching colleagues for organization GUID: $organizationGuid, department GUID: $departmentGuid');
      final service = ColleaguesService();
      final colleagues = await service.getColleagues(
        organizationGuid: organizationGuid,
        departmentGuid: departmentGuid,
      );
      print('Colleagues fetched: $colleagues');
      if (_currentUserId == null) {
        print('Current user ID is null, skipping filter');
        _updateColleaguesList(colleagues);
        return;
      }
      final filteredColleagues = colleagues.where((colleague) =>
      colleague.guid != _currentUserId).toList();
      print('Filtered colleagues before update: $filteredColleagues');
      _updateColleaguesList(filteredColleagues);
    } catch (e) {
      print('Error fetching colleagues: $e');
      rethrow;
    }
  }

  void _resetToDefault() {
    print('Resetting to default state...');
    setState(() {
      _selectedOrganizationGuid = null;
      _selectedDepartmentGuid = null;
      _departments = [];
      _showOnlyAuthorized = false;
    });
    _saveFilterSettings();
    _fetchColleagues(null, null);
  }

  void _toggleFavorite(Colleague colleague) async {
    try {
      final favoritesService = FavoritesService();
      final isCurrentlySelected = colleague.selected;
      if (isCurrentlySelected) {
        await favoritesService.removeFromFavorites(guidSelected: colleague.guid, context: context); // Передаем контекст
      } else {
        await favoritesService.addToFavorites(guidSelected: colleague.guid, context: context); // Передаем контекст
      }
      setState(() {
        colleague.selected = !isCurrentlySelected;
      });
      _updateColleaguesList(_colleaguesNotifier.value);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при изменении состояния избранного')),
      );
    }
  }

  void _updateColleaguesList(List<Colleague> colleagues) {
    var filteredColleagues = colleagues.where((colleague) =>
        colleague.name.toLowerCase().contains(_searchQuery)).toList();
    if (_showOnlyAuthorized) {
      filteredColleagues = filteredColleagues.where((colleague) => colleague.auth).toList();
    }
    print('Filtered colleagues after search: $filteredColleagues');
    filteredColleagues.sort((a, b) {
      if (a.selected && !b.selected) return -1;
      if (!a.selected && b.selected) return 1;
      return a.name.compareTo(b.name);
    });
    print('Filtered and sorted colleagues: $filteredColleagues');
    _colleaguesNotifier.value = filteredColleagues;
  }

  @override
  Widget build(BuildContext context) {
    print('Building ColleaguesScreen');
    print('_selectedOrganizationGuid: $_selectedOrganizationGuid');
    print('_userOrganizations: $_userOrganizations');
    print('_departments: $_departments');
    print('_selectedDepartmentGuid: $_selectedDepartmentGuid');
    print('_showOnlyAuthorized: $_showOnlyAuthorized');
    return Scaffold(
      appBar: AppBar(
        title: Text('Коллеги'),
        backgroundColor: Colors.yellow,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  String? newOrgValue = _selectedOrganizationGuid;
                  String? newDepValue = _selectedDepartmentGuid;
                  List<Department> dialogDepartments = _departments;
                  bool showOnlyAuthorized = _showOnlyAuthorized;
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        title: Text('Фильтр'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              DropdownButtonFormField<String>(
                                value: newOrgValue,
                                items: _userOrganizations.map((org) {
                                  final orgGuid = org['organization_guid'] as String;
                                  final orgName = org['organization_name'] as String;
                                  return DropdownMenuItem<String>(
                                    value: orgGuid,
                                    child: _buildTruncatedText(orgName),
                                  );
                                }).toList(),
                                onChanged: (String? value) async {
                                  if (value == null) {
                                    setState(() {
                                      newOrgValue = null;
                                      newDepValue = null;
                                      dialogDepartments = [];
                                    });
                                    return;
                                  }
                                  await _loadDepartments(value, context); // Передаем контекст
                                  setState(() {
                                    newOrgValue = value;
                                    newDepValue = null;
                                    dialogDepartments = _departments;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Выберите организацию',
                                ),
                              ),
                              SizedBox(height: 16),
                              if (dialogDepartments.isNotEmpty)
                                DropdownButtonFormField<String>(
                                  value: newDepValue,
                                  items: dialogDepartments.map((dep) {
                                    print('Adding department to dropdown: ${dep.guid} - ${dep.name}');
                                    return DropdownMenuItem<String>(
                                      value: dep.guid,
                                      child: _buildTruncatedText(dep.name),
                                    );
                                  }).toList(),
                                  onChanged: (String? value) {
                                    setState(() {
                                      newDepValue = value;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Выберите подразделение',
                                  ),
                                )
                              else if (newOrgValue != null)
                                Text('Нет доступных подразделений'),
                              SizedBox(height: 16),
                              ListTile(
                                title: Text('Только авторизованные'),
                                trailing: Switch(
                                  value: showOnlyAuthorized,
                                  onChanged: (bool value) async {
                                    setState(() {
                                      showOnlyAuthorized = value;
                                    });
                                    await _saveFilterSettings();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: _resetToDefault,
                            child: Text('Сбросить'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              setState(() {
                                _selectedOrganizationGuid = newOrgValue;
                                _selectedDepartmentGuid = newDepValue;
                                _departments = dialogDepartments;
                                _showOnlyAuthorized = showOnlyAuthorized;
                              });
                              await _saveFilterSettings();
                              _fetchColleagues(newOrgValue, newDepValue);
                              print('Updated filters: org=$newOrgValue, dep=$newDepValue, authOnly=$showOnlyAuthorized');
                            },
                            child: Text('Применить'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск коллеги',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<Colleague>>(
              valueListenable: _colleaguesNotifier,
              builder: (context, colleagues, child) {
                var filteredColleagues = colleagues.where((colleague) =>
                    colleague.name.toLowerCase().contains(_searchQuery)).toList();
                if (_showOnlyAuthorized) {
                  filteredColleagues = filteredColleagues.where((colleague) => colleague.auth).toList();
                }
                print('Filtered colleagues in builder: $filteredColleagues');
                filteredColleagues.sort((a, b) {
                  if (a.selected && !b.selected) return -1;
                  if (!a.selected && b.selected) return 1;
                  return a.name.compareTo(b.name);
                });
                print('Sorted colleagues in builder: $filteredColleagues');
                return filteredColleagues.isEmpty
                    ? Center(child: Text('Коллег нет'))
                    : ListView.builder(
                  itemCount: filteredColleagues.length,
                  itemBuilder: (context, index) {
                    final colleague = filteredColleagues[index];
                    return ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              colleague.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              colleague.selected ? Icons.star : Icons.star_border,
                              color: colleague.selected ? Colors.yellow : Colors.grey,
                            ),
                            onPressed: () {
                              _toggleFavorite(colleague);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ColleagueCardScreen(colleagueGuid: colleague.guid),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTruncatedText(String text) {
    return Container(
      constraints: BoxConstraints(maxWidth: 250), // Ограничиваем максимальную ширину
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}