import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_scaffold.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(body: Center(child: Text('Notes Taker')));
  }
}
