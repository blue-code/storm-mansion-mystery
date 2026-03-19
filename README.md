# 🕵️ 폭풍 저택의 유언 (Testament of the Stormy Mansion)

> 고립된 산장, 한정된 시간, 조여오는 생명의 위협 속에서 진범을 찾아라!
> TDD(Test-Driven Development) 기반으로 설계된 Flutter 텍스트 추리 어드벤처 게임입니다.

---

## 📖 작품 소개
'폭풍 저택의 유언'은 Riverpod의 `GameState`를 활용하여 복잡한 분기와 선택에 따른 나비효과를 처리하는 텍스트 어드벤처입니다. 
당신은 폭풍으로 전화가 끊기고 다리가 무너진 고립된 저택 안에서 탐정이 되어, **한정된 시간(Time Cost)** 안에 제한된 증거를 모아 살인마의 정체를 밝혀내야 합니다. 누적되는 **위험도(Danger Level)**를 관리하며 죽음의 엔딩을 피해 진실에 도달하세요!

---

## 🛠️ 기술 스택 및 주요 라이브러리 (Tech Stack)
* **프레임워크:** Flutter / Dart
* **상태 관리:** Riverpod (`flutter_riverpod`)
* **데이터 직렬화:** Freezed (`freezed_annotation`)
* **연출 라이브러리:** 
  * `animated_text_kit` (타이프라이터 연출)
  * `audioplayers` (동적 BGM & SFX 제어)
  * `flutter_animate` (위험 이벤트 시 화면 흔들림 효과)
* **로컬 스토리지:** `shared_preferences` (JSON 데이터 직렬화 기반 자동 저장)

---

## 🧩 핵심 아키텍처 (Key Architecture)

본 프로젝트는 **'허브 앤 스포크(Hub-and-Spoke)' 모델**과 **'JSON 스크립팅 엔진'**을 채택하고 있습니다. 

### 1. 상태 병합 및 라우팅 (Riverpod + GameState)
* 모든 스토리 진행, 증거물 습득, 신뢰도 변화, 씬 이동은 `GameStateNotifier`를 거쳐 일방향으로 통제됩니다.
* `GameState`의 불변 객체를 활용해 부작용(Side Effect)을 최소화했습니다.
* 매 선택마다 `_saveState()`를 호출하여 `SharedPreferences`에 현재 상태를 보존하고, 디바이스의 메모리 부족 시에도 '이어하기'가 가능합니다.

### 2. JSON 기반 모듈화 스토리 시스템
* 코드를 수정하지 않고도 `assets/story/` 폴더 내 JSON 시나리오 파일만 추가/수정하여 게임의 볼륨을 확장할 수 있습니다.
* 각 노드는 다음을 포함합니다.
  * **조건:** `next_scene_id`
  * **연출:** `bgm`, `sfx`, `background_image`
  * **파라미터 증분:** `time_cost`, `danger_delta`, `trust_delta`, `add_evidence`

---

## 💡 주요 시스템 가이드

### ⏱️ 시간 제한 (Time Cost)
특정 장소를 탐색하거나 깊숙한 대화를 나누면 시간이 소모됩니다.
주어진 시간이 모두 소진되면 강제로 메인 사건 단위(오후 이벤트, 저녁 이벤트 등)로 강제 이동합니다. 짧은 시간 안에 핵심 단서를 취사선택하는 전략이 필요합니다.

### ⚠️ 위험도 (Danger Level) & 카메라 흔들림
함정(Trap)을 밟거나 진범에게 너무 공격적인 태도를 보이면 위험도가 누적(`danger_delta > 0`)됩니다.
위험도가 오르면 화면에 **`Camera Shake` 연출**이 발동하며, 위험도가 **3에 도달할 경우 즉시 사망 엔딩(Bad Ending)**을 맞이합니다.

### 💾 자동 저장 및 불러오기 (Save / Load)
메인 화면에서 두 가지 행동을 지시합니다.
1. **새 사건 조사**: 기존의 기억(`SharedPreferences`)을 말소하고 처음부터 재시작합니다.
2. **기록 열람(이어하기)**: 플레이어가 마지막으로 읽은 텍스트 줄과 상태값부터 재개합니다.

---

## 💻 실행 방법 (Getting Started)

1. Flutter SDK가 설치된 환경을 준비합니다.
2. `flutter_skeleton` 폴더로 이동합니다.
```bash
cd flutter_skeleton
```
3. 의존성을 설치합니다.
```bash
flutter pub get
```
4. 코드를 생성합니다. (Freezed 등)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
5. 브라우저, 윈도우 데스크탑 또는 시뮬레이터로 실행합니다.
```bash
flutter run -d chrome
```

---

## 📝 커밋 컨벤션 (Commit Convention)
본 프로젝트는 다음의 접두어를 사용한 한글 커밋 메시지를 권장합니다.
* `feat :` 새로운 기능 추가
* `fix :` 버그 수정
* `refactor :` 코드 리팩토링
* `docs :` README.md, 주석 등 문서 수정

> *작성자: Kent (Senior Developer)*
