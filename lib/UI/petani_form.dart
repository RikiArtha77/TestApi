import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

class PetaniForm extends StatefulWidget {
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
      if (mounted) {
      }
    }
  }

  Future<void> _submitForm(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      print('Form tidak valid');
      return;
    }

    try {
      print('Mulai submit form...');
      var uri = Uri.parse("https://dev.wefgis.com/api/petani");
      var request = http.MultipartRequest("POST", uri);

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
        print('File foto ditambahkan: ${basename(_image!.path)}, size: $length bytes');
      } else {
        print('Tidak ada file foto yang diupload');
      }

      print('Mengirim request ke server...');
      var response = await request.send();

      print('Response status: ${response.statusCode}');
      var responseBody = await response.stream.bytesToString();
      print('Response body: $responseBody');

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Data berhasil dikirim")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengirim data: ${response.statusCode}")),
        );
      }
    } catch (e, stack) {
      print('Exception saat submit form: $e');
      print(stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat mengirim data: $e')),
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
    return Scaffold(
      appBar: AppBar(title: Text('Form Petani')),
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
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text("Pilih Foto"),
              ),
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.file(_image!, height: 150),
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _submitForm(context),
                child: Text("Kirim"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
