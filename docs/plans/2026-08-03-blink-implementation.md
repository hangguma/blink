# Blink Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** macOS 눈 휴식 리마인더 메뉴바 앱(Blink)을 만든다 — 2단계 브레이크, 오버레이/알림 개입, 스마트 일시정지, 오늘 요약 통계. 전부 로컬.

**Architecture:** UI 없는 순수 Swift 로직(`BlinkCore`: 상태머신·스케줄러·통계 저장, 클럭 주입으로 테스트 가능)과 macOS UI 레이어(`Blink` 실행 타깃: MenuBarExtra·NSPanel 오버레이·알림·유휴/전체화면 감지)를 분리. UI는 BlinkCore를 단방향 의존.

**Tech Stack:** Swift 5.9+, SwiftPM(2 타깃 + 테스트), SwiftUI + 최소 AppKit, `UserNotifications`, `ServiceManagement`, `CoreGraphics`. 외부 라이브러리 없음. XCTest.

## Global Constraints

- 플랫폼: macOS 14 (Sonoma)+ (`platforms: [.macOS(.v14)]`)
- 언어/툴: Swift 5.9+, `swift-tools-version:5.9`
- 외부 의존성 0개 — 표준 프레임워크만
- 데이터: 전부 로컬. 설정 → `UserDefaults`, 통계 → `~/Library/Application Support/Blink/stats.json`. 클라우드·계정 없음
- `BlinkCore` 타깃은 순수 로직만 — AppKit/SwiftUI import 금지 (Windows 이식성 + 테스트 격리). macOS 전용 API(CGEventSource, NSWorkspace 등)는 `Blink` 실행 타깃에만
- 소리/사운드 없음 (비범위)
- 커밋: 각 태스크 끝에서 `git commit`. 커밋 메시지 끝에 `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`

---

## File Structure

```
blink/
├── Package.swift
├── Sources/
│   ├── BlinkCore/                 # 순수 로직 (테스트 대상)
│   │   ├── Models.swift           # BreakKind, BreakMode, BreakConfig, EngineState, DayStats
│   │   ├── Clock.swift            # Clock 프로토콜, SystemClock, TestClock
│   │   ├── Scheduler.swift        # 2단계 주기 카운트다운 + precedence
│   │   ├── BreakEngine.swift      # 상태머신 + skip/postpone/pause
│   │   ├── StatsStore.swift       # 오늘 요약 JSON 영속 + 날짜 리셋
│   │   └── ConfigStore.swift      # UserDefaults ↔ BreakConfig
│   └── Blink/                     # macOS UI 실행 타깃
│       ├── BlinkApp.swift         # @main, MenuBarExtra + Settings scene
│       ├── AppDelegate.swift      # accessory 정책, AppController 소유
│       ├── AppController.swift    # 엔진 + 1초 타이머 + 감지기 배선
│       ├── MenuContent.swift      # 메뉴바 팝업 뷰
│       ├── OverlayController.swift# NSPanel 오버레이 (모니터별)
│       ├── OverlayView.swift      # 오버레이 SwiftUI 콘텐츠
│       ├── Notifier.swift         # UNUserNotification 개입 + 액션
│       ├── IdleDetector.swift     # CGEventSource 유휴 초
│       ├── FullscreenDetector.swift# 전체화면 앱 감지 (heuristic)
│       ├── SettingsView.swift     # 설정 SwiftUI
│       └── LaunchAtLogin.swift    # SMAppService 토글
├── Tests/
│   └── BlinkCoreTests/
│       ├── ClockTests.swift
│       ├── SchedulerTests.swift
│       ├── BreakEngineTests.swift
│       ├── StatsStoreTests.swift
│       └── ConfigStoreTests.swift
└── packaging/                     # Task 13
    ├── Info.plist
    └── make-app.sh
```

---

### Task 1: SwiftPM 프로젝트 스캐폴드

**Files:**
- Create: `Package.swift`
- Create: `Sources/BlinkCore/Placeholder.swift`
- Create: `Sources/Blink/main-placeholder.swift`
- Test: `Tests/BlinkCoreTests/ClockTests.swift` (임시 sanity 테스트, Task 2에서 대체)

**Interfaces:**
- Consumes: 없음
- Produces: `BlinkCore` 라이브러리 타깃, `Blink` 실행 타깃, `BlinkCoreTests` 테스트 타깃

- [ ] **Step 1: `Package.swift` 작성**

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Blink",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "BlinkCore"),
        .executableTarget(
            name: "Blink",
            dependencies: ["BlinkCore"]
        ),
        .testTarget(
            name: "BlinkCoreTests",
            dependencies: ["BlinkCore"]
        ),
    ]
)
```

- [ ] **Step 2: 최소 소스 스텁 작성**

`Sources/BlinkCore/Placeholder.swift`:
```swift
enum BlinkCorePlaceholder {}
```

`Sources/Blink/main-placeholder.swift`:
```swift
// Task 7에서 BlinkApp(@main)으로 대체된다.
print("Blink placeholder")
```

- [ ] **Step 3: 임시 sanity 테스트 작성**

`Tests/BlinkCoreTests/ClockTests.swift`:
```swift
import XCTest
@testable import BlinkCore

final class ClockTests: XCTestCase {
    func test_scaffold_builds() {
        XCTAssertTrue(true)
    }
}
```

- [ ] **Step 4: 빌드/테스트 확인**

Run: `cd ~/Project/blink && swift build`
Expected: `Build complete!`

Run: `swift test`
Expected: `Executed 1 test` 통과

- [ ] **Step 5: 커밋**

```bash
cd ~/Project/blink && git add -A && git commit -m "feat: SwiftPM 스캐폴드 (BlinkCore + Blink + tests)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 2: 핵심 모델 + Clock

**Files:**
- Create: `Sources/BlinkCore/Models.swift`
- Create: `Sources/BlinkCore/Clock.swift`
- Modify: `Tests/BlinkCoreTests/ClockTests.swift` (스텁 대체)
- Delete: `Sources/BlinkCore/Placeholder.swift`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `enum BreakKind { case short, long }`
  - `enum BreakMode { case overlay, notification }`
  - `enum EngineState: Equatable { case working; case preBreak(BreakKind); case onBreak(BreakKind); case paused }`
  - `struct BreakConfig` (아래 필드/기본값)
  - `struct DayStats: Codable, Equatable { var date: String; var breaksCompleted: Int; var breaksSkipped: Int }`
  - `protocol Clock: AnyObject { var now: Date { get } }`, `final class SystemClock`, `final class TestClock { func advance(by:) }`

- [ ] **Step 1: 실패하는 테스트 작성**

`Tests/BlinkCoreTests/ClockTests.swift` (전체 교체):
```swift
import XCTest
@testable import BlinkCore

final class ClockTests: XCTestCase {
    func test_testClock_advances() {
        let clock = TestClock(Date(timeIntervalSince1970: 0))
        XCTAssertEqual(clock.now.timeIntervalSince1970, 0)
        clock.advance(by: 90)
        XCTAssertEqual(clock.now.timeIntervalSince1970, 90)
    }

    func test_defaultConfig_values() {
        let c = BreakConfig()
        XCTAssertEqual(c.shortInterval, 20 * 60)
        XCTAssertEqual(c.shortDuration, 20)
        XCTAssertEqual(c.longInterval, 60 * 60)
        XCTAssertEqual(c.longDuration, 5 * 60)
        XCTAssertEqual(c.preBreakWarning, 10)
        XCTAssertEqual(c.idleThreshold, 2 * 60)
        XCTAssertEqual(c.postponeInterval, 5 * 60)
        XCTAssertEqual(c.shortMode, .notification)
        XCTAssertEqual(c.longMode, .overlay)
    }
}
```

- [ ] **Step 2: 실패 확인**

