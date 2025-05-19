import 'dart:convert';
import 'package:tesapi/Models/datanimodel.dart';
import 'package:http/http.dart' as http;

class ApiStatic {
  static final String host = 'https://dev.wefgis.com';
  static String _token = "8|x6bKsHp9STb0uLJsM11GkWhZEYRWPbv0IqlXvFi7";

  /// Mengambil list Petani dengan pagination dan filter.
  /// [pageKey]: halaman saat ini (mulai dari 1)
  /// [_s]: keyword pencarian (kosongkan jika tidak ada)
  /// [_selectedChoice]: status publish, misal "Y"
  /// [pageSize]: jumlah data per halaman
  static Future<List<Petani>> getPetaniFilter(
    int pageKey,
    String _s,
    String _selectedChoice, {
    int pageSize = 10,
  }) async {
    try {
      final uri = Uri.parse("$host/api/petani").replace(queryParameters: {
        'page': pageKey.toString(),
        'size': pageSize.toString(),
        's': _s,
        'publish': _selectedChoice,
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);

        // Pastikan key 'data' ada dan merupakan List
        if (json.containsKey('data') && json['data'] is List) {
          final List<dynamic> list = json['data'];
          return list.map((item) => Petani.fromJson(item)).toList();
        } else {
          // Jika format tidak sesuai, kembalikan list kosong
          return [];
        }
      } else {
        print('Error: ${response.statusCode} ${response.reasonPhrase}');
        return [];
      }
    } catch (e, stack) {
      print('Exception in getPetaniFilter: $e');
      print(stack);
      return [];
    }
  }

  /// Menghapus data Petani berdasarkan [id].
  /// Kembalikan true jika berhasil, false jika gagal.
  static Future<bool> deletePetani(String idPenjual) async {
    try {
      final uri = Uri.parse("$host/api/petani/$idPenjual");
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Gagal hapus data petani, status: ${response.statusCode}');
        return false;
      }
    } catch (e, stack) {
      print('Exception in deletePetani: $e');
      print(stack);
      return false;
    }
  }
}
