// lib/utils/error_handler.dart
import 'package:flutter/material.dart';

void handleError(BuildContext context, dynamic error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Произошла ошибка: $error'),
      duration: Duration(seconds: 3),
    ),
  );
}