import 'package:flutter/material.dart';
import 'package:perpus_app/api/api_service.dart';
import 'package:perpus_app/screens/auth/login_screen.dart';
import 'package:perpus_app/screens/admin/admin_book_management_screen.dart';
import 'package:perpus_app/screens/admin/admin_category_management_screen.dart';
import 'package:perpus_app/screens/admin/admin_member_management_screen.dart';
import 'package:perpus_app/screens/admin/admin_borrowing_management_screen.dart';
import 'package:perpus_app/screens/admin/enhanced_import_export_dialog.dart';
import 'package:perpus_app/providers/theme_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  String? _userName;
  Map<String, dynamic>? _dashboardStats;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  void _loadAdminData() async {
    final name = await _apiService.getUserName();
    final stats = await _apiService.getDashboardData();
    setState(() {
      _userName = name;
      _dashboardStats = stats['dashboard'] ?? stats; // ambil isi dashboard
    });
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari Admin Panel?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          const ThemeToggleButton(),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout Admin'),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.indigo.shade400,
                Colors.indigo.shade600,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Welcome Card
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.shade400.withOpacity(0.85),
                    Colors.indigo.shade600.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          // Tambahkan Expanded di sini
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang, Administrator',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                                overflow: TextOverflow
                                    .ellipsis, // opsional, biar lebih aman
                              ),
                              const SizedBox(height: 4),
                              _userName == null
                                  ? const SizedBox(
                                      height: 28,
                                      width: 200,
                                      child: LinearProgressIndicator())
                                  : Text(
                                      _userName!,
                                      style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                      overflow:
                                          TextOverflow.ellipsis, // opsional
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Statistics Cards
          if (_dashboardStats != null) ...[
            const Text('Statistik Perpustakaan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        'Total Buku',
                        _dashboardStats!['totalBuku'] ?? 0,
                        Icons.menu_book,
                        Colors.blue)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildStatCard(
                        'Total Member',
                        _dashboardStats!['totalMember'] ?? 0,
                        Icons.people,
                        Colors.green)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        'Dipinjam',
                        _dashboardStats!['totalDipinjam'] ?? 0,
                        Icons.bookmark_added,
                        Colors.orange)),
                const SizedBox(width: 8),
                Expanded(
                    child: _buildStatCard(
                        'Tersedia',
                        (_dashboardStats!['totalStok'] ?? 0) -
                            (_dashboardStats!['totalDipinjam'] ?? 0),
                        Icons.bookmark_border,
                        Colors.purple)),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Management Menu
          const Text('Menu Manajemen',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildAdminMenuItem(context,
                  icon: Icons.menu_book,
                  label: 'Manajemen Buku',
                  color: Colors.indigo,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AdminBookManagementScreen()))),
              _buildAdminMenuItem(context,
                  icon: Icons.category,
                  label: 'Manajemen Kategori',
                  color: Colors.teal,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AdminCategoryManagementScreen()))),
              _buildAdminMenuItem(context,
                  icon: Icons.people,
                  label: 'Manajemen Member',
                  color: Colors.green,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AdminMemberManagementScreen()))),
              _buildAdminMenuItem(context,
                  icon: Icons.library_books,
                  label: 'Peminjaman Buku',
                  color: Colors.orange,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const AdminBorrowingManagementScreen()))),
              _buildAdminMenuItem(context,
                  icon: Icons.import_export,
                  label: 'Import/Export Data',
                  color: Colors.blue,
                  onTap: _showImportExportDialog),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportExportDialog() {
    showDialog(
      context: context,
      builder: (context) => const EnhancedImportExportDialog(),
    );
  }
}
