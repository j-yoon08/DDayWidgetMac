# DDayWidgetMac

macOS 캘린더의 이번 달 일정을 선택해 D-Day 위젯으로 표시하는 네이티브 macOS 앱입니다.

앱에서 표시할 일정을 고르면 선택 결과를 App Group 컨테이너의 JSON 파일로 공유하고, WidgetKit 확장이 이를 읽어 Small·Medium·Large 위젯에 반영합니다.

## 주요 기능

- EventKit을 이용한 이번 달 캘린더 일정 조회
- 앱에서 위젯에 표시할 일정 선택 및 해제
- 일정 날짜에 따른 `D-DAY`, `D-n`, `D+n` 계산
- Small, Medium, Large 위젯 레이아웃
- 임박한 일정 강조: 3일 이내 빨간색, 7일 이내 주황색
- App Group과 `selected_events.json`을 이용한 앱·위젯 데이터 공유
- 일정 선택 변경 시 위젯 타임라인 새로고침

## 동작 구조

1. `CalendarStore`가 캘린더 접근 권한을 요청하고 이번 달 일정을 불러옵니다.
2. 사용자가 `DDayView`에서 위젯에 표시할 일정을 선택합니다.
3. 선택된 일정이 App Group 컨테이너의 `selected_events.json`에 저장됩니다.
4. WidgetKit의 `Provider`가 공유 JSON을 읽어 위젯 엔트리를 생성합니다.
5. 위젯은 크기에 따라 대표 일정과 추가 일정을 다르게 배치합니다.

## 기술 스택

- Swift
- SwiftUI
- WidgetKit
- EventKit
- AppKit
- App Groups

## 프로젝트 구조

```text
DDayWidgeMac/
├── DDayWidgeMac.xcodeproj/
├── DDayWidgeMac/
│   ├── CalendarStore.swift
│   ├── DDayView.swift
│   └── DDayWidgeMacApp.swift
├── DDayWidgetMacWidget/
│   ├── DDayWidgetMacWidget.swift
│   ├── DDayWidgetMacWidgetBundle.swift
│   └── Info.plist
└── DDayWidgetMacWidgetExtension.entitlements
```

## 실행 방법

```bash
git clone https://github.com/j-yoon08/DDayWidgetMac.git
cd DDayWidgetMac
open DDayWidgeMac/DDayWidgeMac.xcodeproj
```

Xcode에서 다음 설정을 확인한 뒤 앱 타깃을 실행합니다.

1. 앱과 위젯 확장 타깃의 Development Team을 자신의 Apple Developer 계정으로 설정합니다.
2. 두 타깃에 동일한 App Group capability를 연결합니다.
3. App Group 식별자를 변경한다면 아래 네 파일의 `group.markwise.DDayWidgeMac` 값도 동일하게 변경합니다.
   - `DDayWidgeMac/DDayWidgeMac/CalendarStore.swift`
   - `DDayWidgeMac/DDayWidgetMacWidget/DDayWidgetMacWidget.swift`
   - `DDayWidgeMac/DDayWidgeMac/DDayWidgeMac.entitlements`
   - `DDayWidgeMac/DDayWidgetMacWidgetExtension.entitlements`
4. 앱 최초 실행 시 캘린더 접근을 허용합니다.
5. macOS 위젯 갤러리에서 DDayWidgetMac 위젯을 추가합니다.

## 빌드 환경

현재 Xcode 프로젝트 설정은 다음과 같습니다.

- Swift 5
- macOS deployment target 26.2
- Xcode tools version 26.2에서 생성된 프로젝트 형식

이보다 낮은 macOS 또는 Xcode에서 사용하려면 deployment target과 프로젝트 설정을 조정해야 합니다.

## 데이터 처리

캘린더 일정은 기기에서 읽으며, 사용자가 선택한 일정의 식별자·제목·날짜·선택 상태만 App Group 컨테이너의 로컬 JSON 파일에 저장합니다. 현재 구현에는 외부 서버로 일정을 전송하는 코드가 없습니다.
