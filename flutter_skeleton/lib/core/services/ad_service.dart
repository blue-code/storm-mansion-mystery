import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// TODO: 실제 출시 전 AdMob 콘솔에서 발급받은 ID로 교체
const _kTestRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';

// 실제 광고 단위 ID (출시 시 사용)
// const _kProdRewardedAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  String get _adUnitId {
    if (kDebugMode) return _kTestRewardedAdUnitId;
    return Platform.isIOS
        ? _kTestRewardedAdUnitId // TODO: 실제 iOS 광고 단위 ID
        : _kTestRewardedAdUnitId; // TODO: 실제 Android 광고 단위 ID
  }

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadAd();
  }

  void _loadAd() {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
        },
      ),
    );
  }

  bool get isReady => _rewardedAd != null;

  /// 광고 시청 → [onRewarded] 호출. 광고 없으면 [onRewarded] 바로 호출(개발 편의용).
  Future<void> showRewardedAd({required VoidCallback onRewarded}) async {
    if (_rewardedAd == null) {
      if (kDebugMode) {
        // 광고 미로드 상태에서도 디버그 편의상 보상 지급
        onRewarded();
      }
      _loadAd();
      return;
    }

    await _rewardedAd!.show(
      onUserEarnedReward: (_, __) => onRewarded(),
    );
  }
}