Run: `swift test --filter ClockTests`
Expected: FAIL — `TestClock` / `BreakConfig` 미정의로 컴파일 에러

- [ ] **Step 3: 모델 구현**

`Sources/BlinkCore/Models.swift`:
```swift
import Foundation

public enum BreakKind: Equatable, Sendable {
    case short
    case long
}

public enum BreakMode: String, Equatable, Sendable, Codable {
    case overlay
    case notification
}

public enum EngineState: Equatable, Sendable {
    case working
    case preBreak(BreakKind)
    case onBreak(BreakKind)
    case paused
}

public struct BreakConfig: Equatable, Sendable {
    public var shortInterval: TimeInterval
    public var shortDuration: TimeInterval
    public var longInterval: TimeInterval
    public var longDuration: TimeInterval
    public var preBreakWarning: TimeInterval
    public var idleThreshold: TimeInterval
    public var postponeInterval: TimeInterval
    public var shortMode: BreakMode
    public var longMode: BreakMode

    public init(
        shortInterval: TimeInterval = 20 * 60,
        shortDuration: TimeInterval = 20,
        longInterval: TimeInterval = 60 * 60,
        longDuration: TimeInterval = 5 * 60,
        preBreakWarning: TimeInterval = 10,
        idleThreshold: TimeInterval = 2 * 60,
        postponeInterval: TimeInterval = 5 * 60,
        shortMode: BreakMode = .notification,
        longMode: BreakMode = .overlay
    ) {
        self.shortInterval = shortInterval
        self.shortDuration = shortDuration
        self.longInterval = longInterval
        self.longDuration = longDuration
        self.preBreakWarning = preBreakWarning
        self.idleThreshold = idleThreshold
        self.postponeInterval = postponeInterval
        self.shortMode = shortMode
        self.longMode = longMode
    }

    public func duration(for kind: BreakKind) -> TimeInterval {
        kind == .short ? shortDuration : longDuration
    }

    public func mode(for kind: BreakKind) -> BreakMode {
        kind == .short ? shortMode : longMode
    }
}

public struct DayStats: Codable, Equatable, Sendable {
    public var date: String
    public var breaksCompleted: Int
    public var breaksSkipped: Int

    public init(date: String = "", breaksCompleted: Int = 0, breaksSkipped: Int = 0) {
        self.date = date
        self.breaksCompleted = breaksCompleted
        self.breaksSkipped = breaksSkipped
    }
}
```

`Sources/BlinkCore/Clock.swift`:
```swift
import Foundation

public protocol Clock: AnyObject {
    var now: Date { get }
}

public final class SystemClock: Clock {
    public init() {}
    public var now: Date { Date() }
}

public final class TestClock: Clock {
    public private(set) var now: Date
    public init(_ start: Date = Date(timeIntervalSince1970: 0)) {
        self.now = start
    }
    public func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
    }
}
```

- [ ] **Step 4: 스텁 삭제 후 통과 확인**

Run: `rm Sources/BlinkCore/Placeholder.swift && swift test --filter ClockTests`
Expected: PASS (2 tests)

- [ ] **Step 5: 커밋**

```bash
git add -A && git commit -m "feat: 핵심 모델(BreakConfig/EngineState/DayStats) + Clock 추상화

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 3: Scheduler (2단계 주기 + precedence)

**Files:**
- Create: `Sources/BlinkCore/Scheduler.swift`
- Test: `Tests/BlinkCoreTests/SchedulerTests.swift`

**Interfaces:**
- Consumes: `BreakConfig`, `BreakKind`
- Produces: `final class Scheduler`
  - `init(config: BreakConfig, now: Date)`
  - `func dueBreak(at now: Date) -> BreakKind?` (long 우선)
  - `func timeUntilNextBreak(at now: Date) -> TimeInterval`
  - `func reschedule(_ kind: BreakKind, from now: Date)`
  - `func postpone(_ kind: BreakKind, until date: Date)`
  - `func shift(by interval: TimeInterval)`

- [ ] **Step 1: 실패하는 테스트 작성**

`Tests/BlinkCoreTests/SchedulerTests.swift`:
```swift
import XCTest
@testable import BlinkCore

final class SchedulerTests: XCTestCase {
    private func makeScheduler() -> (Scheduler, TestClock) {
        let clock = TestClock()
        return (Scheduler(config: BreakConfig(), now: clock.now), clock)
    }

    func test_no_break_due_before_shortInterval() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 19 * 60)
        XCTAssertNil(s.dueBreak(at: clock.now))
    }

    func test_short_due_at_20min() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 20 * 60)
        XCTAssertEqual(s.dueBreak(at: clock.now), .short)
    }

    func test_long_takes_precedence_at_60min() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 60 * 60)
        XCTAssertEqual(s.dueBreak(at: clock.now), .long)
    }

    func test_timeUntilNextBreak_counts_down() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 5 * 60)
        XCTAssertEqual(s.timeUntilNextBreak(at: clock.now), 15 * 60, accuracy: 0.001)
    }

    func test_reschedule_short_pushes_next_short() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 20 * 60)
        s.reschedule(.short, from: clock.now)
        XCTAssertNil(s.dueBreak(at: clock.now))
        clock.advance(by: 20 * 60)
        XCTAssertEqual(s.dueBreak(at: clock.now), .short)
    }

    func test_reschedule_long_also_resets_short() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 60 * 60)
        s.reschedule(.long, from: clock.now)
        // 직후 20분 지점에 short 뜨는지 (long이 short도 리셋했으므로)
        clock.advance(by: 20 * 60)
        XCTAssertEqual(s.dueBreak(at: clock.now), .short)
    }

    func test_shift_moves_timers_forward() {
        let (s, clock) = makeScheduler()
        clock.advance(by: 20 * 60)
        s.shift(by: 30 * 60)          // 자리 비움 30분 보정
        XCTAssertNil(s.dueBreak(at: clock.now))
    }
}
```

- [ ] **Step 2: 실패 확인**

Run: `swift test --filter SchedulerTests`
Expected: FAIL — `Scheduler` 미정의

- [ ] **Step 3: 구현**

`Sources/BlinkCore/Scheduler.swift`:
```swift
import Foundation

public final class Scheduler {
    private let config: BreakConfig
    private var nextShort: Date
    private var nextLong: Date

    public init(config: BreakConfig, now: Date) {
        self.config = config
        self.nextShort = now.addingTimeInterval(config.shortInterval)
        self.nextLong = now.addingTimeInterval(config.longInterval)
    }

    /// long이 우선. 둘 다 도래하면 long.
    public func dueBreak(at now: Date) -> BreakKind? {
        if now >= nextLong { return .long }
        if now >= nextShort { return .short }
        return nil
    }

    public func timeUntilNextBreak(at now: Date) -> TimeInterval {
        max(0, min(nextShort, nextLong).timeIntervalSince(now))
    }

    /// 브레이크 완료/스킵 후 해당 종류 타이머 리셋. long은 short도 리셋(방금 쉬었으므로).
    public func reschedule(_ kind: BreakKind, from now: Date) {
        switch kind {
        case .short:
            nextShort = now.addingTimeInterval(config.shortInterval)
        case .long:
            nextLong = now.addingTimeInterval(config.longInterval)
            nextShort = now.addingTimeInterval(config.shortInterval)
        }
    }

    /// 미루기: 해당 종류의 다음 발동을 지정 시각으로.
    public func postpone(_ kind: BreakKind, until date: Date) {
        switch kind {
        case .short: nextShort = date
        case .long: nextLong = date
        }
    }

    /// 일시정지(자리 비움) 보정: 모든 타이머를 뒤로 민다.
    public func shift(by interval: TimeInterval) {
        nextShort = nextShort.addingTimeInterval(interval)
        nextLong = nextLong.addingTimeInterval(interval)
    }
}
```

- [ ] **Step 4: 통과 확인**

Run: `swift test --filter SchedulerTests`
Expected: PASS (7 tests)

- [ ] **Step 5: 커밋**

```bash
git add -A && git commit -m "feat: Scheduler — 2단계 주기 카운트다운 + long precedence

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 4: BreakEngine 상태머신 (전이 + skip/postpone/startNow)

