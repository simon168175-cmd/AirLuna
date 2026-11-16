import Foundation
import simd

@MainActor
final class AirLunaViewModel: ObservableObject {
  @Published var cameraHost = "192.168.42.1"
  @Published var cameraPort = 6666
  @Published var airPodsStatus = "未连接"
  @Published var cameraStatus = "未连接"
  @Published var firmwareStatus = "未验证"
  @Published var protocolStatus = "未验证"
  @Published var yawText = "0.0°"
  @Published var pitchText = "0.0°"
  @Published var panText = "0.0°"
  @Published var tiltText = "0.0°"
  @Published var motionRateText = "0 Hz"
  @Published var panGain = 1.0
  @Published var tiltGain = 1.0
  @Published var smoothingMs = 30.0
  @Published private(set) var isRunning = false
  @Published private(set) var isTestingMotion = false
  @Published private(set) var isReplayConnected = false

  private let motion = HeadphoneMotionService()
  private let luna = LunaSession()
  private var controller = GimbalController()
  private var profile = LunaProtocolProfile()
  private var latestSample: HeadPoseSample?
  private var motionWindowStart: TimeInterval?
  private var motionSamplesInWindow = 0
  private var lastDirectionalSendTime: TimeInterval = 0
  private var lastDirectionalCommand: String?
  private var calibrationDeadline: TimeInterval?

  init() {
    loadProfile()
    motion.onSample = { [weak self] sample in
      Task { @MainActor in
        self?.handle(sample: sample)
      }
    }
    motion.onStatus = { [weak self] status in
      Task { @MainActor in
        self?.airPodsStatus = status
      }
    }
  }

  func start() {
    guard profile.controlMode == .absoluteAngles ||
      profile.controlMode == .velocity ||
      profile.controlMode == .directionalFrames else {
      protocolStatus = "需要可驱动 profile"
      return
    }
    guard profile.canDrive else {
      protocolStatus = "ProtocolProfile.json 缺少模板或编码"
      return
    }
    guard profile.allowsFirmware("1.0.288") else {
      firmwareStatus = "固件不在白名单"
      return
    }

    controller = GimbalController(settings: currentSettings())
    isRunning = true
    isTestingMotion = false
    resetMotionStats()
    cameraStatus = "连接中"
    firmwareStatus = "1.0.288"
    protocolStatus = profile.controlMode == .directionalFrames ? "实验性方向重放" : "已验证"
    lastDirectionalSendTime = 0
    lastDirectionalCommand = nil
    calibrationDeadline = ProcessInfo.processInfo.systemUptime + 3
    airPodsStatus = "3 秒后校准，请正视前方"

    luna.connect(host: cameraHost, port: UInt16(cameraPort), profile: profile) { [weak self] status in
      Task { @MainActor in self?.cameraStatus = status }
    }
    motion.start()
  }

  func testAirPods() {
    controller = GimbalController(settings: currentSettings())
    isRunning = false
    isTestingMotion = true
    calibrationDeadline = nil
    resetMotionStats()
    cameraStatus = "仅测试耳机"
    motion.start()
  }

  func connectReplay() {
    guard profile.controlMode == .directionalFrames, profile.canDrive else {
      protocolStatus = "重放测试需要 directionalFrames profile"
      return
    }
    guard profile.allowsFirmware("1.0.288") else {
      firmwareStatus = "固件不在白名单"
      return
    }

    cameraStatus = "连接中"
    firmwareStatus = "1.0.288"
    protocolStatus = "抓包帧重放"
    isReplayConnected = true
    luna.connect(host: cameraHost, port: UInt16(cameraPort), profile: profile) { [weak self] status in
      Task { @MainActor in self?.cameraStatus = status }
    }
  }

  func replay(_ direction: String) {
    guard isReplayConnected else {
      connectReplay()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
        self?.replay(direction)
      }
      return
    }

