// Servidor estático mínimo para pré-visualizar build/web localmente.
// Uso: dart run tool/serve.dart  (porta 8923)
import 'dart:io';

const _port = 8923;
const _root = 'build/web';

const _types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.symbols': 'text/plain; charset=utf-8',
  '.bin': 'application/octet-stream',
};

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
  stdout.writeln('Servindo $_root em http://localhost:$_port');
  await for (final req in server) {
    var path = req.uri.path;
    // O build usa base href "/gymfit/"; removemos esse prefixo ao servir local.
    if (path.startsWith('/gymfit/')) path = path.substring('/gymfit'.length);
    if (path == '/gymfit') path = '/';
    if (path == '/' || path.isEmpty) path = '/index.html';
    var file = File('$_root$path');
    if (!file.existsSync()) {
      // Fallback SPA para o index.
      file = File('$_root/index.html');
    }
    final ext = path.contains('.') ? path.substring(path.lastIndexOf('.')) : '';
    req.response.headers.contentType = null;
    req.response.headers
        .set(HttpHeaders.contentTypeHeader, _types[ext] ?? 'application/octet-stream');
    try {
      await req.response.addStream(file.openRead());
    } catch (_) {}
    await req.response.close();
  }
}
