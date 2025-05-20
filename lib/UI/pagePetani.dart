import 'package:flutter/material.dart';
import 'package:tesapi/Models/datanimodel.dart';
import 'package:tesapi/Services/apiPetani.dart';
import 'package:tesapi/UI/petani_form.dart';

class PagePetani extends StatefulWidget {
  const PagePetani({super.key});

  @override
  State<PagePetani> createState() => _PagePetaniState();
}

class _PagePetaniState extends State<PagePetani> {
  static const int _pageSize = 10;
  int _currentPage = 1;
  List<Petani> _petaniList = [];
  bool _isLastPage = false;
  bool _isLoading = false;

  String _searchQuery = '';
  String _selectedStatus = 'Y';

  // Ganti sesuai dengan base URL server kamu
  static const String baseUrl = "https://dev.wefgis.com";

  @override
  void initState() {
    super.initState();
    _fetchPage();
  }

  Future<void> _fetchPage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newItems = await ApiStatic.getPetaniFilter(
        _currentPage,
        _searchQuery,
        _selectedStatus,
        pageSize: _pageSize,
      );

      setState(() {
        _petaniList = newItems;
        _isLastPage = newItems.length < _pageSize;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (!_isLastPage) {
      _currentPage++;
      _fetchPage();
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      _currentPage--;
      _fetchPage();
    }
  }

  Future<void> _deletePetani(String idPenjual) async {
    final result = await ApiStatic.deletePetani(idPenjual);
    if (!mounted) return;

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil dihapus')),
      );
      _fetchPage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus data')),
      );
    }
  }

  // Helper untuk gabungkan base URL dan path foto
  String _getFullImageUrl(String fotoPath) {
    if (fotoPath.isEmpty) return '';
    if (fotoPath.startsWith('http')) return fotoPath;

    // Tangani slash agar tidak double slash
    if (baseUrl.endsWith('/') && fotoPath.startsWith('/')) {
      return baseUrl + fotoPath.substring(1);
    } else if (!baseUrl.endsWith('/') && !fotoPath.startsWith('/')) {
      return '$baseUrl/$fotoPath';
    } else {
      return baseUrl + fotoPath;
    }
  }

  Widget _buildPetaniItem(Petani petani) {
    final imageUrl = _getFullImageUrl(petani.foto);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        leading: ClipOval(
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person, size: 60),
                )
              : const Icon(Icons.person, size: 60),
        ),
        title: Text(petani.nama.isNotEmpty ? petani.nama : 'Nama tidak tersedia'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NIK: ${petani.nik.isNotEmpty ? petani.nik : "-"}'),
            Text('Alamat: ${petani.alamat.isNotEmpty ? petani.alamat : "-"}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PetaniForm(petani: petani),
                ),
              ).then((_) => _fetchPage());
            } else if (value == 'delete') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Konfirmasi"),
                  content: const Text("Yakin ingin menghapus data ini?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deletePetani(petani.idPenjual.toString());
                      },
                      child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Petani')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Cari Nama',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _currentPage = 1;
                      _fetchPage();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Semua')),
                    DropdownMenuItem(value: 'Y', child: Text('Aktif')),
                    DropdownMenuItem(value: 'N', child: Text('Tidak Aktif')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                      _currentPage = 1;
                      _fetchPage();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _petaniList.isEmpty
                    ? const Center(child: Text('Tidak ada data petani'))
                    : ListView.builder(
                        itemCount: _petaniList.length,
                        itemBuilder: (context, index) {
                          return _buildPetaniItem(_petaniList[index]);
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 1 ? _prevPage : null,
                  child: const Text('Previous'),
                ),
                const SizedBox(width: 20),
                Text('Page $_currentPage'),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: !_isLastPage ? _nextPage : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PetaniForm()),
          ).then((_) => _fetchPage());
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Petani',
      ),
    );
  }
}