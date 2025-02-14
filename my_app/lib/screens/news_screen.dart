import 'package:flutter/material.dart';

class NewsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Новости'), backgroundColor: Colors.yellow),
      body: Center(child: Text('Раздел новостей')),
    );
  }
}
