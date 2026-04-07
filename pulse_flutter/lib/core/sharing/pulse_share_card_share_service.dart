import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pulse_flutter/core/models/pulse_share_card_data.dart';
import 'package:share_plus/share_plus.dart';

abstract class PulseShareCardShareService {
  Future<void> shareCard({
    required GlobalKey boundaryKey,
    required PulseShareCardData data,
    Rect? sharePositionOrigin,
  });
}

class NativePulseShareCardShareService implements PulseShareCardShareService {
  NativePulseShareCardShareService({SharePlus? sharePlus})
    : _sharePlus = sharePlus ?? SharePlus.instance;

  final SharePlus _sharePlus;

  @override
  Future<void> shareCard({
    required GlobalKey boundaryKey,
    required PulseShareCardData data,
    Rect? sharePositionOrigin,
  }) async {
    final Uint8List pngBytes = await captureCardPng(boundaryKey);

    await _sharePlus.share(
      ShareParams(
        title: data.title,
        subject: data.title,
        text: data.toShareText(),
        files: <XFile>[
          XFile.fromData(
            pngBytes,
            mimeType: 'image/png',
            name: 'pulse-share-card.png',
          ),
        ],
        fileNameOverrides: const <String>['pulse-share-card.png'],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  @visibleForTesting
  static Future<Uint8List> captureCardPng(
    GlobalKey boundaryKey, {
    double pixelRatio = 3,
  }) async {
    final BuildContext? boundaryContext = boundaryKey.currentContext;
    if (boundaryContext == null) {
      throw StateError('The Pulse share card is not ready to capture yet.');
    }

    final RenderObject? renderObject = boundaryContext.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('The Pulse share card capture boundary is unavailable.');
    }

    await WidgetsBinding.instance.endOfFrame;

    if (!renderObject.attached) {
      throw StateError('The Pulse share card is no longer available.');
    }

    final ui.Image image = await renderObject.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();

    if (byteData == null) {
      throw StateError('Unable to encode the Pulse share card image.');
    }

    return byteData.buffer.asUint8List();
  }
}
