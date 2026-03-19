---
프로젝트명: storm-mansion-mystery
작업일시: 2026-03-19 09:19
작성자: Kent
세션목적: Chapter 1 시나리오 JSON 데이터 설계
---

# 구체화: 스토리라인 JSON 초안 설계 (Chapter 1)

Flutter 앱의 데이터 소스로 직접 활용 가능한 `assets/story/chapter1.json` 기준의 데이터 초안입니다. 분기 1단계(사건 발생 직후의 대응)가 모두 수록되었습니다.

## 1. JSON 기반 State-Action 로직의 작동 원리
본 JSON 노드는 플러터단 `GameStateNotifier.makeChoice(effects)`의 완벽한 맵핑 테이블이 됩니다.

1. **id (현재 장소/상황 구분자)**: 플레이어가 마주하게 될 장면 화면
2. **speaker (화자)**: 'system'일 경우 내레이션, 이름일 경우 스탠딩 레이어와 함께 표시
3. **choices (선택지 리스트)**: 유저가 탭할 버튼들
   * `effects.add_evidence`: 이것을 획득하면 나중에 범인 지목 시 결정적 트리거 락킹 해제
   * `effects.danger_delta`: 위험도를 즉시 올려, 추후 사망 엔딩 발동에 기여
   * `effects.trust_delta`: 타겟 캐릭터의 호감도/경계심을 관리.

## 2. 생성된 폴더 내 구조
* 앱 개발에 바로 적용할 수 있도록, 뼈대 코드 폴더 내에 실제 구조를 모방하여 생성해 두었습니다.
* 파일 경로: `~\flutter_skeleton\assets\story\chapter1.json`

이제는 이 JSON을 Dart의 직렬화 패키지(`json_serializable` 등)로 객체화해서 Riverpod provider에 넘기면, **코드를 건드리지 않아도 JSON 수정만으로 게임 시나리오가 끝없이 확장됩니다.** (완전한 기획자 주도형 개발 파이프라인 완성)
