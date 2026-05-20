import 'package:flutter/material.dart';
import '../../core/widgets/app_bar_widget.dart';

class TopicListScreen extends StatelessWidget {
  const TopicListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBarWidget(title: 'Topics'),
      body: Center(
        child: Text('Topic List Screen'),
      ),
    );
  }
}
