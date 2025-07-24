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
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  void _loadAdminData() async {
    final name = await _apiService.getUserName();
    await _loadDashboardStats();
    setState(() {
      _userName = name;
    });
  }

  // Method terpisah untuk memuat ulang statistik dashboard
  Future<void> _loadDashboardStats() async {
    if (_isLoadingStats) return; // Prevent multiple concurrent calls
    
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await _apiService.getDashboardData();
      if (mounted) {
        setState(() {
          _dashboardStats = stats['dashboard'] ?? stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
        // Optional: Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat statistik: $e')),
        );
      }
    }
  }

  // Method untuk navigasi dengan callback refresh
  void _navigateToBookManagement() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminBookManagementScreen()),
    );
    
    // Jika ada perubahan data (result == true) atau tidak ada return value, refresh statistik
    if (result == true || result == null) {
      await _loadDashboardStats();
    }
  }

  void _navigateToCategoryManagement() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminCategoryManagementScreen()),
    );
    
    if (result == true || result == null) {
      await _loadDashboardStats();
    }
  }

  void _navigateToMemberManagement() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminMemberManagementScreen()),
    );
    
    if (result == true || result == null) {
      await _loadDashboardStats();
    }
  }

  void _navigateToBorrowingManagement() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AdminBorrowingManagementScreen()),
    );
    
    if (result == true || result == null) {
      await _loadDashboardStats();
    }
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
          // Tambahkan tombol refresh manual
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingStats ? null : _loadDashboardStats,
            tooltip: 'Refresh Statistik',
          ),
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
      body: RefreshIndicator(
        onRefresh: _loadDashboardStats,
        child: ListView(
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selamat Datang, Administrator',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                                        overflow: TextOverflow.ellipsis,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Statistik Perpustakaan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_isLoadingStats)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_dashboardStats != null) ...[
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
            ] else if (!_isLoadingStats) ...[
              // Show placeholder cards when no data
              Row(
                children: [
                  Expanded(child: _buildStatCard('Total Buku', 0, Icons.menu_book, Colors.blue)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Total Member', 0, Icons.people, Colors.green)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Dipinjam', 0, Icons.bookmark_added, Colors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Tersedia', 0, Icons.bookmark_border, Colors.purple)),
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
                    onTap: _navigateToBookManagement), // Gunakan method baru
                _buildAdminMenuItem(context,
                    icon: Icons.category,
                    label: 'Manajemen Kategori',
                    color: Colors.teal,
                    onTap: _navigateToCategoryManagement),
                _buildAdminMenuItem(context,
                    icon: Icons.people,
                    label: 'Manajemen Member',
                    color: Colors.green,
                    onTap: _navigateToMemberManagement),
                _buildAdminMenuItem(context,
                    icon: Icons.library_books,
                    label: 'Peminjaman Buku',
                    color: Colors.orange,
                    onTap: _navigateToBorrowingManagement),
                _buildAdminMenuItem(context,
                    icon: Icons.import_export,
                    label: 'Import/Export Data',
                    color: Colors.blue,
                    onTap: _showImportExportDialog),
              ],
            ),
          ],
        ),
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