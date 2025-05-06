import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class FavoritesService {
  static const String _baseUrl = 'mw.azs-topline.ru';
  static const int _port = 44445;

  // Метод для добавления сотрудника в избранное
  Future<bool> addToFavorites(String guidSelected) async {
    try {
      final guid = await AuthService().getGUID();
      if (guid == null || guid.isEmpty) {
        throw Exception('GUID не найден');
      }
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/addSelected',
      );
      final bodyMap = {"guid_selected": guidSelected};
      final body = base64Encode(utf8.encode(jsonEncode(bodyMap)));
      final response = await http.post(
        uri,
        headers: {
          ...AuthService.baseHeaders,
          'ma-guid': guid,
        },
        body: body,
      ).timeout(Duration(seconds: 10));
      print('Статус-код добавления в избранное: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return true;
        } else {
          throw Exception('Ошибка в структуре ответа: ${json['error']}');
        }
      } else if (response.statusCode == 409) {
        final json = jsonDecode(response.body);
        if (json['error'] == 'Пользователь уже в избранном') {
          print('Пользователь уже в избранном');
          return true; // Возвращаем true, чтобы состояние осталось без изменений
        } else {
          throw Exception('HTTP-ошибка: ${response.statusCode}');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при добавлении в избранное: $e');
      rethrow;
    }
  }

  // Метод для удаления сотрудника из избранного
  Future<bool> removeFromFavorites(String guidSelected) async {
    try {
      final guid = await AuthService().getGUID();
      if (guid == null || guid.isEmpty) {
        throw Exception('GUID не найден');
      }
      final uri = Uri(
        scheme: 'https',
        host: _baseUrl,
        port: _port,
        path: '/hrm/hs/ewp/deleteSelected',
      );
      final bodyMap = {"guid_selected": guidSelected};
      final body = base64Encode(utf8.encode(jsonEncode(bodyMap)));
      final response = await http.post(
        uri,
        headers: {
          ...AuthService.baseHeaders,
          'ma-guid': guid,
        },
        body: body,
      ).timeout(Duration(seconds: 10));
      print('Статус-код удаления из избранного: ${response.statusCode}');
      print('Ответ сервера: ${response.body}');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          return true;
        } else {
          throw Exception('Ошибка в структуре ответа: ${json['error']}');
        }
      } else if (response.statusCode == 404) {
        final json = jsonDecode(response.body);
        if (json['error'] == 'Пользователя нет в избранном') {
          print('Пользователя нет в избранном');
          return true; // Возвращаем true, чтобы состояние осталось без изменений
        } else {
          throw Exception('HTTP-ошибка: ${response.statusCode}');
        }
      } else {
        throw Exception('HTTP-ошибка: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при удалении из избранного: $e');
      rethrow;
    }
  }
}
