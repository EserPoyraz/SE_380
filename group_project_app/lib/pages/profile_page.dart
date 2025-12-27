import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/profile_service.dart';

import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_section_title.dart';
import '../widgets/profile/profile_stat_card.dart';
import '../widgets/profile/profile_info_card.dart';
import '../widgets/profile/profile_program_card.dart';
import '../widgets/profile/profile_action_button.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _bmiPillText(double bmi) {
    if (bmi < 18.5) return "Low";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "High";
    return "Very High";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E1A),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ProfileService.profileDocStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text("Error loading profile",
                  style: TextStyle(color: Colors.white)),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = ProfileService.me;
          final data = snap.data!.data() ?? {};

          final name =
              (data['name'] as String?)?.trim().isNotEmpty == true
                  ? (data['name'] as String).trim()
                  : (user.displayName ?? "User");

          final email =
              (data['email'] as String?)?.trim().isNotEmpty == true
                  ? (data['email'] as String).trim()
                  : (user.email ?? "-");

          final photoUrl =
              (data['photoUrl'] as String?)?.trim().isNotEmpty == true
                  ? (data['photoUrl'] as String).trim()
                  : (user.photoURL ?? "");

          final sets = (data['sets'] as num?)?.toInt() ?? 0;
          final water = (data['water'] as num?)?.toInt() ?? 0;

          final bmi = (data['bmi'] as num?)?.toDouble();
          final bmiCategory = (data['bmiCategory'] as String?) ?? "";
          final gender = (data['gender'] as String?) ?? "";

          final heightCm = (data['heightCm'] as num?)?.toInt();
          final weightKg = (data['weightKg'] as num?)?.toInt();

          final currentProgram = data['currentProgram'];
          final friends = (data['friends'] as List?)?.cast<String>() ?? [];

          final healthRows = <MapEntry<String, String>>[
            MapEntry("BMI", bmi == null ? "-" : bmi.toStringAsFixed(1)),
            MapEntry("Category", bmiCategory.isEmpty ? "-" : bmiCategory),
            MapEntry("Gender", gender.isEmpty ? "-" : gender),
            MapEntry("Height", heightCm == null ? "-" : "$heightCm cm"),
            MapEntry("Weight", weightKg == null ? "-" : "$weightKg kg"),
          ];

          final pill = bmi == null ? "Not set" : _bmiPillText(bmi);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ProfileHeader(
                  name: name,
                  email: email,
                  photoUrl: photoUrl,
                  friendsCount: friends.length,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const ProfileSectionTitle(title: "Today"),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ProfileStatCard(
                              title: "Sets",
                              value: sets.toString(),
                              icon: Icons.fitness_center_rounded,
                              subtitle: "Completed",
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ProfileStatCard(
                              title: "Water",
                              value: "${water}ml",
                              icon: Icons.water_drop_rounded,
                              subtitle: "Intake",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const ProfileSectionTitle(title: "Health"),
                      const SizedBox(height: 10),
                      ProfileInfoCard(
                        title: "Body Metrics",
                        rows: healthRows,
                        pillText: pill,
                      ),
                      const SizedBox(height: 14),
                      const ProfileSectionTitle(title: "Program"),
                      const SizedBox(height: 10),
                      ProfileProgramCard(program: currentProgram),
                      const SizedBox(height: 16),
                      const ProfileSectionTitle(title: "Actions"),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ProfileActionButton(
                              icon: Icons.edit_rounded,
                              text: "Edit Profile",
                              onTap: () {
                                Navigator.pushNamed(context, '/bmi');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ProfileActionButton(
                              icon: Icons.logout_rounded,
                              text: "Sign out",
                              onTap: () async {
                                await ProfileService.signOut();
                              },
                              danger: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
