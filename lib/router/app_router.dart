import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthapp/screens/health_records/health_record_screen.dart';
import 'package:healthapp/screens/home/home_screen.dart';
import 'package:healthapp/screens/record_history/record_history_screen.dart';
import 'package:healthapp/screens/trends/trends_screen.dart';
import 'package:healthapp/models/health_record.dart';

class AppRouter {
  static final _navigationKey = GlobalKey<NavigatorState>();
  static final _refreshNotifier = ValueNotifier<bool>(false);

  static final router = GoRouter(
    navigatorKey: _navigationKey,
    initialLocation: '/',
    refreshListenable: _refreshNotifier,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/record/:type',
        builder: (context, state) {
          final typeIndex = int.parse(state.pathParameters['type'] ?? '0');
          return HealthRecordScreen(
            recordType: RecordType.values[typeIndex],
          );
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const RecordHistoryScreen(),
      ),
      GoRoute(
        path: '/trends',
        builder: (context, state) => const TrendsScreen(),
      ),
    ],
  );

  // 다른 화면에서 홈 화면으로 돌아갈 때 데이터 새로고침 함수
  static void refreshHomeScreen() {
    _refreshNotifier.value = !_refreshNotifier.value;
  }
}
