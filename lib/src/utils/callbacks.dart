import 'dart:async';

import 'package:flutter/material.dart';

typedef UpdateCallback = void Function(
  BuildContext context,
  String storeUrl,
);

typedef ForcedUpdateCallback = Future<bool?> Function(
  BuildContext context,
  String storeUrl,
);

typedef ErrorUpdateCallback = void Function(
  Object error,
  StackTrace? stackTrace,
);

typedef FetchMinVersionCallback = FutureOr<String?> Function();

typedef FetchMinForcedVersionCallback = FutureOr<String?> Function();
