import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:args/args.dart';

final cookieJar = CookieJar();
final dio = Dio();

/// Login to your Aiyss account
Future<bool> login(String email, String password, [String? code]) async {
  final response = await dio.post(
    'https://aiyss.com/auth/login', data: {
      'email': email,
      'passwd': password,
      'code': code ?? ''
    }
  );

  final res = jsonDecode(response.data);

  print(res['msg']);

  return res['ret'] == 1;
}

/// Check-in
Future<String> checkin() async {
  final response = await dio.post('https://aiyss.com/user/checkin');

  final data = response.data;
  final messageBag = [data['msg']];

  if (data['ret'] == 1) {
    if (data['trafficInfo'] != null) {
      if (data['trafficInfo']['lastUsedTraffic'] != null) {
        messageBag.add("已用流量: ${data['trafficInfo']['lastUsedTraffic']}");
        messageBag.add("今日使用: ${data['trafficInfo']['todayUsedTraffic']}");
        messageBag.add("剩余流量: ${data['trafficInfo']['unUsedTraffic']}");
      }
    }
  }

  return messageBag.join('\n');
}

/// The entrypoint of this program
void main(List<String> arguments) {
  var parser = ArgParser();

  parser.addFlag('help', abbr: 'h', callback: (res) {
    if (res) {
      print(parser.usage);
      exit(0);
    }
  });

  parser.addOption('email', abbr: 'e', mandatory: true, help: 'The login email like: user@example.com');
  parser.addOption('password', abbr: 'p', mandatory: true);
  parser.addOption('code', abbr: 'c', help: 'The two-step verification code');

  late ArgResults res;

  try {
    res = parser.parse(arguments);
  } on FormatException catch (e) {
    print('Can not process your request.');
    print(parser.usage);
    exit(1);
  }

  dio.interceptors.add(CookieManager(cookieJar));
  login(res['email'], res['password'], res['code']).then(
    (bool res) async {
      if (res) {
        print(await checkin());
        exit(0);
      }
    }
  );
}