**Files:**
- Create: `Sources/BlinkCore/BreakEngine.swift`
- Test: `Tests/BlinkCoreTests/BreakEngineTests.swift`

**Interfaces:**
- Consumes: `BreakConfig`, `Clock`, `Scheduler`, `EngineState`, `BreakKind`
- Produces: `final class BreakEngine`
  - `init(config: BreakConfig, clock: Clock)`
  - `var state: EngineState { get }`
  - `var onStateChange: ((EngineState) -> Void)?`
  - `var onBreakCompleted: (() -> Void)?`
  - `var onBreakSkipped: (() -> Void)?`
  - `func update()` — 매 tick 호출, 시간 기반 전이
  - `func timeUntilNextBreak() -> TimeInterval`
  - `func phaseRemaining() -> TimeInterval`
  - `func currentBreakKind() -> BreakKind?`
  - `func skipCurrent()`, `func postponeCurrent()`, `func startBreakNow()`
  - `func pause()`, `func resume()` (Task 5에서 테스트 추가, 시그니처는 여기서 확정)

- [ ] **Step 1: 실패하는 테스트 작성**

`Tests/BlinkCoreTests/BreakEngineTests.swift`:
```swift
import XCTest
@testable import BlinkCore

final class BreakEngineTests: XCTestCase {
    private func make() -> (BreakEngine, TestClock) {
        let clock = TestClock()
        return (BreakEngine(config: BreakConfig(), clock: clock), clock)
    }

    func test_starts_working() {
        let (e, _) = make()
        XCTAssertEqual(e.state, .working)
    }

    func test_enters_preBreak_short_after_20min() {
        let (e, clock) = make()
        clock.advance(by: 20 * 60); e.update()
        XCTAssertEqual(e.state, .preBreak(.short))
    }

    func test_preBreak_transitions_to_onBreak_after_warning() {
        let (e, clock) = make()
        clock.advance(by: 20 * 60); e.update()
        clock.advance(by: 10); e.update()
        XCTAssertEqual(e.state, .onBreak(.short))
    }

    func test_onBreak_completes_to_working_and_fires_completed() {
        let (e, clock) = make()
        var completed = 0
        e.onBreakCompleted = { completed += 1 }
        clock.advance(by: 20 * 60); e.update()   // preBreak
        clock.advance(by: 10); e.update()        // onBreak
        clock.advance(by: 20); e.update()        // shortDuration 경과
        XCTAssertEqual(e.state, .working)
        XCTAssertEqual(completed, 1)
    }

    func test_skip_returns_to_working_and_fires_skipped() {
        let (e, clock) = make()
        var skipped = 0
        e.onBreakSkipped = { skipped += 1 }
        clock.advance(by: 20 * 60); e.update()
        e.skipCurrent()
        XCTAssertEqual(e.state, .working)
        XCTAssertEqual(skipped, 1)
    }

    func test_postpone_reschedules_without_skip() {
        let (e, clock) = make()
        var skipped = 0
        e.onBreakSkipped = { skipped += 1 }
        clock.advance(by: 20 * 60); e.update()   // preBreak(.short)
        e.postponeCurrent()
        XCTAssertEqual(e.state, .working)
        XCTAssertEqual(skipped, 0)
        e.update()
        XCTAssertEqual(e.state, .working)         // 아직 도래 안 함
        clock.advance(by: 5 * 60); e.update()     // postponeInterval 뒤
        XCTAssertEqual(e.state, .preBreak(.short))
    }

    func test_startBreakNow_enters_onBreak_short() {
        let (e, _) = make()
        e.startBreakNow()
        XCTAssertEqual(e.state, .onBreak(.short))
    }

    func test_currentBreakKind_reflects_state() {
        let (e, clock) = make()
        XCTAssertNil(e.currentBreakKind())
        clock.advance(by: 60 * 60); e.update()    // preBreak(.long)
        XCTAssertEqual(e.currentBreakKind(), .long)
    }

    func test_onStateChange_fires_on_transition() {
        let (e, clock) = make()
        var seen: [EngineState] = []
        e.onStateChange = { seen.append($0) }
        clock.advance(by: 20 * 60); e.update()
        XCTAssertEqual(seen, [.preBreak(.short)])
    }
}
```

- [ ] **Step 2: 실패 확인**

Run: `swift test --filter BreakEngineTests`
Expected: FAIL — `BreakEngine` 미정의

- [ ] **Step 3: 구현**

`Sources/BlinkCore/BreakEngine.swift`:
```swift
import Foundation

public final class BreakEngine {
    public private(set) var state: EngineState = .working {
        didSet {
            if state != oldValue { onStateChange?(state) }
        }
    }

    public var onStateChange: ((EngineState) -> Void)?
    public var onBreakCompleted: (() -> Void)?
    public var onBreakSkipped: (() -> Void)?

    private let config: BreakConfig
    private let clock: Clock
    private let scheduler: Scheduler
    private var phaseEndsAt: Date?
    private var pausedAt: Date?

    public init(config: BreakConfig, clock: Clock) {
        self.config = config
        self.clock = clock
        self.scheduler = Scheduler(config: config, now: clock.now)
    }

    // MARK: 조회 (UI용)

    public func timeUntilNextBreak() -> TimeInterval {
        scheduler.timeUntilNextBreak(at: clock.now)
    }

    public func phaseRemaining() -> TimeInterval {
        guard let end = phaseEndsAt else { return 0 }
        return max(0, end.timeIntervalSince(clock.now))
    }

    public func currentBreakKind() -> BreakKind? {
        switch state {
        case .preBreak(let k), .onBreak(let k): return k
        default: return nil
        }
    }

    // MARK: tick

    public func update() {
        let now = clock.now
        switch state {
        case .working:
            if let kind = scheduler.dueBreak(at: now) {
                enterPreBreak(kind, now: now)
            }
        case .preBreak(let kind):
            if now >= (phaseEndsAt ?? now) {
                enterOnBreak(kind, now: now)
            }
        case .onBreak(let kind):
            if now >= (phaseEndsAt ?? now) {
                completeBreak(kind, now: now)
            }
        case .paused:
            break
        }
    }

    // MARK: 사용자 액션

    public func skipCurrent() {
        guard let kind = currentBreakKind() else { return }
        scheduler.reschedule(kind, from: clock.now)
        phaseEndsAt = nil
        onBreakSkipped?()
        state = .working
    }

    public func postponeCurrent() {
        guard let kind = currentBreakKind() else { return }
        scheduler.postpone(kind, until: clock.now.addingTimeInterval(config.postponeInterval))
        phaseEndsAt = nil
        state = .working
    }

    public func startBreakNow() {
        enterOnBreak(.short, now: clock.now)
    }

    // MARK: 일시정지 (Task 5에서 테스트)

    public func pause() {
        guard state == .working else { return }
        pausedAt = clock.now
        state = .paused
    }

    public func resume() {
        guard state == .paused, let since = pausedAt else { return }
        scheduler.shift(by: clock.now.timeIntervalSince(since))
        pausedAt = nil
        state = .working
    }

    // MARK: 내부 전이

    private func enterPreBreak(_ kind: BreakKind, now: Date) {
        phaseEndsAt = now.addingTimeInterval(config.preBreakWarning)
        state = .preBreak(kind)
    }

    private func enterOnBreak(_ kind: BreakKind, now: Date) {
        phaseEndsAt = now.addingTimeInterval(config.duration(for: kind))
        state = .onBreak(kind)
    }

    private func completeBreak(_ kind: BreakKind, now: Date) {
        scheduler.reschedule(kind, from: now)
        phaseEndsAt = nil
        onBreakCompleted?()
        state = .working
    }
}
```

