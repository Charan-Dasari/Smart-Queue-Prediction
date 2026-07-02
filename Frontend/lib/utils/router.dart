import 'package:go_router/go_router.dart';
import 'theme.dart';

// User screens
import '../screens/user/splash_screen.dart';
import '../screens/user/login_screen.dart';
import '../screens/user/registration_screen.dart';
import '../screens/user/forgot_password_screen.dart';
import '../screens/user/home_dashboard_screen.dart';
import '../screens/user/service_selection_screen.dart';
import '../screens/user/appointment_booking_screen.dart';
import '../screens/user/smart_slot_screen.dart';
import '../screens/user/booking_confirmation_screen.dart';
import '../screens/user/digital_token_screen.dart';
import '../screens/user/queue_tracking_screen.dart';
import '../screens/user/notifications_screen.dart';
import '../screens/user/appointment_history_screen.dart';
import '../screens/user/profile_screen.dart';
import '../screens/user/help_support_screen.dart';
import '../screens/user/about_screen.dart';

// Admin screens
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/queue_management_screen.dart';
import '../screens/admin/appointment_management_screen.dart';
import '../screens/admin/service_management_screen.dart';
import '../screens/admin/staff_counter_screen.dart';
import '../screens/admin/analytics_dashboard_screen.dart';
import '../screens/admin/ai_prediction_screen.dart';
import '../screens/admin/role_management_screen.dart';

// Staff screens
import '../screens/staff/staff_dashboard_screen.dart';
import '../screens/staff/staff_queue_screen.dart';

// Super Admin screens
import '../screens/super_admin/super_admin_dashboard_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ─── User Routes ─────────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegistrationScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const UserThemeWrapper(child: HomeDashboardScreen()),
    ),
    GoRoute(
      path: '/services',
      builder: (context, state) => const UserThemeWrapper(child: ServiceSelectionScreen()),
    ),
    GoRoute(
      path: '/booking/:providerId',
      builder: (context, state) {
        final providerId = state.pathParameters['providerId'] ?? 'h1';
        return UserThemeWrapper(child: AppointmentBookingScreen(providerId: providerId));
      },
    ),
    GoRoute(
      path: '/smart-slots/:providerId',
      builder: (context, state) {
        final providerId = state.pathParameters['providerId'] ?? 'h1';
        return UserThemeWrapper(child: SmartSlotScreen(providerId: providerId));
      },
    ),
    GoRoute(
      path: '/confirmation/:appointmentId',
      builder: (context, state) {
        final appointmentId = state.pathParameters['appointmentId'] ?? 'apt1';
        return UserThemeWrapper(child: BookingConfirmationScreen(appointmentId: appointmentId));
      },
    ),
    GoRoute(
      path: '/token/:tokenId',
      builder: (context, state) {
        final tokenId = state.pathParameters['tokenId'] ?? 't1';
        return UserThemeWrapper(child: DigitalTokenScreen(tokenId: tokenId));
      },
    ),
    GoRoute(
      path: '/tracking/:tokenId',
      builder: (context, state) {
        final tokenId = state.pathParameters['tokenId'] ?? 't1';
        return UserThemeWrapper(child: QueueTrackingScreen(tokenId: tokenId));
      },
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const UserThemeWrapper(child: NotificationsScreen()),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const UserThemeWrapper(child: AppointmentHistoryScreen()),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const UserThemeWrapper(child: ProfileScreen()),
    ),
    GoRoute(
      path: '/help-support',
      builder: (context, state) => const UserThemeWrapper(child: HelpSupportScreen()),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const UserThemeWrapper(child: AboutScreen()),
    ),

    // ─── Admin Routes ────────────────────────────────────────────────────────
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/queue',
      builder: (context, state) => const QueueManagementScreen(),
    ),
    GoRoute(
      path: '/admin/appointments',
      builder: (context, state) => const AppointmentManagementScreen(),
    ),
    GoRoute(
      path: '/admin/services',
      builder: (context, state) => const ServiceManagementScreen(),
    ),
    GoRoute(
      path: '/admin/staff',
      builder: (context, state) => const StaffCounterScreen(),
    ),
    GoRoute(
      path: '/admin/analytics',
      builder: (context, state) => const AnalyticsDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/predictions',
      builder: (context, state) => const AIPredictionScreen(),
    ),
    GoRoute(
      path: '/admin/roles',
      builder: (context, state) => const RoleManagementScreen(),
    ),

    // ─── Staff Routes ────────────────────────────────────────────────────────
    GoRoute(
      path: '/staff/dashboard',
      builder: (context, state) => const StaffDashboardScreen(),
    ),
    GoRoute(
      path: '/staff/queue',
      builder: (context, state) => const StaffQueueScreen(),
    ),

    // ─── Super Admin Routes ──────────────────────────────────────────────────
    GoRoute(
      path: '/super/dashboard',
      builder: (context, state) => const SuperAdminDashboardScreen(),
    ),
  ],
);
