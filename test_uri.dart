void main() {
  var uri = Uri.parse('https://mafiagame-351f8.web.app/#/?session=XYZ');
  print('URL: $uri');
  print('Query params: ${uri.queryParameters}');
  
  var uri2 = Uri.parse('https://mafiagame-351f8.web.app/?session=XYZ#/');
  print('URL2: $uri2');
  print('Query params2: ${uri2.queryParameters}');
}