- [ ] **Step 4: 통과 확인**

Run: `swift test --filter BreakEngineTests`
Expected: PASS (9 tests)

- [ ] **Step 5: 커밋**

```bash
git add -A && git commit -m "feat: BreakEngine 상태머신 — 전이/skip/postpone/startNow

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 5: 일시정지 동작 (유휴 pause/resume)

**Files:**
- Test: `Tests/BlinkCoreTests/BreakEngineTests.swift` (테스트 추가)

**Interfaces:**
- Consumes: Task 4의 `pause()` / `resume()` (이미 구현됨)
- Produces: 없음 (동작 검증만)

- [ ] **Step 1: 실패할 수 있는 테스트 추가**

`Tests/BlinkCoreTests/BreakEngineTests.swift`의 클래스 안에 메서드 추가:
```swift
    func test_pause_sets_paused_only_from_working() {
        let (e, clock) = make()
        e.pause()
        XCTAssertEqual(e.state, .paused)
        // preBreak 중엔 pause 무시
        e.resume()
        clock.advance(by: 20 * 60); e.update()   // preBreak
        e.pause()
        XCTAssertEqual(e.state, .preBreak(.short))
    }

    func test_idle_pause_freezes_countdown() {
        let (e, clock) = make()
        clock.advance(by: 10 * 60)   // 10분 작업
        e.pause()
        clock.advance(by: 30 * 60)   // 30분 자리 비움
        e.resume()
        e.update()
        XCTAssertEqual(e.state, .working)          // 정지 동안 카운트 안 감
        clock.advance(by: 10 * 60); e.update()     // 남은 10분 후 도래
        XCTAssertEqual(e.state, .preBreak(.short))
    }
```

- [ ] **Step 2: 실행 (Task 4 구현으로 통과 예상)**

Run: `swift test --filter BreakEngineTests`
Expected: PASS (11 tests). 실패하면 Task 4의 `pause/resume/shift` 로직을 테스트 기준으로 수정.

- [ ] **Step 3: 커밋**

```bash
git add -A && git commit -m "test: 유휴 pause/resume 카운트다운 동결 검증

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 6: StatsStore (오늘 요약 JSON 영속 + 날짜 리셋)

**Files:**
- Create: `Sources/BlinkCore/StatsStore.swift`
- Test: `Tests/BlinkCoreTests/StatsStoreTests.swift`

**Interfaces:**
- Consumes: `DayStats`
- Produces: `final class StatsStore`
  - `init(fileURL: URL, now: Date, calendar: Calendar = .current)`
  - `var today: DayStats { get }`
  - `func recordCompleted(now: Date)`, `func recordSkipped(now: Date)`
  - `static func dateKey(for: Date, calendar: Calendar) -> String`

- [ ] **Step 1: 실패하는 테스트 작성**

`Tests/BlinkCoreTests/StatsStoreTests.swift`:
```swift
import XCTest
@testable import BlinkCore

final class StatsStoreTests: XCTestCase {
    private var tmpURL: URL!

    override func setUp() {
        super.setUp()
        tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("blink-test-\(UUID().uuidString).json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tmpURL)
        super.tearDown()
    }

    func test_starts_empty_for_today() {
        let now = Date(timeIntervalSince1970: 0)
        let store = StatsStore(fileURL: tmpURL, now: now)
        XCTAssertEqual(store.today.breaksCompleted, 0)
        XCTAssertEqual(store.today.breaksSkipped, 0)
    }

    func test_records_and_persists() {
        let now = Date(timeIntervalSince1970: 0)
        let store = StatsStore(fileURL: tmpURL, now: now)
        store.recordCompleted(now: now)
        store.recordCompleted(now: now)
        store.recordSkipped(now: now)
        XCTAssertEqual(store.today.breaksCompleted, 2)
        XCTAssertEqual(store.today.breaksSkipped, 1)

        // 같은 날 재로드 시 유지
        let reloaded = StatsStore(fileURL: tmpURL, now: now)
        XCTAssertEqual(reloaded.today.breaksCompleted, 2)
        XCTAssertEqual(reloaded.today.breaksSkipped, 1)
    }

    func test_resets_on_new_day() {
        let day1 = Date(timeIntervalSince1970: 0)                 // 1970-01-01
        let store = StatsStore(fileURL: tmpURL, now: day1)
        store.recordCompleted(now: day1)

        let day2 = Date(timeIntervalSince1970: 60 * 60 * 24 * 2)  // 이틀 뒤
        let reloaded = StatsStore(fileURL: tmpURL, now: day2)
        XCTAssertEqual(reloaded.today.breaksCompleted, 0)         // 새 날 → 리셋
    }

    func test_corrupt_file_starts_empty() {
        try? "garbage".data(using: .utf8)!.write(to: tmpURL)
        let store = StatsStore(fileURL: tmpURL, now: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(store.today.breaksCompleted, 0)
    }
}
```

- [ ] **Step 2: 실패 확인**

Run: `swift test --filter StatsStoreTests`
Expected: FAIL — `StatsStore` 미정의

- [ ] **Step 3: 구현**

`Sources/BlinkCore/StatsStore.swift`:
```swift
import Foundation

public final class StatsStore {
    private let fileURL: URL
    private let calendar: Calendar
    public private(set) var today: DayStats

    public init(fileURL: URL, now: Date, calendar: Calendar = .current) {
        self.fileURL = fileURL
        self.calendar = calendar
        let key = StatsStore.dateKey(for: now, calendar: calendar)
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(DayStats.self, from: data),
           saved.date == key {
            self.today = saved
        } else {
            self.today = DayStats(date: key)
        }
    }

    public func recordCompleted(now: Date) {
        rollover(now)
        today.breaksCompleted += 1
        save()
    }

    public func recordSkipped(now: Date) {
        rollover(now)
        today.breaksSkipped += 1
        save()
    }

    public static func dateKey(for date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private func rollover(_ now: Date) {
        let key = StatsStore.dateKey(for: now, calendar: calendar)
        if today.date != key {
            today = DayStats(date: key)
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(today)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // 통계는 부가기능 — 저장 실패는 조용히 무시 (앱 동작 안 막음)
        }
    }
}
```

- [ ] **Step 4: 통과 확인**

Run: `swift test --filter StatsStoreTests`
Expected: PASS (4 tests)

Run: `swift test`
Expected: 전체 통과 (Clock/Scheduler/BreakEngine/StatsStore)

- [ ] **Step 5: 커밋**

```bash
git add -A && git commit -m "feat: StatsStore — 오늘 요약 JSON 영속 + 날짜 리셋

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 7: App 진입점 + MenuBarExtra (실행 타깃 골격)

**Files:**
- Create: `Sources/Blink/BlinkApp.swift`
- Create: `Sources/Blink/AppDelegate.swift`
- Create: `Sources/Blink/AppController.swift`
- Create: `Sources/Blink/MenuContent.swift`
- Delete: `Sources/Blink/main-placeholder.swift`

**Interfaces:**
- Consumes: `BreakEngine`, `BreakConfig`, `StatsStore`, `SystemClock`
- Produces: `AppController`(ObservableObject) — `@Published nextBreakText`, `@Published todayText`, `func quit()`, `func breakNow()`. `BlinkApp`(@main). `AppDelegate`.

- [ ] **Step 1: AppController 작성**

`Sources/Blink/AppController.swift`:
```swift
import SwiftUI
import BlinkCore

@MainActor
final class AppController: ObservableObject {
    @Published var nextBreakText: String = "--:--"
    @Published var todayText: String = "오늘: 0회 · 스킵 0"

    let engine: BreakEngine
    let statsStore: StatsStore
    private let clock = SystemClock()
    private var timer: Timer?

