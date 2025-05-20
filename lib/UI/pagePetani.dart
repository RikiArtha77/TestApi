import 'package:flutter/material.dart';
import 'package:tesapi/Models/datanimodel.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:tesapi/Services/apiPetani.dart';
import 'package:tesapi/UI/petani_form.dart';

class PagePetani extends StatefulWidget {
  const PagePetani({super.key});

  @override
  State<PagePetani> createState() => _PagePetaniState();
}

class _PagePetaniState extends State<PagePetani> {
  static const _pageSize = 10;

  final PagingController<int, Petani> _pagingController =
      PagingController(firstPageKey: 1);

  String _searchQuery = '';
  String _selectedStatus = 'Y';

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await ApiStatic.getPetaniFilter(
        pageKey,
        _searchQuery,
        _selectedStatus,
        pageSize: _pageSize,
      );

      final isLastPage = newItems.length < _pageSize;

      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  Future<void> _deletePetani(String idPenjual) async {
    final result = await ApiStatic.deletePetani(idPenjual);
    if (!mounted) return;

    if (result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil dihapus')),
      );
      _pagingController.refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus data')),
      );
    }
  }

  Widget _buildPetaniItem(Petani petani) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        leading: ClipOval(
          child: petani.foto.isNotEmpty
              ? Image.network(
                  petani.foto,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person),
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
              ).then((_) => _pagingController.refresh());
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
  void dispose() {
    _pagingController.dispose();
    super.dispose();
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
                      _pagingController.refresh();
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
                      _pagingController.refresh();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => Future.sync(() => _pagingController.refresh()),
              child: PagedListView<int, Petani>(
                pagingController: _pagingController,
                builderDelegate: PagedChildBuilderDelegate<Petani>(
                  itemBuilder: (context, petani, index) => _buildPetaniItem(petani),
                  firstPageProgressIndicatorBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  newPageProgressIndicatorBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  firstPageErrorIndicatorBuilder: (context) =>
                      const Center(child: Text('Gagal memuat data')),
                  noItemsFoundIndicatorBuilder: (context) =>
                      const Center(child: Text('Tidak ada data petani')),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PetaniForm()),
          ).then((_) => _pagingController.refresh());
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Petani',
      ),
    );
  }
}
