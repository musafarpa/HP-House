import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'config/constants.dart';
import 'providers/auth_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) {
        return Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
