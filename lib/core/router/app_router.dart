import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/trip_tracking/presentation/pages/home_page.dart';
import '../../features/trip_survey/presentation/pages/survey_page.dart';
import '../../features/trip_survey/presentation/pages/trip_history_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/survey',
      builder: (context, state) {
        final params = state.uri.queryParameters;
        return SurveyPage(
          tripStartTime: params['startTime'],
          tripEndTime: params['endTime'],
          startLat: double.tryParse(params['startLat'] ?? ''),
          startLng: double.tryParse(params['startLng'] ?? ''),
          endLat: double.tryParse(params['endLat'] ?? ''),
          endLng: double.tryParse(params['endLng'] ?? ''),
        );
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const TripHistoryPage(),
    ),
  ],
);
