import 'package:flutter/material.dart';
import 'package:perpus_app/api/api_service.dart';
import 'package:perpus_app/models/book.dart';
import 'package:perpus_app/models/category.dart' as CategoryModel;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:perpus_app/screens/book_detail/book_detail_screen.dart';

class AdminBookManagementScreen extends StatefulWidget {
  const AdminBookManagementScreen({super.key});

  @override
  State<AdminBookManagementScreen> createState() =>
      _AdminBookManagementScreenState();
}

class _AdminBookManagementScreenState extends State<AdminBookManagementScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Book> _books = [];
  List<CategoryModel.Category> _categories = [];
  List<String> _authors = [];
  List<String> _publishers = [];
  List<int> _years = [];

  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _perPage = 10;

  // Track if any changes were made for returning to dashboard
  bool _hasChanges = false;
  // Override for pop signal (optional, for WillPopScope)
  Future<bool> _onWillPop() async {
    Navigator.of(context).pop(_hasChanges);
    return false;
  }

  // Filter variables
  int? _selectedCategoryId;
  String? _selectedAuthor;
  String? _selectedPublisher;
  int? _selectedYear;
  String? _selectedStatus;
  String _sortBy = 'judul';
  String _sortOrder = 'asc';

  // Filter options
  final List<String> _statusOptions = ['Semua', 'Tersedia', 'Dipinjam'];
  final List<String> _sortByOptions = [
    'judul',
    'pengarang',
    'penerbit',
    'tahun'
  ];
  final List<String> _sortOrderOptions = ['asc', 'desc'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    try {
      // Load filter options
      await Future.wait([
        _loadCategories(),
        _loadAuthors(),
        _loadPublishers(),
        _loadYears(),
      ]);

      // Load books
      await _loadBooks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadBooks({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 1;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.getBooksPaginated(
        page: _currentPage,
        perPage: _perPage,
        search:
            _searchController.text.isNotEmpty ? _searchController.text : null,
        categoryId: _selectedCategoryId,
        author: _selectedAuthor,
        publisher: _selectedPublisher,
        year: _selectedYear,
        status: _selectedStatus,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (mounted) {
        setState(() {
          _books = result['books'] ?? [];
          _currentPage = result['current_page'] ?? 1;
          _totalPages = result['total_pages'] ?? 1;
          _totalItems = result['total_items'] ?? 0;
          _perPage = result['per_page'] ?? 10;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat buku: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {}
  }

  Future<void> _loadAuthors() async {
    try {
      final authors = await _apiService.getAuthors();
      if (mounted) {
        setState(() => _authors = authors);
      }
    } catch (e) {}
  }

  Future<void> _loadPublishers() async {
    try {
      final publishers = await _apiService.getPublishers();
      if (mounted) {
        setState(() => _publishers = publishers);
      }
    } catch (e) {}
  }

  Future<void> _loadYears() async {
    try {
      final years = await _apiService.getPublicationYears();
      if (mounted) {
        setState(() => _years = years);
      }
    } catch (e) {}
  }

  void _showAddBookDialog() {
    _showBookDialog();
  }

  void _showEditBookDialog(Book book) {
    _showBookDialog(book: book);
  }

  void _showBookDialog({Book? book}) async {
    // Pastikan categories sudah dimuat
    if (_categories.isEmpty) {
      await _loadCategories();
    }

    final titleController = TextEditingController(text: book?.judul ?? '');
    final authorController = TextEditingController(text: book?.pengarang ?? '');
    final publisherController =
        TextEditingController(text: book?.penerbit ?? '');
    final yearController = TextEditingController(text: book?.tahun ?? '');
    final stockController =
        TextEditingController(text: book?.stok.toString() ?? '1');

    int? selectedCategoryId = book?.category.id;
    File? selectedImage;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(book == null ? 'Tambah Buku' : 'Edit Buku'),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Judul Buku
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Buku',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Pengarang
                  TextField(
                    controller: authorController,
                    decoration: const InputDecoration(
                      labelText: 'Pengarang',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Penerbit
                  TextField(
                    controller: publisherController,
                    decoration: const InputDecoration(
                      labelText: 'Penerbit',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tahun
                  TextField(
                    controller: yearController,
                    decoration: const InputDecoration(
                      labelText: 'Tahun',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  // Stok
                  TextField(
                    controller: stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stok',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  // Kategori Dropdown
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                        items: _categories.isEmpty
                            ? [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('Loading categories...'),
                                )
                              ]
                            : [
                                const DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('Pilih Kategori'),
                                ),
                                ..._categories
                                    .map<DropdownMenuItem<int>>((category) {
                                  return DropdownMenuItem<int>(
                                    value: category.id,
                                    child: SizedBox(
                                      width: constraints.maxWidth -
                                          80, // Biar tidak overflow
                                      child: Text(
                                        category.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCategoryId = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Image picker section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gambar Sampul',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Image preview
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : (book != null &&
                                      book.path != null &&
                                      book.path!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        'http://perpus-api.mamorasoft.com/${book.path!}',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                        ),
                        const SizedBox(height: 12),

                        // Image picker buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 80,
                                  );
                                  if (image != null) {
                                    setDialogState(() {
                                      selectedImage = File(image.path);
                                    });
                                  }
                                },
                                icon: const Icon(Icons.photo_library, size: 16),
                                label: const Text('Galeri'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.camera,
                                    imageQuality: 80,
                                  );
                                  if (image != null) {
                                    setDialogState(() {
                                      selectedImage = File(image.path);
                                    });
                                  }
                                },
                                icon: const Icon(Icons.camera_alt, size: 16),
                                label: const Text('Kamera'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Remove image button
                        if (selectedImage != null ||
                            (book != null &&
                                book.path != null &&
                                book.path!.isNotEmpty))
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  selectedImage = null;
                                });
                              },
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text('Hapus Gambar'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validasi categories tersedia
                if (_categories.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Kategori belum dimuat. Silakan coba lagi.')),
                  );
                  return;
                }

                // Validasi lengkap semua field required
                if (titleController.text.trim().isEmpty ||
                    authorController.text.trim().isEmpty ||
                    publisherController.text.trim().isEmpty ||
                    yearController.text.trim().isEmpty ||
                    stockController.text.trim().isEmpty ||
                    selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Mohon lengkapi semua field wajib')),
                  );
                  return;
                }

                // Validasi format tahun
                final year = int.tryParse(yearController.text.trim());
                if (year == null ||
                    year < 1000 ||
                    year > DateTime.now().year + 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Format tahun tidak valid')),
                  );
                  return;
                }

                // Validasi format stok
                final stock = int.tryParse(stockController.text.trim());
                if (stock == null || stock < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Format stok tidak valid')),
                  );
                  return;
                }

                try {
                  final bookData = {
                    'judul': titleController.text.trim(),
                    'pengarang': authorController.text.trim(),
                    'penerbit': publisherController.text.trim(),
                    'tahun': yearController.text.trim(),
                    'category_id': selectedCategoryId.toString(),
                    'stok': stockController.text.trim(),
                  };

                  bool success;
                  if (book == null) {
                    // Create new book
                    success = await _apiService.addBookWithImage(
                        bookData, selectedImage);
                    if (success) {
                      _hasChanges = true;
                      Navigator.pop(context);
                      _loadBooks();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Buku berhasil ditambahkan')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal menambahkan buku')),
                      );
                    }
                  } else {
                    // Update existing book
                    success = await _apiService.updateBookWithImage(
                        book.id, bookData, selectedImage);
                    if (success) {
                      _hasChanges = true;
                      Navigator.pop(context);
                      _loadBooks();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Buku berhasil diupdate')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal mengupdate buku')),
                      );
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text(book == null ? 'Tambah' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteBook(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Buku'),
        content:
            Text('Apakah Anda yakin ingin menghapus buku "${book.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _apiService.deleteBook(book.id);
                _hasChanges = true;
                Navigator.pop(context);
                _loadBooks();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Buku berhasil dihapus')),
                );
              } catch (e) {
                Navigator.pop(context);
                // Ambil pesan error dari API jika ada
                String errorMsg = 'Gagal menghapus buku';
                if (e is ApiException) {
                  errorMsg = e.message;
                } else if (e is Exception) {
                  final msg = e.toString();
                  // Coba parsing pesan dari response API
                  final match =
                      RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(msg);
                  if (match != null) {
                    errorMsg = match.group(1)!;
                  } else {
                    errorMsg = msg;
                  }
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMsg)),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedAuthor = null;
      _selectedPublisher = null;
      _selectedYear = null;
      _selectedStatus = null;
      _sortBy = 'judul';
      _sortOrder = 'asc';
      _searchController.clear();
    });
    _loadBooks(resetPage: true);
  }

  bool _hasActiveFilters() {
    return _selectedCategoryId != null ||
        _selectedAuthor != null ||
        _selectedPublisher != null ||
        _selectedYear != null ||
        (_selectedStatus != null && _selectedStatus != 'Semua') ||
        _searchController.text.isNotEmpty ||
        _sortBy != 'judul' ||
        _sortOrder != 'asc';
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedCategoryId != null) count++;
    if (_selectedAuthor != null) count++;
    if (_selectedPublisher != null) count++;
    if (_selectedYear != null) count++;
    if (_selectedStatus != null && _selectedStatus != 'Semua') count++;
    if (_searchController.text.isNotEmpty) count++;
    if (_sortBy != 'judul' || _sortOrder != 'asc') count++;
    return count;
  }

  List<Widget> _buildActiveFilterChips() {
    List<Widget> chips = [];

    if (_selectedCategoryId != null) {
      final categoryName =
          _categories.firstWhere((c) => c.id == _selectedCategoryId).name;
      chips.add(_buildFilterChip('Kategori: $categoryName', () {
        setState(() => _selectedCategoryId = null);
        _loadBooks(resetPage: true);
      }));
    }

    if (_selectedAuthor != null) {
      chips.add(_buildFilterChip('Pengarang: $_selectedAuthor', () {
        setState(() => _selectedAuthor = null);
        _loadBooks(resetPage: true);
      }));
    }

    if (_selectedPublisher != null) {
      chips.add(_buildFilterChip('Penerbit: $_selectedPublisher', () {
        setState(() => _selectedPublisher = null);
        _loadBooks(resetPage: true);
      }));
    }

    if (_selectedYear != null) {
      chips.add(_buildFilterChip('Tahun: $_selectedYear', () {
        setState(() => _selectedYear = null);
        _loadBooks(resetPage: true);
      }));
    }

    if (_selectedStatus != null && _selectedStatus != 'Semua') {
      chips.add(_buildFilterChip('Status: $_selectedStatus', () {
        setState(() => _selectedStatus = null);
        _loadBooks(resetPage: true);
      }));
    }

    if (_searchController.text.isNotEmpty) {
      chips.add(_buildFilterChip('Pencarian: "${_searchController.text}"', () {
        setState(() => _searchController.clear());
        _loadBooks(resetPage: true);
      }));
    }

    if (_sortBy != 'judul' || _sortOrder != 'asc') {
      String sortLabel = _sortBy;
      switch (_sortBy) {
        case 'judul':
          sortLabel = 'Judul';
          break;
        case 'pengarang':
          sortLabel = 'Pengarang';
          break;
        case 'penerbit':
          sortLabel = 'Penerbit';
          break;
        case 'tahun':
          sortLabel = 'Tahun';
          break;
      }
      chips.add(_buildFilterChip(
          'Urutan: $sortLabel ${_sortOrder == 'asc' ? 'A-Z' : 'Z-A'}', () {
        setState(() {
          _sortBy = 'judul';
          _sortOrder = 'asc';
        });
        _loadBooks(resetPage: true);
      }));
    }

    return chips;
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: Colors.blue.shade100,
      deleteIconColor: Colors.blue.shade700,
      labelStyle: TextStyle(color: Colors.blue.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Buku'),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddBookDialog,
              tooltip: 'Tambah Buku',
            ),
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
          onRefresh: _loadBooks,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Search Bar
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Cari buku...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _loadBooks(resetPage: true);
                    },
                  ),
                ),
              ),

              // Filter Section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ExpansionTile(
                    title: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Filter & Sorting'),
                          const SizedBox(width: 6),
                          if (_hasActiveFilters())
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _getActiveFilterCount().toString(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                    leading: Icon(
                      Icons.filter_list,
                      color: _hasActiveFilters() ? Colors.blue : null,
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Active filters summary
                            if (_hasActiveFilters())
                              Container(
                                padding: const EdgeInsets.all(6),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Icon(Icons.filter_alt,
                                              size: 16,
                                              color: Colors.blue.shade700),
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            'Filter Aktif:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 1,
                                      children: _buildActiveFilterChips(),
                                    ),
                                  ],
                                ),
                              ),

                            // Filter controls
                            Column(
                              children: [
                                // Category Filter
                                DropdownButtonFormField<int>(
                                  value: _selectedCategoryId,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    labelText: 'Kategori',
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor: _selectedCategoryId != null
                                        ? Colors.blue.shade50
                                        : Colors.white,
                                    prefixIcon: Icon(
                                      Icons.category,
                                      size: 18,
                                      color: _selectedCategoryId != null
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem<int>(
                                      value: null,
                                      child: Text('Semua Kategori'),
                                    ),
                                    ..._categories
                                        .map<DropdownMenuItem<int>>((category) {
                                      return DropdownMenuItem<int>(
                                        value: category.id,
                                        child: Text(
                                          category.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedCategoryId = value);
                                    _loadBooks(resetPage: true);
                                  },
                                ),
                                const SizedBox(height: 6),

                                // Author Filter
                                DropdownButtonFormField<String>(
                                  value: _selectedAuthor,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    labelText: 'Pengarang',
                                    border: const OutlineInputBorder(),
                                    filled: true,
                                    fillColor: _selectedAuthor != null
                                        ? Colors.blue.shade50
                                        : Colors.white,
                                    prefixIcon: Icon(
                                      Icons.person,
                                      size: 18,
                                      color: _selectedAuthor != null
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: null,
                                      child: Text('Semua Pengarang'),
                                    ),
                                    ..._authors.map((author) {
                                      return DropdownMenuItem<String>(
                                        value: author,
                                        child: Text(
                                          author,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedAuthor = value);
                                    _loadBooks(resetPage: true);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Publisher and Year in Row
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _selectedPublisher,
                                    isDense: true,
                                    decoration: InputDecoration(
                                      labelText: 'Penerbit',
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: _selectedPublisher != null
                                          ? Colors.blue.shade50
                                          : Colors.white,
                                      prefixIcon: Icon(
                                        Icons.business,
                                        size: 18,
                                        color: _selectedPublisher != null
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('Semua Penerbit',
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      ..._publishers.map((publisher) {
                                        return DropdownMenuItem<String>(
                                          value: publisher,
                                          child: Text(
                                            publisher,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (value) {
                                      setState(
                                          () => _selectedPublisher = value);
                                      _loadBooks(resetPage: true);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    isExpanded: true,
                                    value: _selectedYear,
                                    isDense: true,
                                    decoration: InputDecoration(
                                      labelText: 'Tahun',
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: _selectedYear != null
                                          ? Colors.blue.shade50
                                          : Colors.white,
                                      prefixIcon: Icon(
                                        Icons.calendar_today,
                                        size: 12,
                                        color: _selectedYear != null
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    items: [
                                      const DropdownMenuItem<int>(
                                        value: null,
                                        child: Text('Semua Tahun',
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      ..._years.map((year) {
                                        return DropdownMenuItem<int>(
                                          value: year,
                                          child: Text(year.toString(),
                                              overflow: TextOverflow.ellipsis),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (value) {
                                      setState(() => _selectedYear = value);
                                      _loadBooks(resetPage: true);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Status Filter
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              isDense: true,
                              decoration: InputDecoration(
                                labelText: 'Status Ketersediaan',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: (_selectedStatus != null &&
                                        _selectedStatus != 'Semua')
                                    ? Colors.blue.shade50
                                    : Colors.white,
                                prefixIcon: Icon(
                                  Icons.inventory,
                                  size: 12,
                                  color: (_selectedStatus != null &&
                                          _selectedStatus != 'Semua')
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                              ),
                              items: _statusOptions.map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Row(
                                    children: [
                                      Icon(
                                        status == 'Tersedia'
                                            ? Icons.check_circle
                                            : status == 'Dipinjam'
                                                ? Icons.remove_circle
                                                : Icons.all_inclusive,
                                        size: 16,
                                        color: status == 'Tersedia'
                                            ? Colors.green
                                            : status == 'Dipinjam'
                                                ? Colors.red
                                                : Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(status),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedStatus = value);
                                _loadBooks(resetPage: true);
                              },
                            ),
                            const SizedBox(height: 8),

                            // Sort options
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _sortBy,
                                    decoration: InputDecoration(
                                      labelText: 'Urutkan berdasarkan',
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: _sortBy != 'judul'
                                          ? Colors.orange.shade50
                                          : Colors.white,
                                      prefixIcon: Icon(
                                        Icons.sort,
                                        color: _sortBy != 'judul'
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                    ),
                                    items: _sortByOptions.map((option) {
                                      String displayText = option;
                                      IconData iconData = Icons.sort_by_alpha;
                                      switch (option) {
                                        case 'judul':
                                          displayText = 'Judul';
                                          iconData = Icons.title;
                                          break;
                                        case 'pengarang':
                                          displayText = 'Pengarang';
                                          iconData = Icons.person;
                                          break;
                                        case 'penerbit':
                                          displayText = 'Penerbit';
                                          iconData = Icons.business;
                                          break;
                                        case 'tahun':
                                          displayText = 'Tahun';
                                          iconData = Icons.calendar_today;
                                          break;
                                      }
                                      return DropdownMenuItem<String>(
                                        value: option,
                                        child: Row(
                                          children: [
                                            Icon(iconData, size: 16),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                displayText,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(
                                          () => _sortBy = value ?? 'judul');
                                      _loadBooks(resetPage: true);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _sortOrder,
                                    decoration: InputDecoration(
                                      labelText: 'Urutan',
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: _sortOrder != 'asc'
                                          ? Colors.orange.shade50
                                          : Colors.white,
                                      prefixIcon: Icon(
                                        _sortOrder == 'asc'
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        color: _sortOrder != 'asc'
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                    ),
                                    items: _sortOrderOptions.map((option) {
                                      return DropdownMenuItem<String>(
                                        value: option,
                                        child: Row(
                                          children: [
                                            Icon(
                                              option == 'asc'
                                                  ? Icons.arrow_upward
                                                  : Icons.arrow_downward,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                option == 'asc'
                                                    ? 'A-Z (Naik)'
                                                    : 'Z-A (Turun)',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(
                                          () => _sortOrder = value ?? 'asc');
                                      _loadBooks(resetPage: true);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Reset & info
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _clearFilters,
                                    icon: const Icon(Icons.clear_all),
                                    label: const Text('Reset Semua Filter'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade50,
                                      foregroundColor: Colors.red.shade700,
                                      side: BorderSide(
                                          color: Colors.red.shade200),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      border: Border.all(
                                          color: Colors.green.shade200),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.book,
                                            size: 16,
                                            color: Colors.green.shade700),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            'Total: $_totalItems buku',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Books List
              _isLoading
                  ? const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _books.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              'Tidak ada buku ditemukan',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final book = _books[index];
                              return _BookListItem(
                                book: book,
                                onEdit: () => _showEditBookDialog(book),
                                onDelete: () => _deleteBook(book),
                              );
                            },
                            childCount: _books.length,
                          ),
                        ),

              // Pagination Controls
              if (_totalPages > 1)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border:
                          Border(top: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Halaman $_currentPage dari $_totalPages ($_totalItems buku)',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _currentPage > 1
                                  ? () {
                                      setState(() => _currentPage--);
                                      _loadBooks();
                                    }
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                              label: const Text('Sebelumnya'),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _totalPages > 7 ? 7 : _totalPages,
                                    (index) {
                                      int pageNumber;
                                      if (_totalPages <= 7) {
                                        pageNumber = index + 1;
                                      } else if (_currentPage <= 4) {
                                        pageNumber = index + 1;
                                      } else if (_currentPage >
                                          _totalPages - 4) {
                                        pageNumber = _totalPages - 6 + index;
                                      } else {
                                        pageNumber = _currentPage - 3 + index;
                                      }

                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                pageNumber == _currentPage
                                                    ? Colors.red.shade600
                                                    : Colors.grey.shade300,
                                            foregroundColor:
                                                pageNumber == _currentPage
                                                    ? Colors.white
                                                    : Colors.black,
                                            minimumSize: const Size(40, 36),
                                            padding: EdgeInsets.zero,
                                          ),
                                          onPressed: () {
                                            setState(() =>
                                                _currentPage = pageNumber);
                                            _loadBooks();
                                          },
                                          child: Text('$pageNumber'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _currentPage < _totalPages
                                  ? () {
                                      setState(() => _currentPage++);
                                      _loadBooks();
                                    }
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                              label: const Text('Selanjutnya'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// **BARU:** Widget terpisah untuk menampilkan item buku di sisi admin
class _BookListItem extends StatelessWidget {
  final Book book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BookListItem({
    required this.book,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(book: book),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                height: 110,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                      ? Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.book, color: Colors.grey),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.judul,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('oleh ${book.pengarang}',
                        style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    Text('Kategori: ${book.category.name}'),
                    Text('Stok: ${book.stok}'),
                    Text('Penerbit: ${book.penerbit} (${book.tahun})'),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Hapus',
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