    init() {
        let config = AppController.loadConfig()
        engine = BreakEngine(config: config, clock: clock)
        statsStore = StatsStore(fileURL: AppController.statsURL(), now: clock.now)

        engine.onBreakCompleted = { [weak self] in
            self?.statsStore.recordCompleted(now: Date())
            self?.refresh()
        }
        engine.onBreakSkipped = { [weak self] in
            self?.statsStore.recordSkipped(now: Date())
            self?.refresh()
        }
        startTimer()
        refresh()
    }

    func breakNow() { engine.startBreakNow() }

    func quit() { NSApplication.shared.terminate(nil) }

    private func startTimer() {
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        engine.update()
        refresh()
    }

    private func refresh() {
        nextBreakText = AppController.mmss(engine.timeUntilNextBreak())
        let s = statsStore.today
        todayText = "오늘: \(s.breaksCompleted)회 · 스킵 \(s.breaksSkipped)"
    }

    // MARK: helpers

    static func mmss(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    // 디버그: BLINK_FAST=1 이면 초 단위로 빠른 주기
    static func loadConfig() -> BreakConfig {
        if ProcessInfo.processInfo.environment["BLINK_FAST"] == "1" {
            return BreakConfig(
                shortInterval: 15, shortDuration: 5,
                longInterval: 40, longDuration: 10,
                preBreakWarning: 3, idleThreshold: 10, postponeInterval: 15
            )
        }
        return ConfigStore(defaults: .standard).load()   // Task 11
    }

    static func statsURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Blink/stats.json")
    }
}
```

> 참고: `ConfigStore`는 Task 11에서 만든다. Task 7 시점엔 아래 임시 구현을 `Sources/BlinkCore/ConfigStore.swift`에 두고 Task 11에서 확장한다:
> ```swift
> import Foundation
> public final class ConfigStore {
>     private let defaults: UserDefaults
>     public init(defaults: UserDefaults) { self.defaults = defaults }
>     public func load() -> BreakConfig { BreakConfig() }
>     public func save(_ config: BreakConfig) {}
> }
> ```

- [ ] **Step 2: MenuContent 작성**

`Sources/Blink/MenuContent.swift`:
```swift
import SwiftUI

struct MenuContent: View {
    @ObservedObject var controller: AppController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("다음 브레이크까지  \(controller.nextBreakText)")
                .font(.headline)
            Text(controller.todayText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Divider()
            Button("지금 쉬기") { controller.breakNow() }
            SettingsLink { Text("설정…") }   // macOS 14+
            Divider()
            Button("종료") { controller.quit() }
        }
        .padding(12)
        .frame(width: 240)
    }
}
```

- [ ] **Step 3: AppDelegate 작성**

`Sources/Blink/AppDelegate.swift`:
```swift
import SwiftUI
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = AppController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 메뉴바 전용 (Dock 아이콘 숨김)
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
```

- [ ] **Step 4: BlinkApp(@main) 작성 + 스텁 삭제**

`Sources/Blink/BlinkApp.swift`:
```swift
import SwiftUI

@main
struct BlinkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("Blink", systemImage: "eye") {
            MenuContent(controller: delegate.controller)
        }
        .menuBarExtraStyle(.window)

        Settings {
            // Task 11에서 SettingsView로 교체
            Text("설정 (준비 중)").padding(40)
        }
    }
}
```

Run: `rm Sources/Blink/main-placeholder.swift`

- [ ] **Step 5: 빌드 + 수동 확인**

Run: `swift build`
Expected: `Build complete!`

Run: `BLINK_FAST=1 swift run Blink`
Expected(수동): 메뉴바에 눈(eye) 아이콘. 클릭하면 "다음 브레이크까지 mm:ss", "오늘: 0회 · 스킵 0", [지금 쉬기] [설정…] [종료]. ~15초 뒤 카운트다운이 0에 근접(오버레이/알림은 아직 없음 — Task 8/9). "종료"로 종료.

- [ ] **Step 6: 커밋**

```bash
git add -A && git commit -m "feat: MenuBarExtra 앱 골격 — AppController + 1초 tick + 메뉴 UI

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 8: 전체화면 오버레이 (NSPanel, 모니터별)

**Files:**
- Create: `Sources/Blink/OverlayView.swift`
- Create: `Sources/Blink/OverlayController.swift`
- Modify: `Sources/Blink/AppController.swift` (상태 변화 → 오버레이 표시/숨김 배선)

**Interfaces:**
- Consumes: `AppController`, `BreakEngine` 조회(`phaseRemaining`, `currentBreakKind`), 액션(`skipCurrent`, `postponeCurrent`)
- Produces:
  - `OverlayController` — `func show(kind: BreakKind, controller: AppController)`, `func updateCountdown(_ text: String)`, `func hide()`
  - `OverlayView`(SwiftUI)

- [ ] **Step 1: OverlayView 작성**

`Sources/Blink/OverlayView.swift`:
```swift
import SwiftUI

struct OverlayView: View {
    let title: String
    let countdown: String
    let onSkip: () -> Void
    let onPostpone: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(title).font(.system(size: 34, weight: .semibold))
                Text("20피트(약 6m) 밖을 바라보세요").font(.title3).foregroundStyle(.secondary)
                Text(countdown).font(.system(size: 64, weight: .bold, design: .rounded)).monospacedDigit()
                HStack(spacing: 16) {
                    Button("미루기", action: onPostpone)
                    Button("건너뛰기", action: onSkip)
                }
                .controlSize(.large)
            }
            .foregroundStyle(.white)
        }
    }
}
```

- [ ] **Step 2: OverlayController 작성**

`Sources/Blink/OverlayController.swift`:
```swift
import SwiftUI
import AppKit
import BlinkCore

@MainActor
final class OverlayController {
    private var panels: [NSPanel] = []
    private var countdownText = ""

    func show(kind: BreakKind, controller: AppController) {
        hide()
        let title = kind == .short ? "눈 휴식" : "긴 휴식"
        for screen in NSScreen.screens {
            let panel = NSPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.level = .screenSaver
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.ignoresMouseEvents = false
            panel.hasShadow = false

            let root = OverlayView(
                title: title,
                countdown: countdownText,
                onSkip: { [weak controller] in controller?.engine.skipCurrent() },
                onPostpone: { [weak controller] in controller?.engine.postponeCurrent() }
            )
            let host = NSHostingView(rootView: root)
            host.frame = CGRect(origin: .zero, size: screen.frame.size)
            panel.contentView = host
            panel.setFrame(screen.frame, display: true)
            panel.orderFrontRegardless()
            panels.append(panel)
        }
    }

    func updateCountdown(_ text: String, kind: BreakKind, controller: AppController) {
        countdownText = text
        let title = kind == .short ? "눈 휴식" : "긴 휴식"
        for panel in panels {
            let root = OverlayView(
                title: title,
                countdown: text,
                onSkip: { [weak controller] in controller?.engine.skipCurrent() },
                onPostpone: { [weak controller] in controller?.engine.postponeCurrent() }
            )
            (panel.contentView as? NSHostingView<OverlayView>)?.rootView = root
        }
    }

    func hide() {
        for panel in panels { panel.orderOut(nil) }
        panels.removeAll()
    }
}
```

- [ ] **Step 3: AppController에 오버레이 배선**

`Sources/Blink/AppController.swift`의 `init()` 안 `startTimer()` 호출 **앞**에 추가:
```swift
        engine.onStateChange = { [weak self] state in
            self?.handleStateChange(state)
        }
```

같은 파일에 프로퍼티와 메서드 추가 (`private var timer` 선언 아래):
```swift
    private let overlay = OverlayController()
```

