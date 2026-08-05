# Blink

macOS 눈 휴식 리마인더 (20-20-20). 메뉴바 앱, 전부 로컬.

## 개발
- 빌드: `swift build`
- 테스트: `swift test`
- 실행(개발): `swift run Blink` (빠른 주기: `BLINK_FAST=1 swift run Blink`)

## 설치(.app)
- `./packaging/make-app.sh` 실행 → `Blink.app` 생성
- `/Applications`로 이동 후 실행. 메뉴바 눈 아이콘에서 조작.
- 로그인 시 자동 실행은 설정창 토글(번들 .app에서만 동작).

## 구조
- `BlinkCore` — 순수 로직(상태머신·스케줄러·통계). `swift test` 대상
- `Blink` — macOS UI(MenuBarExtra·오버레이·알림·감지)
