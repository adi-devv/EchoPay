import 'package:flutter/cupertino.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:echopay/services/auth/auth_service.dart';
import 'package:echopay/components/my_logo.dart';
import 'package:echopay/components/smooth_toggle.dart';
import 'package:flutter/material.dart';
import 'package:echopay/theme/theme_provider.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  void logout(BuildContext context) {
    AuthService().signOut(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Theme.of(context).brightness == Brightness.dark
          ? BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 100,
                  offset: Offset(4, 0),
                ),
              ],
            )
          : null,
      child: Drawer(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Column(
          children: [
            SizedBox(height: 12),
            Theme(
              data: Theme.of(context).copyWith(
                dividerTheme: DividerThemeData(color: Colors.transparent),
              ),
              child: DrawerHeader(
                child: Center(child: MyLogo(fontSize: 48)),
              ),
            ),
            SmoothToggle(
              tabs: [
                GButton(icon: Icons.dark_mode),
                GButton(icon: Icons.light_mode),
              ],
              initialIndex: Provider.of<ThemeProvider>(context).isDarkMode ? 0 : 1,
              onTabChange: (index) {
                final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                if (themeProvider.isDarkMode != (index == 0)) {
                  themeProvider.toggleTheme();
                }
              },
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.only(left: 25, bottom: 16),
              child: ListTile(
                title: Text('Logout'),
                leading: Icon(Icons.logout),
                onTap: () {
                  logout(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
