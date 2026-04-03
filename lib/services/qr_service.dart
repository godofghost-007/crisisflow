import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class QRService {
  String generateZoneQRData(String zoneId, String zoneName, String floor) {
    // Encoding attributes to ensure safe URL parsing
    final safeName = Uri.encodeComponent(zoneName);
    final safeFloor = Uri.encodeComponent(floor);
    return 'https://crisisflow.app/report?zone=$zoneId&name=$safeName&floor=$safeFloor';
  }

  Future<Uint8List?> captureQRAsImage(GlobalKey repaintKey) async {
    try {
      RenderRepaintBoundary boundary =
          repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      // Return null if boundary is not painted yet
      return null;
    }
  }

  // For web we use csv or standard web downloads, this abstracts the UI part.
  // In an actual web app, you would use `dart:html` AnchorElement to download.
  // We'll define a placeholder here that UI can hook onto.
}