그리고 클래스 안에 메서드 추가:
```swift
    private func handleStateChange(_ state: EngineState) {
        switch state {
        case .onBreak(let kind):
            let config = engine // 모드 판단은 Task 9에서 확장. 지금은 항상 오버레이.
            _ = config
            overlay.show(kind: kind, controller: self)
        case .working, .paused, .preBreak:
            overlay.hide()
        }
    }
```

`tick()`을 수정 — 오버레이 카운트다운 갱신:
```swift
    private func tick() {
        engine.update()
        if let kind = engine.currentBreakKind(), case .onBreak = engine.state {
            overlay.updateCountdown(AppController.mmss(engine.phaseRemaining()), kind: kind, controller: self)
        }
        refresh()
    }
```

- [ ] **Step 4: 빌드 + 수동 확인**

Run: `swift build && BLINK_FAST=1 swift run Blink`
Expected(수동): ~15초 뒤 화면 전체가 어두워지며 "눈 휴식 / 00:05" 카운트다운 + [미루기][건너뛰기]. 5초 뒤 자동으로 사라짐(오늘 1회 반영). [건너뛰기] 누르면 즉시 사라지고 스킵 +1. 다중 모니터면 모든 화면에 표시.

- [ ] **Step 5: 커밋**

```bash
git add -A && git commit -m "feat: NSPanel 전체화면 오버레이 (모니터별) + 카운트다운/스킵/미루기

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 9: 알림 개입 + 종류별 모드(오버레이 vs 알림)

**Files:**
- Create: `Sources/Blink/Notifier.swift`
- Modify: `Sources/Blink/AppController.swift` (모드별 분기 + 알림 배선 + preBreak 예고)

**Interfaces:**
- Consumes: `BreakConfig.mode(for:)`, `UNUserNotificationCenter`
- Produces: `Notifier` — `func requestAuthorization()`, `func notifyBreak(kind:remaining:)`, `func notifyWarning(kind:)`, `func clear()`, 액션 핸들러가 `AppController`로 skip/postpone 전달

- [ ] **Step 1: Notifier 작성**

`Sources/Blink/Notifier.swift`:
```swift
import Foundation
import UserNotifications
import BlinkCore

@MainActor
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let categoryId = "BLINK_BREAK"
    static let skipAction = "BLINK_SKIP"
    static let postponeAction = "BLINK_POSTPONE"

    weak var controller: AppController?

    func configure() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let skip = UNNotificationAction(identifier: Notifier.skipAction, title: "건너뛰기", options: [])
        let postpone = UNNotificationAction(identifier: Notifier.postponeAction, title: "미루기", options: [])
        let category = UNNotificationCategory(
            identifier: Notifier.categoryId,
            actions: [postpone, skip],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notifyWarning(kind: BreakKind) {
        post(title: kind == .short ? "곧 눈 휴식" : "곧 긴 휴식",
             body: "잠시 후 브레이크가 시작됩니다.", id: "warning")
    }

    func notifyBreak(kind: BreakKind, remaining: TimeInterval) {
        let secs = Int(remaining.rounded())
        post(title: kind == .short ? "눈 휴식" : "긴 휴식",
             body: "20피트 밖을 \(secs)초간 바라보세요.", id: "break")
    }

    func clear() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    private func post(title: String, body: String, id: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = Notifier.categoryId
        let req = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    // 포그라운드에서도 배너 표시
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .list]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        switch response.actionIdentifier {
        case Notifier.skipAction: controller?.engine.skipCurrent()
        case Notifier.postponeAction: controller?.engine.postponeCurrent()
        default: break
        }
    }
}
```

- [ ] **Step 2: AppController에서 모드별 분기**

`Sources/Blink/AppController.swift`에 프로퍼티 추가:
```swift
    private let notifier = Notifier()
    private let config: BreakConfig
```

`init()` 상단에서 `let config = AppController.loadConfig()`를 `self.config = AppController.loadConfig()`로 바꾸고 `engine = BreakEngine(config: config, ...)`도 `self.config` 사용. `init()` 안 `startTimer()` 앞에 추가:
```swift
        notifier.controller = self
        notifier.configure()
```

`handleStateChange`를 모드 인식하도록 교체:
```swift
    private func handleStateChange(_ state: EngineState) {
        switch state {
        case .preBreak(let kind):
            overlay.hide()
            if config.mode(for: kind) == .overlay {
                notifier.notifyWarning(kind: kind)   // 오버레이 모드는 예고 배너
            }
        case .onBreak(let kind):
            if config.mode(for: kind) == .overlay {
                overlay.show(kind: kind, controller: self)
            } else {
                notifier.notifyBreak(kind: kind, remaining: engine.phaseRemaining())
            }
        case .working, .paused:
            overlay.hide()
            notifier.clear()
        }
    }
```

- [ ] **Step 3: 빌드 + 수동 확인**

Run: `swift build && BLINK_FAST=1 swift run Blink`
Expected(수동): 최초 실행 시 알림 권한 요청 팝업 → 허용. 짧은 브레이크(기본 `shortMode=.notification`)는 배너 "눈 휴식 …"으로, 배너의 [미루기]/[건너뛰기] 동작 확인. 긴 브레이크(`longMode=.overlay`, FAST에선 40초)는 예고 배너 후 오버레이 표시.

- [ ] **Step 4: 커밋**

```bash
git add -A && git commit -m "feat: 알림 개입 + 종류별 모드(오버레이/알림) 분기, 알림 액션 skip/postpone

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 10: 스마트 일시정지 — 유휴 감지 + 전체화면 미룸

**Files:**
- Create: `Sources/Blink/IdleDetector.swift`
- Create: `Sources/Blink/FullscreenDetector.swift`
- Modify: `Sources/Blink/AppController.swift` (tick에 감지 배선)

**Interfaces:**
- Consumes: `CGEventSource`, `NSWorkspace`, `CGWindowListCopyWindowInfo`
- Produces:
  - `enum IdleDetector { static func idleSeconds() -> TimeInterval }`
  - `enum FullscreenDetector { static func isFullscreenActive() -> Bool }`

- [ ] **Step 1: IdleDetector 작성**

`Sources/Blink/IdleDetector.swift`:
```swift
import CoreGraphics
import Foundation

enum IdleDetector {
    /// 마지막 입력(키/마우스) 이후 경과 초.
    static func idleSeconds() -> TimeInterval {
        let anyInput = CGEventType(rawValue: ~0)!
        return CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: anyInput)
    }
}
```

- [ ] **Step 2: FullscreenDetector 작성**

`Sources/Blink/FullscreenDetector.swift`:
```swift
import AppKit
import CoreGraphics

enum FullscreenDetector {
    /// 최전면 앱의 창이 메인 화면을 꽉 채우는지(메뉴바 가림)로 판정하는 heuristic.
    /// 발표·전체화면 영상 감지용. 완벽하지 않으며 추후 정교화 여지 있음.
    static func isFullscreenActive() -> Bool {
        guard let main = NSScreen.main else { return false }
        let screenFrame = main.frame
        guard let front = NSWorkspace.shared.frontmostApplication else { return false }
        let pid = front.processIdentifier

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        for info in infoList {
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t, ownerPID == pid,
                  let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                  let boundsDict = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let w = boundsDict["Width"], let h = boundsDict["Height"]
            else { continue }
            // 화면 크기와 거의 같으면 전체화면으로 간주 (2pt 여유)
            if abs(w - screenFrame.width) < 2, abs(h - screenFrame.height) < 2 {
                return true
            }
        }
        return false
    }
}
```

- [ ] **Step 3: AppController.tick에 감지 배선**

