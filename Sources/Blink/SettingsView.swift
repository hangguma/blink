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
