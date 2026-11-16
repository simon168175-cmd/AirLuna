import Foundation
import simd

public struct GimbalController: Sendable {
  public private(set) var neutralAttitude: simd_quatd?
  public private(set) var estimatedAngles = GimbalAngles()
  public var settings: ControlSettings
  public var limits: GimbalLimits
  private var filter = LowPassFilter()
  private var lastCommandTimestamp: TimeInterval?

  public init(settings: ControlSettings = ControlSettings(), limits: GimbalLimits = GimbalLimits()) {
    self.settings = settings
    self.limits = limits
  }

  public mutating func calibrate(with sample: HeadPoseSample) {
    neutralAttitude = sample.attitude
    estimatedAngles = GimbalAngles()
    lastCommandTimestamp = nil
    filter.reset(to: .init(), timestamp: sample.timestamp)
  }

  public mutating func command(for sample: HeadPoseSample, now: TimeInterval) -> LunaGimbalCommand? {
    guard neutralAttitude != nil else { return .stop }
    guard now - sample.timestamp <= 0.100 else { return .stop }
    guard shouldEmitCommand(at: now) else { return nil }

    let filtered = filteredTarget(for: sample, now: now)
    estimatedAngles = filtered
    return .absolute(filtered)
  }

  public mutating func velocityCommand(for sample: HeadPoseSample, now: TimeInterval) -> LunaGimbalCommand? {
    guard neutralAttitude != nil else { return .stop }
    guard now - sample.timestamp <= 0.100 else { return .stop }
    guard shouldEmitCommand(at: now) else { return nil }

    let target = filteredTarget(for: sample, now: now)
    return velocityCommand(for: target, now: now)
  }

  public mutating func velocityCommand(for target: GimbalAngles, now: TimeInterval) -> LunaGimbalCommand {
    let panError = target.pan.radians - estimatedAngles.pan.radians
    let tiltError = target.tilt.radians - estimatedAngles.tilt.radians
    let gain = 4.0
    let maxSpeed = settings.maxSpeed.radians
    let panRate = min(max(panError * gain, -maxSpeed), maxSpeed)
    let tiltRate = min(max(tiltError * gain, -maxSpeed), maxSpeed)
    estimatedAngles.pan = Angle(radians: estimatedAngles.pan.radians + panRate / settings.commandRateHz)
      .clamped(to: limits.pan)
    estimatedAngles.tilt = Angle(radians: estimatedAngles.tilt.radians + tiltRate / settings.commandRateHz)
      .clamped(to: limits.tilt)
    lastCommandTimestamp = now
    return .velocity(panRate: Angle(radians: panRate), tiltRate: Angle(radians: tiltRate))
  }

  private func shouldEmitCommand(at now: TimeInterval) -> Bool {
    guard let lastCommandTimestamp else { return true }
    return now - lastCommandTimestamp >= 1 / settings.commandRateHz
  }

  private mutating func filteredTarget(for sample: HeadPoseSample, now: TimeInterval) -> GimbalAngles {
    let neutralAttitude = neutralAttitude!
    let pose = PoseMath.relativePose(neutral: neutralAttitude, current: sample.attitude)
    let target = PoseMath.targetAngles(pose: pose, settings: settings, limits: limits)
    let filtered = filter.update(
      target: target,
      timestamp: sample.timestamp,
      timeConstant: settings.smoothingTimeConstant
    )
    lastCommandTimestamp = now
    return filtered
  }
}
