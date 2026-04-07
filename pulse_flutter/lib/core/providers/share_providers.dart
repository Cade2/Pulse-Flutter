import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/sharing/pulse_share_card_share_service.dart';

final pulseShareCardShareServiceProvider = Provider<PulseShareCardShareService>(
  (ref) {
    return NativePulseShareCardShareService();
  },
);
