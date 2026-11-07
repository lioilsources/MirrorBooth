/// Store links the app hands out, with campaign tags so App Analytics and the
/// Play Console can tell shared-post installs apart from everything else.
///
/// Fill in [providerToken] and [sharedPhotoPageId] from App Store Connect
/// (App Analytics → Campaigns → Generate a campaign link; App Store → Custom
/// Product Pages → the "Shared photo" page). Empty values are left out of the
/// link, which still works, just without that attribution.
class StoreLinks {
  static const appStoreId = '6767824892';
  static const playPackage = 'com.ab.mirrorbooth';

  /// App Analytics provider token (`pt=`). TODO(ol1n): fill in.
  static const providerToken = '';

  /// Custom Product Page ID for the "Shared photo" page (`ppid=`).
  /// TODO(ol1n): fill in once the page is approved.
  static const sharedPhotoPageId = '';

  /// Short address burned into shared photos and videos; it should redirect
  /// to the store page (App Store or Play by user agent).
  static const shortUrl = 'olin.now/mirror';

  /// App Store link for a shared post, tagged with campaign [campaign].
  static Uri appStore({String campaign = 'share'}) => Uri.https(
        'apps.apple.com',
        '/app/id$appStoreId',
        {
          if (sharedPhotoPageId.isNotEmpty) 'ppid': sharedPhotoPageId,
          'ct': campaign,
          if (providerToken.isNotEmpty) 'pt': providerToken,
        },
      );

  /// Play link for a shared post; the install referrer carries the campaign.
  static Uri play({String campaign = 'share'}) => Uri.https(
        'play.google.com',
        '/store/apps/details',
        {
          'id': playPackage,
          'referrer': 'utm_source=$campaign&utm_medium=app_share',
        },
      );
}
