import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.biometricEnabled,
    required this.onConfigureBiometric,
    super.key,
  });

  final bool biometricEnabled;
  final VoidCallback onConfigureBiometric;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _EmptyDashboard(onCreateGoal: () => _selectTab(2)),
      const _PlaceholderPage(
        key: Key('goals-page'),
        title: 'Target',
        description: 'Target aktif, selesai, dan arsip akan tersusun di sini.',
        icon: Icons.flag_rounded,
      ),
      const _AddPage(key: Key('add-page')),
      const _PlaceholderPage(
        key: Key('reports-page'),
        title: 'Laporan',
        description: 'Ringkasan dan perkembangan tabungan akan tampil di sini.',
        icon: Icons.bar_chart_rounded,
      ),
      _ProfilePage(
        biometricEnabled: widget.biometricEnabled,
        onConfigureBiometric: widget.onConfigureBiometric,
      ),
    ];

    return Scaffold(
      key: const Key('main-shell'),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: _PocketlyNavigationBar(
        selectedIndex: _selectedIndex,
        onSelected: _selectTab,
      ),
    );
  }
}

class _PocketlyNavigationBar extends StatelessWidget {
  const _PocketlyNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      key: const Key('main-navigation'),
      height: 94 + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 18,
            right: 18,
            top: 20,
            bottom: 8 + bottomInset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.09),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _NavigationItem(
                      key: const Key('nav-home'),
                      label: 'Beranda',
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      selected: selectedIndex == 0,
                      onTap: () => onSelected(0),
                    ),
                  ),
                  Expanded(
                    child: _NavigationItem(
                      key: const Key('nav-target'),
                      label: 'Target',
                      icon: Icons.flag_outlined,
                      selectedIcon: Icons.flag_rounded,
                      selected: selectedIndex == 1,
                      onTap: () => onSelected(1),
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    child: _NavigationItem(
                      key: const Key('nav-reports'),
                      label: 'Laporan',
                      icon: Icons.bar_chart_outlined,
                      selectedIcon: Icons.bar_chart_rounded,
                      selected: selectedIndex == 3,
                      onTap: () => onSelected(3),
                    ),
                  ),
                  Expanded(
                    child: _NavigationItem(
                      key: const Key('nav-profile'),
                      label: 'Profil',
                      icon: Icons.person_outline_rounded,
                      selectedIcon: Icons.person_rounded,
                      selected: selectedIndex == 4,
                      onTap: () => onSelected(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Semantics(
              button: true,
              selected: selectedIndex == 2,
              label: 'Tambah',
              child: Tooltip(
                message: 'Tambah',
                child: InkResponse(
                  key: const Key('nav-add'),
                  onTap: () => onSelected(2),
                  radius: 38,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.16),
                          blurRadius: 0,
                          spreadRadius: 5,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 34,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (selectedIndex == 2)
            const Positioned(top: 76, child: _SelectedDot()),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Icon(
                  selected ? selectedIcon : icon,
                  key: ValueKey(selected),
                  color: selected
                      ? AppColors.primary
                      : AppColors.ink.withValues(alpha: 0.28),
                  size: 27,
                ),
              ),
              const SizedBox(height: 5),
              if (selected) const _SelectedDot() else const SizedBox(height: 7),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDot extends StatelessWidget {
  const _SelectedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({required this.onCreateGoal});

  final VoidCallback onCreateGoal;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const Key('dashboard-page'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        children: [
          Row(
            children: [
              Image.asset(
                'assets/branding/pocketly_logo.png',
                width: 38,
                height: 38,
              ),
              const SizedBox(width: 10),
              const Text(
                'pocketly',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const Spacer(),
              const IconButton(
                tooltip: 'Notifikasi',
                onPressed: null,
                icon: Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            'Selamat datang',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            'Satu target kecil bisa menjadi awal yang berarti.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.savings_outlined,
                    size: 46,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Belum ada target tabungan',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'Buat target pertamamu untuk mulai mencatat dan melihat perkembangan tabungan.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.62),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('dashboard-create-goal'),
                  onPressed: onCreateGoal,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Buat target pertama'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _InfoCard(
            icon: Icons.lock_outline_rounded,
            title: 'Data tetap di perangkatmu',
            description:
                'Target dan transaksi akan disimpan secara lokal di Pocketly.',
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.muted),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.ink.withValues(alpha: 0.58),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPage extends StatelessWidget {
  const _AddPage({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature akan tersedia pada tahap berikutnya.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
        children: [
          Text('Tambah', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Pilih hal yang ingin kamu catat.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 28),
          _ActionCard(
            key: const Key('add-goal-action'),
            icon: Icons.flag_rounded,
            title: 'Target baru',
            description: 'Tentukan tujuan dan rencana tabunganmu.',
            onTap: () => _showComingSoon(context, 'Target baru'),
          ),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.south_west_rounded,
            title: 'Setoran',
            description: 'Catat uang yang kamu sisihkan.',
            onTap: () => _showComingSoon(context, 'Setoran'),
          ),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.north_east_rounded,
            title: 'Penarikan',
            description: 'Catat uang yang diambil dari target.',
            onTap: () => _showComingSoon(context, 'Penarikan'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.muted),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColors.ink.withValues(alpha: 0.58),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.title,
    required this.description,
    required this.icon,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineLarge),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Icon(icon, size: 58, color: AppColors.primary),
                  const SizedBox(height: 18),
                  Text(
                    'Belum ada data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.biometricEnabled,
    required this.onConfigureBiometric,
  });

  final bool biometricEnabled;
  final VoidCallback onConfigureBiometric;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const Key('profile-page'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
        children: [
          Text('Profil', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 28),
          _InfoCard(
            icon: Icons.fingerprint_rounded,
            title: biometricEnabled ? 'Biometrik aktif' : 'Biometrik nonaktif',
            description: biometricEnabled
                ? 'Kamu dapat membuka Pocketly dengan biometrik.'
                : 'Aktifkan biometrik untuk membuka Pocketly lebih cepat.',
          ),
          if (!biometricEnabled) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('configure-biometric'),
              onPressed: onConfigureBiometric,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text('Aktifkan biometrik'),
            ),
          ],
          const SizedBox(height: 24),
          const _InfoCard(
            icon: Icons.storage_rounded,
            title: 'Mode lokal',
            description: 'Data Pocketly tersimpan hanya di perangkat ini.',
          ),
        ],
      ),
    );
  }
}
