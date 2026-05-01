#!/usr/bin/env bash
# 앱스토어 제출용 스크린샷 자동 캡처 스크립트
#
# 동작:
#  1) SCREENSHOT_MODE=true 로 디버그 빌드 → 시뮬레이터에 설치
#  2) 앱을 한 번 실행. 앱 내부 _ScreenshotRouter 가 N초마다 다음 씬으로 자동 전환
#  3) bash 는 같은 주기로 simctl screenshot 만 호출
#  4) 결과물은 ../marketing/screenshots/ios_69/ 에 PNG 로 저장
#
# 사전 조건: iPhone 17 Pro Max 시뮬레이터(또는 6.9" 동급)가 부팅된 상태

set -euo pipefail

BUNDLE_ID="com.digimaru.stormMansionMystery"
OUT_DIR="$(cd "$(dirname "$0")/../.." && pwd)/marketing/screenshots/ios_69"
APP_PATH="build/ios/iphonesimulator/Runner.app"
# main.dart 의 kScreenshotSecondsPerScene 와 일치해야 한다
SECS_PER_SHOT=4
# Lazy build: 첫 씬 렌더 전에 잠깐 더 기다린다
INITIAL_WAIT=3
# simctl 은 외부 볼륨에 직접 못 쓰므로 임시 캐시 경로 사용
TMP_DIR="${HOME}/Library/Caches/storm-mansion-screenshots"

SHOT_FILES=(
  "01_title.png"
  "02_intro_storm.png"
  "03_office_choice.png"
  "04_murder_discovery.png"
  "05_danger_shake.png"
  "06_accusation.png"
  "07_investigation_sheet.png"
  "08_true_ending.png"
)

# 우선 부팅된 6.9" iPhone 을 찾고, 없으면 그냥 부팅된 첫 iPhone
DEVICE_UDID=$(xcrun simctl list devices | grep "iPhone 17 Pro Max" | grep "Booted" | grep -oE "[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}" | head -1)
if [[ -z "${DEVICE_UDID}" ]]; then
  DEVICE_UDID=$(xcrun simctl list devices | grep "iPhone 16 Pro Max" | grep "Booted" | grep -oE "[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}" | head -1)
fi
if [[ -z "${DEVICE_UDID}" ]]; then
  DEVICE_UDID=$(xcrun simctl list devices | grep "iPhone" | grep "Booted" | grep -oE "[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}" | head -1)
fi
if [[ -z "${DEVICE_UDID}" ]]; then
  echo "Error: 부팅된 iPhone 시뮬레이터를 찾을 수 없습니다." >&2
  exit 1
fi
echo "▶ 시뮬레이터 UDID: ${DEVICE_UDID}"

mkdir -p "${OUT_DIR}" "${TMP_DIR}"

# 1) 빌드
echo "▶ Flutter 디버그 빌드 (SCREENSHOT_MODE=true) ..."
flutter build ios --debug --simulator --dart-define=SCREENSHOT_MODE=true >/dev/null

if [[ ! -d "${APP_PATH}" ]]; then
  echo "Error: 빌드 결과물이 없습니다: ${APP_PATH}" >&2
  exit 1
fi

# 2) 설치
echo "▶ 시뮬레이터에 설치"
xcrun simctl install "${DEVICE_UDID}" "${APP_PATH}"

# 3) 기존 인스턴스 종료 후 launch
xcrun simctl terminate "${DEVICE_UDID}" "${BUNDLE_ID}" >/dev/null 2>&1 || true
sleep 0.5

echo "▶ 앱 실행"
xcrun simctl launch "${DEVICE_UDID}" "${BUNDLE_ID}" >/dev/null
sleep "${INITIAL_WAIT}"

# 4) N초 간격으로 캡처
for i in "${!SHOT_FILES[@]}"; do
  OUT_FILE="${SHOT_FILES[$i]}"
  echo "▶ [${OUT_FILE}]"

  # 첫 캡처는 INITIAL_WAIT 후 바로, 이후는 SECS_PER_SHOT 간격
  if [[ $i -gt 0 ]]; then
    sleep "${SECS_PER_SHOT}"
  fi

  xcrun simctl io "${DEVICE_UDID}" screenshot "${TMP_DIR}/${OUT_FILE}" >/dev/null 2>&1
  cp "${TMP_DIR}/${OUT_FILE}" "${OUT_DIR}/${OUT_FILE}"
  echo "  ✓ ${OUT_DIR}/${OUT_FILE}"
done

xcrun simctl terminate "${DEVICE_UDID}" "${BUNDLE_ID}" >/dev/null 2>&1 || true

echo ""
echo "✅ 완료. 결과물:"
ls -lh "${OUT_DIR}"
