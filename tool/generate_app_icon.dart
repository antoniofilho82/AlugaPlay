import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _size = 1024;

Future<void> main() async {
  final iconDirectory = Directory('assets/icon');
  await iconDirectory.create(recursive: true);

  final appIcon = _Raster(_size);
  appIcon.fillRoundedRect(
    16,
    16,
    _size - 16,
    _size - 16,
    216,
    const _Color(6, 13, 9),
  );
  appIcon.drawWaves(clipToIconShape: true);
  appIcon.drawEmblem();
  await File('assets/icon/app_icon.png').writeAsBytes(appIcon.encodePng());

  final foreground = _Raster(_size);
  foreground.drawWaves();
  foreground.drawEmblem();
  await File('assets/icon/app_icon_foreground.png')
      .writeAsBytes(foreground.encodePng());
}

class _Color {
  const _Color(this.red, this.green, this.blue, [this.alpha = 255]);

  final int red;
  final int green;
  final int blue;
  final int alpha;
}

class _Raster {
  _Raster(this.size) : pixels = Uint8List(size * size * 4);

  final int size;
  final Uint8List pixels;

  void _blend(int x, int y, _Color color, [double opacity = 1]) {
    if (x < 0 || y < 0 || x >= size || y >= size) return;
    final offset = (y * size + x) * 4;
    final sourceAlpha = (color.alpha / 255 * opacity).clamp(0, 1);
    final targetAlpha = pixels[offset + 3] / 255;
    final outAlpha = sourceAlpha + targetAlpha * (1 - sourceAlpha);
    if (outAlpha <= 0) return;

    pixels[offset] =
        ((color.red * sourceAlpha +
                    pixels[offset] * targetAlpha * (1 - sourceAlpha)) /
                outAlpha)
            .round();
    pixels[offset + 1] =
        ((color.green * sourceAlpha +
                    pixels[offset + 1] * targetAlpha * (1 - sourceAlpha)) /
                outAlpha)
            .round();
    pixels[offset + 2] =
        ((color.blue * sourceAlpha +
                    pixels[offset + 2] * targetAlpha * (1 - sourceAlpha)) /
                outAlpha)
            .round();
    pixels[offset + 3] = (outAlpha * 255).round();
  }

  bool _insideRoundedRect(
    double x,
    double y,
    double left,
    double top,
    double right,
    double bottom,
    double radius,
  ) {
    final halfWidth = (right - left) / 2;
    final halfHeight = (bottom - top) / 2;
    final centerX = (right + left) / 2;
    final centerY = (bottom + top) / 2;
    final qx = (x - centerX).abs() - (halfWidth - radius);
    final qy = (y - centerY).abs() - (halfHeight - radius);
    final outside = math.sqrt(
      math.pow(math.max(qx, 0), 2) + math.pow(math.max(qy, 0), 2),
    );
    return outside + math.min(math.max(qx, qy), 0) <= radius;
  }

  void fillRoundedRect(
    double left,
    double top,
    double right,
    double bottom,
    double radius,
    _Color color,
  ) {
    for (var y = top.floor(); y < bottom.ceil(); y++) {
      for (var x = left.floor(); x < right.ceil(); x++) {
        var coverage = 0;
        for (final dy in const [0.25, 0.75]) {
          for (final dx in const [0.25, 0.75]) {
            if (_insideRoundedRect(
              x + dx,
              y + dy,
              left,
              top,
              right,
              bottom,
              radius,
            )) {
              coverage++;
            }
          }
        }
        if (coverage > 0) _blend(x, y, color, coverage / 4);
      }
    }
  }

  void strokeRoundedRect(
    double left,
    double top,
    double right,
    double bottom,
    double radius,
    double strokeWidth,
    _Color color,
  ) {
    for (var y = top.floor(); y < bottom.ceil(); y++) {
      for (var x = left.floor(); x < right.ceil(); x++) {
        var coverage = 0;
        for (final dy in const [0.25, 0.75]) {
          for (final dx in const [0.25, 0.75]) {
            final px = x + dx;
            final py = y + dy;
            final outer = _insideRoundedRect(
              px,
              py,
              left,
              top,
              right,
              bottom,
              radius,
            );
            final inner = _insideRoundedRect(
              px,
              py,
              left + strokeWidth,
              top + strokeWidth,
              right - strokeWidth,
              bottom - strokeWidth,
              math.max(0, radius - strokeWidth),
            );
            if (outer && !inner) coverage++;
          }
        }
        if (coverage > 0) _blend(x, y, color, coverage / 4);
      }
    }
  }

