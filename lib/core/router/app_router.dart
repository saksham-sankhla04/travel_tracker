import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/trip_tracking/presentation/pages/home_page.dart';
import '../../features/trip_survey/presentation/pages/survey_page.dart';

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
        return SurveyPage(
          tripStartTime: state.uri.queryParameters['startTime'],
          tripEndTime: state.uri.queryParameters['endTime'],
        );
      },
    ),
  ],
);
