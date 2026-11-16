import SwiftUI

struct ContentView: View {
  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var model = AirLunaViewModel()

  var body: some View {
    NavigationView {
      Form {
        Section("状态") {
          statusRow("AirPods", model.airPodsStatus)
          statusRow("Luna", model.cameraStatus)
          statusRow("固件", model.firmwareStatus)
          statusRow("协议", model.protocolStatus)
          statusRow("运动频率", model.motionRateText)
        }

        Section("连接") {
          TextField("Luna IP", text: $model.cameraHost)
            .textInputAutocapitalization(.never)
            .keyboardType(.numbersAndPunctuation)
          Stepper("端口 \(model.cameraPort)", value: $model.cameraPort, in: 1...65535)
        }

        Section("控制") {
          Button("3 秒后校准并开始") {
            model.start()
          }
          .disabled(model.isRunning || model.isTestingMotion)

          Text("当前协议为方向重放：用于验证头控方向，不是最终 1:1 角度模式。")
            .font(.footnote)
            .foregroundColor(.secondary)

          Button("测试 AirPods") {
            model.testAirPods()
          }
          .disabled(model.isRunning || model.isTestingMotion)

          Button("停止", role: .destructive) {
            model.stop(reason: "用户停止")
          }
          .disabled(!model.isRunning && !model.isTestingMotion && !model.isReplayConnected)
        }

        Section("抓包重放测试") {
          Button("连接 Luna（重放）") {
            model.connectReplay()
          }
          .disabled(model.isRunning || model.isTestingMotion || model.isReplayConnected)

          VStack(spacing: 12) {
            HStack(spacing: 12) {
              replayButton("上", direction: "up")
              replayButton("下", direction: "down")
            }
            HStack(spacing: 12) {
              replayButton("左", direction: "left")
              replayButton("右", direction: "right")
            }
          }
          .disabled(model.isRunning || model.isTestingMotion)
        }

        Section("当前姿态") {
          statusRow("Yaw", model.yawText)
          statusRow("Pitch", model.pitchText)
          statusRow("Pan", model.panText)
          statusRow("Tilt", model.tiltText)
        }

        Section("参数") {
          slider("Pan 增益", value: $model.panGain, range: -2...2)
          slider("Tilt 增益", value: $model.tiltGain, range: -2...2)
          slider("平滑", value: $model.smoothingMs, range: 0...100, suffix: "ms")
        }
      }
      .navigationTitle("AirLuna")
    }
    .onChange(of: scenePhase) { phase in
      if phase != .active {
        model.stop(reason: "App 进入后台")
      }
    }
  }

  private func statusRow(_ title: String, _ value: String) -> some View {
    HStack {
      Text(title)
      Spacer()
      Text(value)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.trailing)
    }
  }

  private func slider(
    _ title: String,
    value: Binding<Double>,
    range: ClosedRange<Double>,
    suffix: String = ""
  ) -> some View {
    VStack(alignment: .leading) {
      HStack {
        Text(title)
        Spacer()
        Text("\(value.wrappedValue, specifier: "%.2f")\(suffix)")
          .foregroundColor(.secondary)
      }
      Slider(value: value, in: range)
    }
  }

  private func replayButton(_ title: String, direction: String) -> some View {
    Button {
      model.replay(direction)
    } label: {
      Text(title)
        .font(.title2)
        .frame(maxWidth: .infinity, minHeight: 80)
    }
    .buttonStyle(.borderedProminent)
  }
}

#Preview {
  ContentView()
}
