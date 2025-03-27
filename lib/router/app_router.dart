import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthapp/models/health_record.dart';
import 'package:healthapp/screens/home/home_screen.dart';
import 'package:healthapp/screens/health_records/health_record_screen.dart';
import 'package:healthapp/screens/record_history/record_history_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          print('📱 라우팅: 홈 화면으로 이동');
          return const HomeScreen();
        },
        routes: [
          GoRoute(
            path: 'record/:typeIndex',
            builder: (BuildContext context, GoRouterState state) {
              final typeIndex =
                  int.parse(state.pathParameters['typeIndex'] ?? '0');
              final recordType = RecordType.values[typeIndex];
              print(
                  '📱 라우팅: ${HealthRecord.getTypeName(recordType)} 기록 화면으로 이동');
              return HealthRecordScreen(recordType: recordType);
            },
          ),
          GoRoute(
            path: 'history',
            builder: (BuildContext context, GoRouterState state) {
              print('📱 라우팅: 기록 이력 화면으로 이동');
              return const RecordHistoryScreen();
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      print('⚠️ 라우팅 오류: ${state.uri}');
      return Scaffold(
        body: Center(
          child: Text('페이지를 찾을 수 없습니다: ${state.uri}'),
        ),
      );
    },
    // 라우터 관찰자 추가
    observers: [NavigationLogger()],
    // 리다이렉트 처리 시에도 로그 기록
    redirect: (context, state) {
      print('🔄 리다이렉트 체크: ${state.uri}');
      return null; // 리다이렉트 없음
    },
  );
}

// 네비게이션 로거 구현
class NavigationLogger extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print(
        '👉 Push: ${route.settings.name} (이전: ${previousRoute?.settings.name})');
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print(
        '👈 Pop: ${route.settings.name} (다음: ${previousRoute?.settings.name})');
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('🗑️ Remove: ${route.settings.name}');
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    print(
        '🔄 Replace: ${oldRoute?.settings.name} -> ${newRoute?.settings.name}');
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
