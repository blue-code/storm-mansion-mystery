# App Store 제출 체크리스트 — 폭풍 저택의 유언

## 1. 빌드 준비

### 1-1. AdMob App ID 교체 (필수 — 출시 전 반드시)
```
파일: ios/Runner/Info.plist
키: GADApplicationIdentifier
현재값: ca-app-pub-3940256099942544~1458002511  ← 구글 테스트 ID
→ AdMob 콘솔 > 앱 > 앱 ID 로 교체
```

```
파일: lib/core/services/ad_service.dart
상수: _kProdRewardedAdUnitId
현재값: 테스트 ID
→ AdMob 콘솔 > 광고 단위 > 보상형 광고 ID 로 교체
그리고 _adUnitId getter 에서 kDebugMode 분기를 프로드 ID 로 전환
```

### 1-2. 버전 번호 확인
```yaml
# pubspec.yaml
version: 1.0.0+1   # 형식: 버전이름+빌드번호
                   # App Store Connect 에 동일하게 입력
```

### 1-3. Release 빌드
```bash
flutter build ipa \
  --release \
  --export-method app-store-connect \
  --export-options-plist ios/ExportOptions.plist
```

`ios/ExportOptions.plist` 예시:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC ...>
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>YOUR_TEAM_ID</string>
  <key>uploadBitcode</key><false/>
  <key>uploadSymbols</key><true/>
</dict></plist>
```

또는 Xcode Organizer 에서 Archive → Distribute App 으로 업로드.

---

## 2. App Store Connect 앱 메타데이터 입력

### 앱 정보 탭
| 항목 | 입력값 |
|------|--------|
| 앱 이름 | 폭풍 저택의 유언 |
| 부제목 | 1920년대 저택 살인 추리 미스터리 |
| 카테고리 | 게임 > 어드벤처 |
| 보조 카테고리 | 게임 > 롤플레잉 |
| 개인정보 처리방침 URL | https://github.com/blue-code/legal/blob/main/privacy_policy_storm_mansion.md |

### 버전 정보 탭
| 항목 | 입력값 |
|------|--------|
| 홍보 문구 | (marketing/aso_metadata.md 참조) |
| 설명 | (marketing/aso_metadata.md 참조) |
| 키워드 | 추리,미스터리,탐정,살인,저택,공포,어드벤처,비주얼노벨,스릴러,범인,수사,단서,게임,murder,mystery |
| 지원 URL | https://github.com/blue-code/legal |
| 마케팅 URL | (선택 사항) |

---

## 3. 스크린샷 업로드

경로: `marketing/screenshots/ios_69/`

| 파일 | 용도 |
|------|------|
| 01_title.png | 타이틀 화면 |
| 02_intro_storm.png | 오프닝 씬 |
| 03_office_choice.png | 선택지 화면 |
| 04_murder_discovery.png | 증거 수집 |
| 05_danger_shake.png | 위험도 시스템 |
| 06_accusation.png | 기소 씬 |
| 07_investigation_sheet.png | 단서장 UI |
| 08_true_ending.png | 진실 엔딩 |

> App Store Connect > 앱 버전 > iPhone 스크린샷 > 6.9" Display 에 업로드
> 6.9" 필수, 6.5" 및 5.5"는 선택 (없으면 자동 축소 적용)

---

## 4. 앱 심사 정보

### 로그인 정보 (데모 계정)
본 앱은 로그인 없이 바로 플레이 가능.
심사자 메모 입력란:
```
이 앱은 계정 생성이나 로그인 없이 즉시 플레이 가능합니다.
광고는 힌트 버튼 탭 또는 사망 후 이어하기 선택 시에만 자선택적으로 노출됩니다.
```

### 연령 등급 설문
`marketing/aso_metadata.md` 의 연령 등급 섹션 참조 → **예상 결과: 12+**

### 앱 내 구매
없음 (광고 기반 무료)

### 개인정보 처리 관행 (Data Privacy)
| 데이터 유형 | 수집 여부 | 추적 사용 | 목적 |
|------------|-----------|----------|------|
| 식별자 (광고 ID) | 예 (AdMob) | 예 | 광고 |
| 사용 데이터 | 예 (AdMob) | 예 | 광고 |
| 위치 | 아니오 | - | - |
| 연락처 | 아니오 | - | - |
| 사용자 콘텐츠 | 아니오 | - | - |
| 검색 기록 | 아니오 | - | - |

---

## 5. 최종 제출 전 체크

- [ ] AdMob App ID 를 실제 ID 로 교체
- [ ] Rewarded Ad Unit ID 를 실제 ID 로 교체  
- [ ] `kDebugMode` 분기에서 프로드 광고 ID 활성화
- [ ] `pubspec.yaml` 버전 번호 확인 (1.0.0+1)
- [ ] App Store Connect 에 번들 ID 등록 (`com.digimaru.stormMansionMystery`)
- [ ] 개인정보처리방침 GitHub 에 업로드 완료
- [ ] 스크린샷 8장 6.9" 슬롯에 업로드
- [ ] 메타데이터(이름/부제/키워드/설명/홍보문구) 입력
- [ ] 연령 등급 설문 완료
- [ ] Data Privacy 섹션 입력
- [ ] TestFlight 베타 테스트 완료 (이미 완료)
- [ ] 심사 제출

---

## 6. 개인정보처리방침 GitHub 업로드 방법

```bash
# github.com/blue-code/legal 리포지토리에 아래 파일 추가
cp marketing/privacy_policy_storm_mansion.md /path/to/blue-code-legal-repo/
cd /path/to/blue-code-legal-repo/
git add privacy_policy_storm_mansion.md
git commit -m "Add privacy policy for Storm Mansion Mystery"
git push
```

업로드 후 URL 확인:
```
https://github.com/blue-code/legal/blob/main/privacy_policy_storm_mansion.md
```
이 URL 을 App Store Connect 개인정보 처리방침 URL 칸에 입력.
