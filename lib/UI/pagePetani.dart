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

  final PagingController<int, Petani> _pagingController = PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) async {
      await _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await ApiStatic.getPetaniFilter(pageKey, '', 'Y', pageSize: _pageSize);
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

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Widget _buildPetaniItem(Petani petani) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ListTile(
        leading: petani.foto.isNotEmpty
            ? Image.network(
                petani.foto,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
              )
            : const Icon(Icons.person, size: 60),
        title: Text(petani.nama.isNotEmpty ? petani.nama : 'Nama tidak tersedia'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NIK: ${petani.nik.isNotEmpty ? petani.nik : "-"}'),
            Text('Alamat: ${petani.alamat.isNotEmpty ? petani.alamat : "-"}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Petani'),
      ),
      body: PagedListView<int, Petani>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Petani>(
          itemBuilder: (context, petani, index) => _buildPetaniItem(petani),
          firstPageErrorIndicatorBuilder: (context) => Center(
            child: Text('Gagal memuat data, silakan coba lagi'),
          ),
          noItemsFoundIndicatorBuilder: (context) => Center(
            child: Text('Tidak ada data petani'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke halaman form tambah
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PetaniForm()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Petani',
      ),
    );
  }
}
