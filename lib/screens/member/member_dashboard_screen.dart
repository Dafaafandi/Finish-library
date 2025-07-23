import 'package:flutter/material.dart';
import '../../services/library_api_service.dart';
import 'books_list_screen_working.dart';
import 'borrowed_books_screen.dart';

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  _MemberDashboardScreenState createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  final LibraryApiService _apiService = LibraryApiService();

  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _userName;
  String? _userRole;
  int? _currentMemberId;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    setState(() => _isLoading = true);

    try {
      final userName = await _apiService.getUserName();
      final userRole =
          await _apiService.getUserRole(); // Pastikan ada method ini
      Map<String, dynamic> stats = {};

      if (userRole == 'member') {
        // Ambil data peminjaman member saja
        final currentMemberId = await _apiService.getCurrentMemberId();
        final allBorrowings = await _apiService.getAllBorrowings();
        final memberBorrowings = allBorrowings
            .where((b) => b['id_member'] == currentMemberId)
            .toList();

        int totalBorrowed = memberBorrowings.length;
        int returned = memberBorrowings.where((b) {
          final status = b['status']?.toString();
          final tglKembali = b['tanggal_pengembalian'];
          return status == "3" ||
              (tglKembali != null &&
                  tglKembali.toString().isNotEmpty &&
                  status != "1");
        }).length;

        stats = {
          'total_borrowed': totalBorrowed,
          'returned': returned,
        };
      } else {
        final dashboardStats = await _apiService.getMemberDashboardStats();
        final dashboard = dashboardStats['data']?['dashboard'] ?? {};
        stats = {
          'total_borrowed': dashboard['totalDipinjam'] ?? 0,
          'returned': dashboard['totalDikembalikan'] ?? 0,
        };
      }

      setState(() {
        _userName = userName;
        _userRole = userRole;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _calculateMemberStats() async {
    try {
      final allBorrowings = await _apiService.getAllBorrowings();

      // Filter borrowings for current member
      final memberBorrowings = allBorrowings.where((borrowing) {
        // Check id_member field directly (this is the main field in API response)
        if (borrowing['id_member'] != null) {
          return borrowing['id_member'] == _currentMemberId;
        }
        // Fallback: check nested member.id
        final member = borrowing['member'];
        if (member != null && member['id'] != null) {
          return member['id'] == _currentMemberId;
        }
        // Fallback: check member_id field
        if (borrowing['member_id'] != null) {
          return borrowing['member_id'] == _currentMemberId;
        }
        return false;
      }).toList();

      // Debug: Print first few borrowings to understand structure
      for (int i = 0; i < memberBorrowings.length && i < 5; i++) {
        final borrowing = memberBorrowings[i];
      }

      int totalBorrowed = memberBorrowings.length;
      int currentlyBorrowed = 0;
      int returned = 0;
      int overdue = 0;

      for (var borrowing in memberBorrowings) {
        final status = borrowing['status'];
        final statusStr = status?.toString() ?? '';
        final returnedDate = borrowing['tanggal_pengembalian_aktual'];
        final updateDate = borrowing['updated_at'];
        final returnDate = borrowing['tanggal_pengembalian'];

        bool isReturned = false;
        bool isOverdue = false;

        if (statusStr == "2") {
          isReturned = true;
        } else if (returnedDate != null && returnedDate.toString().isNotEmpty) {
          isReturned = true;
        } else if (statusStr == "3") {
          try {
            final borrowDate = DateTime.parse(borrowing['tanggal_peminjaman']);
            final dueDate = DateTime.parse(returnDate);
            final updated = DateTime.parse(updateDate);
            final now = DateTime.now();
            bool wasReturnedToday = updated.year == now.year &&
                updated.month == now.month &&
                updated.day == now.day;

            final estimatedDueDate = borrowDate.add(const Duration(days: 8));

            if (wasReturnedToday &&
                returnDate == now.toString().substring(0, 10)) {
              isReturned = true;
            } else if (DateTime.parse(returnDate).isBefore(estimatedDueDate) ||
                DateTime.parse(returnDate).isAtSameMomentAs(estimatedDueDate)) {
              isReturned = true;
            } else if (now.isAfter(dueDate)) {
              isOverdue = true;
            } else {
              isReturned = true;
            }
          } catch (e) {
            isReturned = true;
          }
        }

        // Count based on the determined status
        if (isReturned) {
          returned++;
        } else if (isOverdue || statusStr == "4") {
          // status 4 might be used for actual overdue
          overdue++;
        } else if (statusStr == "1") {
          currentlyBorrowed++;
        } else {
          // Unknown status, treat as currently borrowed
          currentlyBorrowed++;
        }
      }

      setState(() {
        _stats = {
          'total_borrowed': totalBorrowed,
          'currently_borrowed': currentlyBorrowed,
          'returned': returned,
          'overdue': overdue,
        };
      });
    } catch (e) {
      setState(() {
        _stats = {
          'total_borrowed': 0,
          'currently_borrowed': 0,
          'returned': 0,
          'overdue': 0,
        };
      });
    }
  }

  String? _getExpectedReturnDate(dynamic borrowing) {
    // Prioritas field untuk tanggal jatuh tempo:
    // 1. expected_return_date (paling reliable)
    // 2. due_date
    // 3. tanggal_jatuh_tempo
    // 4. tanggal_pengembalian (fallback, tapi bisa berubah saat pengembalian)
    return borrowing['expected_return_date'] ??
        borrowing['due_date'] ??
        borrowing['tanggal_jatuh_tempo'] ??
        borrowing['tanggal_pengembalian'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Member'),
        backgroundColor:
            Colors.transparent, // Buat transparan agar gradient terlihat
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade400,
                Colors.indigo.shade600,
              ],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog(context);
              } else if (value == 'tips') {
                _showTipsDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'tips',
                child: ListTile(
                  leading:
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                  title: const Text('Tips Peminjaman'),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red.shade600),
                  title: const Text('Logout'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMemberData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.indigo.shade400,
                            Colors.indigo.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat Datang!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userName ?? 'Member',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Role: member',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Statistics Grid
                    const Text(
                      'Statistik Peminjaman',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_userRole == 'member') ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Dipinjam',
                              _stats['total_borrowed']?.toString() ?? '0',
                              Icons.library_books,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Sudah Dikembalikan',
                              _stats['returned']?.toString() ?? '0',
                              Icons.assignment_return,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Tampilkan statistik global untuk admin
                    ],

                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text(
                      'Aksi Cepat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            'Cari Buku',
                            Icons.search,
                            Colors.blue.shade700,
                            () async {
                              var result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MemberBooksListScreen(),
                                ),
                              );
                              print("result");
                              print(result);
                              if (result != null && result is String) {
                                _loadMemberData();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            'Riwayat Peminjaman',
                            Icons.history,
                            Colors.green.shade700,
                            () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BorrowedBooksScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadMemberData();
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // Ganti _buildStatCard dan _buildActionCard agar lebih modern:
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 34,
                color: color,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _apiService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  void _showTipsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text('Tips Peminjaman'),
          ],
        ),
        content: const Text(
          '• Kembalikan buku tepat waktu untuk menghindari denda\n'
          '• Maksimal peminjaman adalah 14 hari\n'
          '• Gunakan fitur pencarian untuk menemukan buku dengan mudah\n'
          '• Periksa status peminjaman secara berkala',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
