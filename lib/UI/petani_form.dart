import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:tesapi/Models/datanimodel.dart'; // asumsi model Petani disini

class PetaniForm extends StatefulWidget {
  final Petani? petani; // null jika tambah, berisi data jika edit

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

  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.petani != null) {
      namaController.text = widget.petani!.nama;
      nikController.text = widget.petani!.nik;
      alamatController.text = widget.petani!.alamat;
      telpController.text = widget.petani!.telp;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        if (!mounted) return;
        setState(() {
          _image = File(picked.path);
        });
        print('Image selected: ${picked.path}');
      } else {
        print('No image selected');
      }
    } catch (e, stack) {
      print('Error picking image: $e');
      print(stack);
    }
  }

  Future<void> _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.petani != null;
    final uri = isEdit
        ? Uri.parse("https://dev.wefgis.com/api/petani/${widget.petani!.idPenjual}")
        : Uri.parse("https://dev.wefgis.com/api/petani");

    try {
      var request = http.MultipartRequest("POST", uri);
      request.headers['Authorization'] =
          "Bearer 8|x6bKsHp9STb0uLJsM11GkWhZEYRWPbv0IqlXvFi7";

      if (isEdit) {
        request.fields['_method'] = 'PUT';
      }

      request.fields['id_penjual'] = "127";
      request.fields['id_kelompok_tani'] = "4";
      request.fields['nama'] = namaController.text;
      request.fields['nik'] = nikController.text;
      request.fields['alamat'] = alamatController.text;
      request.fields['telp'] = telpController.text;
      request.fields['status'] = "Y";

      if (_image != null) {
        var stream = http.ByteStream(_image!.openRead());
        var length = await _image!.length();
        var multipartFile = http.MultipartFile(
          'foto',
          stream,
          length,
          filename: basename(_image!.path),
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? "Data berhasil diperbarui" : "Data berhasil ditambahkan")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengirim data: ${response.statusCode}")),
        );
        print(responseBody);
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
                decoration: InputDecoration(labelText: "Nama"),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: nikController,
                decoration: InputDecoration(labelText: "NIK"),
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: alamatController,
                decoration: InputDecoration(labelText: "Alamat"),
              ),
              TextFormField(
                controller: telpController,
                decoration: InputDecoration(labelText: "Telepon"),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text("Pilih Foto"),
              ),
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(_image!, height: 150),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _submitForm(context),
                child: Text(isEdit ? "Update" : "Kirim"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
