import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:tesapi/Models/kelompok.dart';
import 'package:tesapi/Services/apiPetani.dart';
import 'package:tesapi/Models/datanimodel.dart';


class PetaniForm extends StatefulWidget {
  final Petani? petani;

  const PetaniForm({Key? key, this.petani}) : super(key: key);

  @override
  _PetaniFormState createState() => _PetaniFormState();
}

class _PetaniFormState extends State<PetaniForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController nikController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController telpController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  List<Kelompok> _kelompok = [];
  String idKelompok = '';
  String? _selectedStatus;
  String idPenjual = '';

  File? _selectedImage;
  String? _imageUrl;

  final List<String> _statuses = ['Aktif', 'Tidak Aktif'];

  @override
  void initState() {
    super.initState();

    if (widget.petani != null) {
      idPenjual = widget.petani!.idPenjual;
      namaController.text = widget.petani!.nama;
      nikController.text = widget.petani!.nik;
      alamatController.text = widget.petani!.alamat;
      telpController.text = widget.petani!.telp;
      idKelompok = widget.petani!.idKelompokTani;
      _selectedStatus = widget.petani!.status;

      if (widget.petani!.foto.isNotEmpty) {
        final baseUrl = "https://dev.wefgis.com/storage/";
        if (widget.petani!.foto.startsWith("http")) {
          _imageUrl = widget.petani!.foto;
        } else {
          _imageUrl = baseUrl + widget.petani!.foto;
        }
      } else {
        _imageUrl = null;
      }
    }

    getKelompok();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _imageUrl = null;
      });
    }
  }

  void getKelompok() async {
    final response = await ApiStatic.getKelompokTani();
    setState(() {
      _kelompok = response.toList();
    });
  }

  Future<void> _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status harus dipilih')),
      );
      return;
    }

    final isEdit = widget.petani != null;
    final uri = isEdit
        ? Uri.parse("https://dev.wefgis.com/api/petani/${widget.petani!.idPenjual}")
        : Uri.parse("https://dev.wefgis.com/api/petani");

    try {
      var request = http.MultipartRequest(isEdit ? "POST" : "POST", uri);
      request.headers['Authorization'] =
          "Bearer 8|x6bKsHp9STb0uLJsM11GkWhZEYRWPbv0IqlXvFi7";

      if (isEdit) {
        request.fields['_method'] = 'PUT';
      }
      
      request.fields['id_penjual'] = "127";
      request.fields['id_kelompok_tani'] = idKelompok;
      request.fields['nama'] = namaController.text;
      request.fields['nik'] = nikController.text;
      request.fields['alamat'] = alamatController.text;
      request.fields['telp'] = telpController.text;
      request.fields['status'] = _selectedStatus!;

      if (_selectedImage != null) {
        var stream = http.ByteStream(_selectedImage!.openRead());
        var length = await _selectedImage!.length();
        var multipartFile = http.MultipartFile(
          'foto',
          stream,
          length,
          filename: basename(_selectedImage!.path),
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  isEdit ? "Data berhasil diperbarui" : "Data berhasil ditambahkan")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengirim data: ${response.statusCode}")),
        );
        print("Response error: $responseBody");
      }
    } catch (e, stack) {
      print('Exception saat submit form: $e');
      print(stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    nikController.dispose();
    alamatController.dispose();
    telpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.petani != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Petani' : 'Tambah Petani')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: namaController,
                decoration: const InputDecoration(labelText: "Nama"),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: nikController,
                decoration: const InputDecoration(labelText: "NIK"),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: alamatController,
                decoration: const InputDecoration(labelText: "Alamat"),
              ),
              TextFormField(
                controller: telpController,
                decoration: const InputDecoration(labelText: "Telepon"),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text("Pilih Foto"),
              ),

              const SizedBox(height: 10),

              // Tampilkan gambar
              if (_selectedImage != null)
                Image.file(_selectedImage!, height: 150, fit: BoxFit.cover)
              else if (_imageUrl != null && _imageUrl!.isNotEmpty)
                Image.network(
                  _imageUrl!,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 150),
                )
              else
                const Icon(Icons.image_not_supported, size: 150),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: idKelompok == '' ? null : idKelompok,
                hint: const Text("Pilih Kelompok"),
                decoration:
                    const InputDecoration(icon: Icon(Icons.category_rounded)),
                items: _kelompok.map((item) {
                  return DropdownMenuItem(
                    child: Text(item.namaKelompok),
                    value: item.idKelompokTani,
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    idKelompok = value ?? '';
                  });
                },
                validator: (u) => u == null || u.isEmpty ? "Wajib Diisi" : null,
              ),

              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  ..._statuses.map((status) {
                    return RadioListTile<String>(
                      title: Text(status),
                      value: status,
                      groupValue: _selectedStatus,
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                    );
                  }).toList(),
                  if (_selectedStatus == null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        'Pilih salah satu status',
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () => _submitForm(context),
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}