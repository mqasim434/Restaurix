import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../features/placeholder/presentation/placeholder_home_screen.dart';

class RestaurixApp extends StatelessWidget {
  const RestaurixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const PlaceholderHomeScreen(),
    );
  }
}