    do {
      try luna.sendWhenReady(.rawFrame(name: direction))
      cameraStatus = "已发送 \(direction)"
    } catch {
      cameraStatus = "重放失败"
    }
  }

  func stop(reason: String) {
    guard isRunning || isTestingMotion || isReplayConnected else { return }
    isRunning = false
    isTestingMotion = false
    isReplayConnected = false
    lastDirectionalCommand = nil
    lastDirectionalSendTime = 0
    calibrationDeadline = nil
    motion.stop()
    luna.stopAndDisconnect()
    cameraStatus = reason
  }

  private func handle(sample: HeadPoseSample) {
    guard isRunning || isTestingMotion else { return }
    latestSample = sample
    updateMotionStats(sample)
    let now = ProcessInfo.processInfo.systemUptime

    if controller.neutralAttitude == nil {
      if let calibrationDeadline {
        let remaining = calibrationDeadline - now
        guard remaining <= 0 else {
          airPodsStatus = "\(Int(ceil(remaining))) 秒后校准"
          return
        }
        self.calibrationDeadline = nil
      }
      controller.calibrate(with: sample)
      airPodsStatus = "已校准"
      try? luna.send(.stop)
      return
    }

    controller.settings = currentSettings()
    let pose = PoseMath.relativePose(neutral: controller.neutralAttitude!, current: sample.attitude)
    yawText = format(pose.yaw)
    pitchText = format(pose.pitch)

    guard isRunning else { return }

    let command: LunaGimbalCommand?
    switch profile.controlMode {
    case .absoluteAngles:
      command = controller.command(for: sample, now: now)
    case .velocity:
      command = controller.velocityCommand(for: sample, now: now)
    case .directionalFrames:
      command = directionalReplayCommand(for: pose, now: now)
    default:
      command = .stop
    }
    guard let command else { return }
    if case let .absolute(angles) = command {
      panText = format(angles.pan)
      tiltText = format(angles.tilt)
    }

    do {
      try luna.send(command)
    } catch {
      stop(reason: "发送失败")
    }
  }

  private func currentSettings() -> ControlSettings {
    ControlSettings(
      panGain: panGain,
      tiltGain: tiltGain,
      smoothingTimeConstant: smoothingMs / 1000
    )
  }

  private func directionalReplayCommand(for pose: RelativeHeadPose, now: TimeInterval) -> LunaGimbalCommand? {
    let deadzone = currentSettings().deadzone.degrees
    let yaw = pose.yaw.degrees * panGain
    let pitch = pose.pitch.degrees * tiltGain
    let direction: String?

    if max(abs(yaw), abs(pitch)) < deadzone {
      direction = nil
    } else if abs(yaw) >= abs(pitch) {
      direction = yaw > 0 ? "right" : "left"
    } else {
      direction = pitch > 0 ? "up" : "down"
    }

    panText = direction == nil ? "停止" : (direction ?? "")
    tiltText = "方向重放"

    if direction == nil {
      guard lastDirectionalCommand != nil else { return nil }
      lastDirectionalCommand = nil
      lastDirectionalSendTime = now
      return .stop
    }

    guard now - lastDirectionalSendTime >= 0.25 else { return nil }
    lastDirectionalSendTime = now
    lastDirectionalCommand = direction
    return .rawFrame(name: direction!)
  }

  private func loadProfile() {
    guard let url = Bundle.main.url(forResource: "ProtocolProfile", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let loaded = try? ProfileLoader.load(from: data) else {
      protocolStatus = "未找到 ProtocolProfile.json"
      return
    }
    profile = loaded
    protocolStatus = loaded.canDrive ? "已验证" : "未验证"
  }

  private func resetMotionStats() {
    motionWindowStart = nil
    motionSamplesInWindow = 0
    motionRateText = "0 Hz"
  }

  private func updateMotionStats(_ sample: HeadPoseSample) {
    if motionWindowStart == nil {
      motionWindowStart = sample.timestamp
      motionSamplesInWindow = 0
    }

    motionSamplesInWindow += 1
    guard let start = motionWindowStart else { return }
    let elapsed = sample.timestamp - start
    if elapsed >= 1 {
      motionRateText = "\(Int(round(Double(motionSamplesInWindow) / elapsed))) Hz"
      motionWindowStart = sample.timestamp
      motionSamplesInWindow = 0
    }
  }

  private func format(_ angle: Angle) -> String {
    "\(angle.degrees.formatted(.number.precision(.fractionLength(1))))°"
  }
}
