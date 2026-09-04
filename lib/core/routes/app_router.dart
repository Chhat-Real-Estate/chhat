import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

// --- ALL NEW CLEAN ARCHITECTURE IMPORTS ---
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/phone_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/onboarding/screens/tenant_onboarding_screen.dart';
import '../../features/onboarding/screens/owner_onboarding_screen.dart';
import '../../features/owner/screens/owner_home_screen.dart'; // FIX: Naya Owner Home
import '../../features/owner/screens/add_listing_screen.dart';
import '../../features/tenant/screens/tenant_home_screen.dart'; // FIX: Naya Tenant Home
import '../../features/tenant/screens/room_detail_screen.dart';
import '../../features/tenant/screens/tenant_requirements_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/privacy_policy_screen.dart'; // NAYA: Privacy Policy Route
import '../../features/profile/screens/data_export_screen.dart'; // NAYA: DPDP Data Export Route
import '../../features/profile/screens/privacy_settings_screen.dart'; // NAYA: Privacy Settings
import '../../features/listings/models/listing_model.dart';
import '../../features/notifications/screens/notifications_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',

    // FIX #15: Route guarding and public paths
    redirect: (context, state) {
      final isLoggedIn = AuthService.isLoggedIn ||
          FirebaseAuth.instance.currentUser != null;
      const publicPaths = ['/', '/phone', '/otp', '/privacy-policy'];
      final isPublic = publicPaths.contains(state.matchedLocation);

      if (!isLoggedIn && !isPublic) {
        return '/phone';
      }

      // Agar already logged in hai aur phone/otp screen khol raha hai, root pe bhej do
      if (isLoggedIn && (state.matchedLocation == '/phone' || state.matchedLocation == '/otp')) {
        return '/';
      }

      return null;
    },

    routes: [
      // Splash
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: '/phone',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PhoneScreen(),
        ),
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          // Agar hot restart hua aur data udd gaya, toh wapas PhoneScreen par bhej do
          if (extra == null) {
            return const NoTransitionPage(
              child: PhoneScreen(),
            );
          }

          return NoTransitionPage(
            child: OtpScreen(
              verificationId: extra['verificationId']?.toString() ?? '',
              phoneNumber: extra['phoneNumber']?.toString() ?? '',
            ),
          );
        },
      ),

      // Role selection
      GoRoute(
        path: '/role',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: RoleSelectionScreen(),
        ),
      ),

      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) {
          final userId = (state.extra as String?) ??
              FirebaseAuth.instance.currentUser?.uid;
          if (userId == null) {
            return const NoTransitionPage(child: PhoneScreen());
          }
          return NoTransitionPage(
            child: NotificationsScreen(userId: userId),
          );
        },
      ),

      // NAYA TENANT ONBOARDING
      GoRoute(
        path: '/tenant-onboarding',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: TenantOnboardingScreen(),
        ),
      ),

      // NAYA OWNER ONBOARDING
      GoRoute(
        path: '/owner-onboarding',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: OwnerOnboardingScreen(),
        ),
      ),

      // --- MAIN HOME SCREENS ---
      GoRoute(
        path: '/owner-home',
        pageBuilder: (context, state) => NoTransitionPage(
          child: OwnerHomeScreen(
              initialTab: state.extra is int ? state.extra as int : 0),
        ),
      ),
      GoRoute(
        path: '/tenant-home',
        builder: (context, state) => TenantHomeScreen(
            initialTab: state.extra is int ? state.extra as int : 0),
      ),

      // --- SUB SCREENS ---
      GoRoute(
        path: '/tenant-requirements',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: TenantRequirementsScreen(),
        ),
      ),
      GoRoute(
        path: '/edit-profile',
        pageBuilder: (context, state) {
          // FIX #25: Fallback to tenant role rather than throwing to phone screen
          final activeRole = (state.extra as String?) ?? 'tenant';
          return NoTransitionPage(
            child: EditProfileScreen(activeRole: activeRole),
          );
        },
      ),
      GoRoute(
        path: '/privacy-policy', // FIX: Added missing privacy policy route
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PrivacyPolicyScreen(),
        ),
      ),
      // NAYA: DPDP Data Export Route
      GoRoute(
        path: '/data-export',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: DataExportScreen(),
        ),
      ),
      // NAYA: Privacy Settings Route
      GoRoute(
        path: '/privacy-settings',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PrivacySettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/add-listing',
        builder: (context, state) {
          // Edit mode vs Create mode
          final listingId = state.extra as String?;
          return AddListingScreen(listingId: listingId);
        },
      ),
      GoRoute(
        path: '/room-detail',
        pageBuilder: (context, state) {
          final listing = state.extra as ListingModel?;
          // FIX #25: Show informative fallback instead of sending to phone screen
          if (listing == null) {
            return NoTransitionPage(
              child: Scaffold(
                appBar: AppBar(title: const Text('Property Details')),
                body: const Center(
                  child: Text('Property details could not be loaded.'),
                ),
              ),
            );
          }
          return NoTransitionPage(
            child: RoomDetailScreen(listing: listing),
          );
        },
      ),
    ],
  );
});