`Sources/Blink/AppController.swift`의 `tick()`를 교체:
```swift
    private func tick() {
        applyPauseLogic()
        engine.update()
        if let kind = engine.currentBreakKind(), case .onBreak = engine.state {
            overlay.updateCountdown(AppController.mmss(engine.phaseRemaining()), kind: kind, controller: self)
        }
        refresh()
    }

    private func applyPauseLogic() {
        let idle = IdleDetector.idleSeconds()
        switch engine.state {
        case .working where idle >= config.idleThreshold:
            engine.pause()                      // 자리 비움 → 정지
        case .paused where idle < config.idleThreshold:
            engine.resume()                     // 복귀 → 재개
        case .preBreak where FullscreenDetector.isFullscreenActive():
            engine.postponeCurrent()            // 전체화면 앱이면 미룸
        default:
            break
        }
    }
```

- [ ] **Step 4: 빌드 + 수동 확인**

Run: `swift build && BLINK_FAST=1 swift run Blink`
Expected(수동):
- 입력 없이 10초 이상 두면(FAST의 idleThreshold=10) 메뉴바 카운트다운이 멈춤(정지). 마우스 움직이면 재개.
- 브레이크 도래 시점에 어떤 앱을 전체화면(초록 버튼)으로 두면 오버레이가 뜨지 않고 미뤄짐. 전체화면 해제하면 다음 도래 때 정상 표시.
> 참고: 유휴/전체화면 감지는 접근성/화면기록 권한과 무관하게 동작하지만, 일부 환경에서 `CGWindowList`가 제한될 수 있음. 그 경우 전체화면 미룸만 보수적으로 false 반환(브레이크는 정상 표시).

- [ ] **Step 5: 커밋**

```bash
git add -A && git commit -m "feat: 스마트 일시정지 — 유휴 pause/resume + 전체화면 앱 미룸

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 12: 설정창 (ConfigStore + SettingsView)

**Files:**
- Modify: `Sources/BlinkCore/ConfigStore.swift` (Task 7 임시 구현 → 실제 영속)
- Create: `Tests/BlinkCoreTests/ConfigStoreTests.swift`
- Create: `Sources/Blink/SettingsView.swift`
- Modify: `Sources/Blink/BlinkApp.swift` (Settings scene 교체)

**Interfaces:**
- Consumes: `BreakConfig`, `BreakMode`, `UserDefaults`
- Produces: `ConfigStore` — `init(defaults:)`, `func load() -> BreakConfig`, `func save(_ config: BreakConfig)`. `SettingsView`.

- [ ] **Step 1: ConfigStore 실패 테스트 작성**

`Tests/BlinkCoreTests/ConfigStoreTests.swift`:
```swift
import XCTest
@testable import BlinkCore

final class ConfigStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "blink-configstore-test"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }

    func test_load_returns_defaults_when_empty() {
        let store = ConfigStore(defaults: defaults)
        XCTAssertEqual(store.load(), BreakConfig())
    }

    func test_save_then_load_roundtrips() {
        let store = ConfigStore(defaults: defaults)
        var c = BreakConfig()
        c.shortInterval = 25 * 60
        c.shortMode = .overlay
        c.longMode = .notification
        store.save(c)

        let reloaded = ConfigStore(defaults: defaults).load()
        XCTAssertEqual(reloaded.shortInterval, 25 * 60)
        XCTAssertEqual(reloaded.shortMode, .overlay)
        XCTAssertEqual(reloaded.longMode, .notification)
    }
}
```

- [ ] **Step 2: 실패 확인**

Run: `swift test --filter ConfigStoreTests`
Expected: FAIL — `load()`이 항상 기본값 반환(roundtrip 실패)

- [ ] **Step 3: ConfigStore 구현 (임시 구현 교체)**

`Sources/BlinkCore/ConfigStore.swift` (전체 교체):
```swift
import Foundation

public final class ConfigStore {
    private let defaults: UserDefaults
    public init(defaults: UserDefaults) { self.defaults = defaults }

    private enum Key {
        static let shortInterval = "blink.shortInterval"
        static let shortDuration = "blink.shortDuration"
        static let longInterval = "blink.longInterval"
        static let longDuration = "blink.longDuration"
        static let preBreakWarning = "blink.preBreakWarning"
        static let idleThreshold = "blink.idleThreshold"
        static let postponeInterval = "blink.postponeInterval"
        static let shortMode = "blink.shortMode"
        static let longMode = "blink.longMode"
        static let marker = "blink.hasConfig"
    }

    public func load() -> BreakConfig {
        guard defaults.bool(forKey: Key.marker) else { return BreakConfig() }
        var c = BreakConfig()
        c.shortInterval = defaults.double(forKey: Key.shortInterval)
        c.shortDuration = defaults.double(forKey: Key.shortDuration)
        c.longInterval = defaults.double(forKey: Key.longInterval)
        c.longDuration = defaults.double(forKey: Key.longDuration)
        c.preBreakWarning = defaults.double(forKey: Key.preBreakWarning)
        c.idleThreshold = defaults.double(forKey: Key.idleThreshold)
        c.postponeInterval = defaults.double(forKey: Key.postponeInterval)
        c.shortMode = BreakMode(rawValue: defaults.string(forKey: Key.shortMode) ?? "") ?? c.shortMode
        c.longMode = BreakMode(rawValue: defaults.string(forKey: Key.longMode) ?? "") ?? c.longMode
        return c
    }

    public func save(_ config: BreakConfig) {
        defaults.set(config.shortInterval, forKey: Key.shortInterval)
        defaults.set(config.shortDuration, forKey: Key.shortDuration)
        defaults.set(config.longInterval, forKey: Key.longInterval)
        defaults.set(config.longDuration, forKey: Key.longDuration)
        defaults.set(config.preBreakWarning, forKey: Key.preBreakWarning)
        defaults.set(config.idleThreshold, forKey: Key.idleThreshold)
        defaults.set(config.postponeInterval, forKey: Key.postponeInterval)
        defaults.set(config.shortMode.rawValue, forKey: Key.shortMode)
        defaults.set(config.longMode.rawValue, forKey: Key.longMode)
        defaults.set(true, forKey: Key.marker)
    }
}
```

- [ ] **Step 4: 통과 확인**

Run: `swift test --filter ConfigStoreTests`
Expected: PASS (2 tests)

- [ ] **Step 5: SettingsView 작성**

`Sources/Blink/SettingsView.swift`:
```swift
import SwiftUI
import BlinkCore

struct SettingsView: View {
    // 분 단위로 편집 (사용자 친화)
    @AppStorage("blink.shortInterval") private var shortInterval: Double = 20 * 60
    @AppStorage("blink.shortDuration") private var shortDuration: Double = 20
    @AppStorage("blink.longInterval") private var longInterval: Double = 60 * 60
    @AppStorage("blink.longDuration") private var longDuration: Double = 5 * 60
    @AppStorage("blink.shortMode") private var shortMode: String = BreakMode.notification.rawValue
    @AppStorage("blink.longMode") private var longMode: String = BreakMode.overlay.rawValue
    @AppStorage("blink.hasConfig") private var hasConfig: Bool = false
    @AppStorage("blink.launchAtLogin") private var launchAtLogin: Bool = false