  _Color _gradientColor(double position, int alpha) {
    final t = position.clamp(0, 1);
    const start = _Color(52, 211, 153);
    const middle = _Color(34, 197, 94);
    const end = _Color(5, 150, 105);
    final first = t < 0.5 ? start : middle;
    final second = t < 0.5 ? middle : end;
    final amount = t < 0.5 ? t * 2 : (t - 0.5) * 2;
    return _Color(
      (first.red + (second.red - first.red) * amount).round(),
      (first.green + (second.green - first.green) * amount).round(),
      (first.blue + (second.blue - first.blue) * amount).round(),
      alpha,
    );
  }

  void drawWaves({bool clipToIconShape = false}) {
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        var topCoverage = 0;
        var topInnerCoverage = 0;
        var bottomCoverage = 0;
        var bottomInnerCoverage = 0;
        for (final dy in const [0.25, 0.75]) {
          for (final dx in const [0.25, 0.75]) {
            final nx = (x + dx) / size;
            final ny = (y + dy) / size;
            if (clipToIconShape &&
                !_insideRoundedRect(
                  nx * size,
                  ny * size,
                  16,
                  16,
                  size - 16,
                  size - 16,
                  216,
                )) {
              continue;
            }
            if (nx < 0.82 &&
                ny < 0.015 + 0.29 * math.pow(1 - nx / 0.82, 1.28)) {
              topCoverage++;
            }
            if (nx < 0.61 && ny < 0.01 + 0.19 * math.pow(1 - nx / 0.61, 1.16)) {
              topInnerCoverage++;
            }
            if (nx > 0.18 &&
                ny > 0.78 - 0.30 * math.pow((nx - 0.18) / 0.82, 0.72)) {
              bottomCoverage++;
            }
            if (nx > 0.42 &&
                ny > 0.91 - 0.20 * math.pow((nx - 0.42) / 0.58, 0.78)) {
              bottomInnerCoverage++;
            }
          }
        }
        final gradientPosition = (x + y) / (size * 2);
        if (topCoverage > 0) {
          _blend(x, y, _gradientColor(gradientPosition, 88), topCoverage / 4);
        }
        if (topInnerCoverage > 0) {
          _blend(
            x,
            y,
            _gradientColor(gradientPosition, 74),
            topInnerCoverage / 4,
          );
        }
        if (bottomCoverage > 0) {
          _blend(
            x,
            y,
            _gradientColor(gradientPosition, 76),
            bottomCoverage / 4,
          );
        }
        if (bottomInnerCoverage > 0) {
          _blend(
            x,
            y,
            _gradientColor(gradientPosition, 82),
            bottomInnerCoverage / 4,
          );
        }
      }
    }
  }

  bool _insideEllipse(
    double x,
    double y,
    double cx,
    double cy,
    double rx,
    double ry,
  ) {
    final dx = (x - cx) / rx;
    final dy = (y - cy) / ry;
    return dx * dx + dy * dy <= 1;
  }

  bool _insideController(double x, double y) {
    return _insideRoundedRect(x, y, 0.36, 0.425, 0.64, 0.575, 0.07) ||
        _insideEllipse(x, y, 0.37, 0.535, 0.105, 0.09) ||
        _insideEllipse(x, y, 0.63, 0.535, 0.105, 0.09);
  }

  void drawController() {
    const left = 0.26;
    const top = 0.42;
    const right = 0.74;
    const bottom = 0.64;
    for (var y = (top * size).floor(); y < (bottom * size).ceil(); y++) {
      for (var x = (left * size).floor(); x < (right * size).ceil(); x++) {
        var coverage = 0;
        for (final dy in const [0.25, 0.75]) {
          for (final dx in const [0.25, 0.75]) {
            if (_insideController((x + dx) / size, (y + dy) / size)) {
              coverage++;
            }
          }
        }
        if (coverage > 0) {
          _blend(
            x,
            y,
            _gradientColor((x / size - left) / (right - left), 255),
            coverage / 4,
          );
        }
      }
    }

    fillRoundedRect(
      size * 0.385,
      size * 0.482,
      size * 0.404,
      size * 0.565,
      size * 0.009,
      const _Color(6, 42, 28, 230),
    );
    fillRoundedRect(
      size * 0.367,
      size * 0.500,
      size * 0.422,
      size * 0.547,
      size * 0.009,
      const _Color(6, 42, 28, 230),
    );
    for (final button in const [
      (0.615, 0.495),
      (0.65, 0.53),
      (0.615, 0.565),
      (0.58, 0.53),
    ]) {
      _fillCircle(
        button.$1 * size,
        button.$2 * size,
        size * 0.012,
        const _Color(6, 42, 28, 230),
      );
    }
  }

  void _fillCircle(double cx, double cy, double radius, _Color color) {
    for (var y = (cy - radius).floor(); y <= (cy + radius).ceil(); y++) {
      for (var x = (cx - radius).floor(); x <= (cx + radius).ceil(); x++) {
        var coverage = 0;
        for (final dy in const [0.25, 0.75]) {
          for (final dx in const [0.25, 0.75]) {
            if (math.pow(x + dx - cx, 2) + math.pow(y + dy - cy, 2) <=
                radius * radius) {
              coverage++;
            }
          }
        }
        if (coverage > 0) _blend(x, y, color, coverage / 4);
      }
    }
  }

  void drawEmblem() {
    const left = 0.265;
    const top = 0.255;
    const right = 0.735;
    const bottom = 0.745;
    final l = size * left;
    final t = size * top;
    final r = size * right;
    final b = size * bottom;

    strokeRoundedRect(
      l - 10,
      t - 10,
      r + 10,
      b + 10,
      size * 0.105,
      4,
      const _Color(34, 197, 94, 24),
    );
    fillRoundedRect(l, t, r, b, size * 0.092, const _Color(10, 20, 15, 225));
    strokeRoundedRect(
      l,
      t,
      r,
      b,
      size * 0.092,
      2.4,
      const _Color(52, 211, 153, 215),
    );
    drawController();
  }

  Uint8List encodePng() {
    final raw = BytesBuilder(copy: false);
    for (var y = 0; y < size; y++) {
      raw.addByte(0);
      raw.add(pixels.sublist(y * size * 4, (y + 1) * size * 4));
    }

    final header = BytesBuilder(copy: false)
      ..add(_uint32(size))
      ..add(_uint32(size))
      ..add([8, 6, 0, 0, 0]);
    final png = BytesBuilder(copy: false)
      ..add([137, 80, 78, 71, 13, 10, 26, 10])
      ..add(_chunk('IHDR', header.takeBytes()))
      ..add(
        _chunk(
          'IDAT',
          Uint8List.fromList(ZLibEncoder().convert(raw.takeBytes())),
        ),
      )
      ..add(_chunk('IEND', Uint8List(0)));
    return png.takeBytes();
  }

  Uint8List _uint32(int value) {
    final bytes = ByteData(4)..setUint32(0, value);
    return bytes.buffer.asUint8List();
  }

  Uint8List _chunk(String type, Uint8List data) {
    final typeBytes = type.codeUnits;
    final crcInput = Uint8List(typeBytes.length + data.length)
      ..setRange(0, typeBytes.length, typeBytes)
      ..setRange(typeBytes.length, typeBytes.length + data.length, data);
    final chunk = BytesBuilder(copy: false)
      ..add(_uint32(data.length))
      ..add(typeBytes)
      ..add(data)
      ..add(_uint32(_crc32(crcInput)));
    return chunk.takeBytes();
  }

  int _crc32(Uint8List bytes) {
    var crc = 0xFFFFFFFF;
    for (final byte in bytes) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
      }
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}
