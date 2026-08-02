import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_scaffold.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(body: Center(child: Text('Login')));
  }
}