    var body: some View {
        Form {
            Section("짧은 브레이크 (눈 쉬기)") {
                LabeledContent("주기") { minutesField($shortInterval) }
                LabeledContent("길이(초)") { secondsField($shortDuration) }
                Picker("방식", selection: $shortMode) {
                    Text("알림").tag(BreakMode.notification.rawValue)
                    Text("오버레이").tag(BreakMode.overlay.rawValue)
                }.pickerStyle(.segmented)
            }
            Section("긴 브레이크") {
                LabeledContent("주기") { minutesField($longInterval) }
                LabeledContent("길이(분)") { minutesField($longDuration) }
                Picker("방식", selection: $longMode) {
                    Text("알림").tag(BreakMode.notification.rawValue)
                    Text("오버레이").tag(BreakMode.overlay.rawValue)
                }.pickerStyle(.segmented)
            }
            Section {
                Toggle("로그인 시 자동 실행", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in
                        LaunchAtLogin.set(enabled: on)   // Task 11 (먼저 구현됨)
                    }
            }
            Text("변경은 다음 실행부터 적용됩니다.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 420)
        .onAppear { hasConfig = true }
        .onDisappear { hasConfig = true }
    }

    private func minutesField(_ value: Binding<Double>) -> some View {
        HStack {
            TextField("", value: Binding(
                get: { value.wrappedValue / 60 },
                set: { value.wrappedValue = $0 * 60 }
            ), format: .number).frame(width: 60).multilineTextAlignment(.trailing)
            Text("분")
        }
    }

    private func secondsField(_ value: Binding<Double>) -> some View {
        HStack {
            TextField("", value: value, format: .number).frame(width: 60).multilineTextAlignment(.trailing)
            Text("초")
        }
    }
}
```

> 참고: `SettingsView`는 개별 값을 `@AppStorage`로 직접 쓰므로, `hasConfig` 마커를 켜서 `ConfigStore.load()`가 저장된 값을 읽게 한다. 개별 키 문자열은 `ConfigStore.Key`와 **정확히 일치**해야 한다(`blink.shortInterval` 등).

- [ ] **Step 6: BlinkApp의 Settings scene 교체**

`Sources/Blink/BlinkApp.swift`의 `Settings { Text("설정 (준비 중)").padding(40) }`을 교체:
```swift
        Settings {
            SettingsView()
        }
```

- [ ] **Step 7: 빌드 + 수동 확인**

Run: `swift build && swift run Blink`
Expected(수동): 메뉴 → [설정…] → 설정창. 주기/길이/방식 변경 후 앱 재실행 시 반영(카운트다운 주기 변화로 확인). `swift test` 전체 통과.

- [ ] **Step 8: 커밋**

```bash
git add -A && git commit -m "feat: 설정 영속(ConfigStore) + SettingsView

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 11: 로그인 시 자동 실행 (SMAppService)

> ⚠️ 이 태스크는 문서상 아래에 있지만 **Task 12(설정창)보다 먼저** 수행한다 — 설정창이 `LaunchAtLogin.set`을 참조하므로.


**Files:**
- Create: `Sources/Blink/LaunchAtLogin.swift`

**Interfaces:**
- Consumes: `ServiceManagement.SMAppService`
- Produces: `enum LaunchAtLogin { static func set(enabled: Bool); static var isEnabled: Bool }`

- [ ] **Step 1: LaunchAtLogin 작성**

`Sources/Blink/LaunchAtLogin.swift`:
```swift
import ServiceManagement
import Foundation

enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func set(enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("LaunchAtLogin 실패: \(error.localizedDescription)")
        }
    }
}
```

- [ ] **Step 2: 빌드 확인**

Run: `swift build`
Expected: `Build complete!`
> 참고: `SMAppService.mainApp`은 **번들된 .app에서만** 정상 등록된다(`swift run`의 느슨한 실행 파일에선 무시/실패). 실제 동작 확인은 Task 13에서 .app 패키징 후.

- [ ] **Step 3: 커밋**

```bash
git add -A && git commit -m "feat: 로그인 시 자동 실행 토글 (SMAppService)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

### Task 13: .app 번들 패키징 (일상 사용 + LaunchAtLogin 활성화)

**Files:**
- Create: `packaging/Info.plist`
- Create: `packaging/make-app.sh`
- Create: `README.md`

**Interfaces:**
- Consumes: `swift build -c release`의 산출 실행 파일
- Produces: `Blink.app` 번들 (`LSUIElement`로 메뉴바 전용), 실행/설치 절차

- [ ] **Step 1: Info.plist 작성**

`packaging/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Blink</string>
    <key>CFBundleDisplayName</key><string>Blink</string>
    <key>CFBundleIdentifier</key><string>com.hangguma.blink</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleExecutable</key><string>Blink</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHumanReadableCopyright</key><string>© 2026</string>
</dict>
</plist>
```

- [ ] **Step 2: make-app.sh 작성**

`packaging/make-app.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP="Blink.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp packaging/Info.plist "$APP/Contents/Info.plist"
cp "$(swift build -c release --show-bin-path)/Blink" "$APP/Contents/MacOS/Blink"

# 로컬 실행용 ad-hoc 서명 (SMAppService 등록에 필요)
codesign --force --deep --sign - "$APP"

echo "생성됨: $APP"
echo "설치: '$APP'를 /Applications 로 이동한 뒤 실행하세요."
```

- [ ] **Step 3: 실행 권한 부여 + 빌드**

Run: `chmod +x packaging/make-app.sh && ./packaging/make-app.sh`
Expected: `생성됨: Blink.app`

- [ ] **Step 4: README 작성**

`README.md`:
```markdown
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
```

- [ ] **Step 5: 수동 확인**

Run: `open Blink.app`
Expected(수동): Dock 아이콘 없이 메뉴바에만 눈 아이콘. 설정에서 [로그인 시 자동 실행] 켜고 재로그인 시 자동 실행되는지 확인. `~/Library/Application Support/Blink/stats.json` 생성 확인.

- [ ] **Step 6: 커밋**

```bash
git add -A && git commit -m "feat: .app 번들 패키징 + README (LSUIElement 메뉴바 전용, ad-hoc 서명)

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## 빌드 아티팩트 gitignore 확인

`Blink.app/`은 빌드 산출물이므로 `.gitignore`에 추가:
```
Blink.app/
```
(Task 13 커밋 전 `.gitignore`에 반영)

---

## Self-Review 체크 결과

**Spec coverage** — 스펙 각 요구사항 → 태스크 매핑:
- 2단계 브레이크 → Task 3(Scheduler) + Task 4(Engine)
- 예고(preBreak) → Task 4(enterPreBreak) + Task 9(예고 배너)
- 오버레이+알림 종류별 선택 → Task 8 + Task 9 + Task 11(모드 설정)
- 스킵/미루기 → Task 4(엔진) + Task 8(오버레이 버튼) + Task 9(알림 액션)
- 자리 비움 자동 멈춤 → Task 4/5(pause/resume) + Task 10(IdleDetector)
- 전체화면 앱 미룸 → Task 10(FullscreenDetector)
- 오늘 요약 통계 → Task 6(StatsStore) + Task 7(메뉴 표시)
- 로컬 저장(JSON/UserDefaults) → Task 6 + Task 11
- 자동 실행 → Task 12 + Task 13(.app)
- 다중 모니터 오버레이 → Task 8
- 엣지(JSON 손상/권한 거부/브레이크 중 자리 비움) → Task 6(손상), Task 9/10(권한), Task 4(브레이크 중 idle은 pause 무시로 자연 완료)
- macOS 14+/의존성 0/소리 없음 → Global Constraints + Package.swift

**Placeholder scan** — "TBD/TODO/적절히 처리" 없음. Task 7의 `ConfigStore` 임시 구현은 코드로 명시했고 Task 11에서 실제 구현으로 교체(경로·이유 명시).

**Type consistency** — 교차 태스크 시그니처 확인:
- `engine.skipCurrent()/postponeCurrent()/startBreakNow()` — Task 4 정의, Task 8/9에서 호출 일치
- `config.mode(for:)/duration(for:)` — Task 2 정의, Task 9에서 사용 일치
- `ConfigStore.Key.*` 문자열 ↔ SettingsView `@AppStorage` 키 — 둘 다 `blink.*`로 일치(Task 11에서 명시)
- `StatsStore.dateKey/recordCompleted/recordSkipped` — Task 6 정의, Task 7에서 호출 일치
- `LaunchAtLogin.set(enabled:)` — **Task 11**(자동실행)에서 정의, **Task 12**(설정창)에서 호출. 번호를 조정해 정의가 먼저 오도록 정렬 완료(Task 11 → Task 12 순서). 문서 물리적 위치와 무관하게 번호 순서대로 수행하면 빌드 안전.
