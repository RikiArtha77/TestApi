import 'dart:convert';

import 'package:tesapi/Models/datanimodel.dart';
import 'package:http/http.dart' as http;

class ApiStatic{
  static final host='https://dev.wefgis.com';
  static var _token="8|x6bKsHp9STb0uLJsM11GkWhZEYRWPbv0IqlXvFi7";
    static Future<List<Petani>> getPetaniFilter(int pageKey, String _s, String _selectedChoice, {int pageSize = 10}) async {
    try {
      final response = await http.get(
        Uri.parse("$host/api/petani?page=$pageKey&size=$pageSize&s=$_s&publish=$_selectedChoice"),
        headers: {
          'Authorization': 'Bearer ' + _token,
        },
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        final parsed = json['data'].cast<Map<String, dynamic>>();
        return parsed.map<Petani>((json) => Petani.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

}