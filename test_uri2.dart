void main() {
  var uri = Uri.parse('https://mafiagame-351f8.web.app/#/?session=XYZ');
  print('Fragment: ${uri.fragment}'); // /?session=XYZ
  
  // Custom parser
  String? getSession(Uri u) {
    if (u.queryParameters.containsKey('session')) return u.queryParameters['session'];
    if (u.fragment.contains('session=')) {
      final parts = u.fragment.split('session=');
      if (parts.length > 1) {
        return parts[1].split('&').first;
      }
    }
    return null;
  }
  print('Session 1: ${getSession(uri)}');
}
