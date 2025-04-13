// ignore_for_file: avoid_print

import 'package:app_links/app_links.dart';

final AppLinks _appLinks = AppLinks();

Future<String?> initDeepLinkHandling() async {
  // Initial link (cold start)
  final Uri? initialLink = await _appLinks.getInitialAppLink();
  if (initialLink != null) {
    print('Initial deep link: ${initialLink.toString()}');
    return initialLink.toString();
  }
  return null;
}