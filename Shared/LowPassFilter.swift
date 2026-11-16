import Foundation

public struct LowPassFilter: Equatable, Sendable {
  private var lastTimestamp: TimeInterval?
  private var lastValue: GimbalAngles?

  public init() {}

  public mutating func reset(to value: GimbalAngles? = nil, timestamp: TimeInterval? = nil) {
    lastValue = value
    lastTimestamp = timestamp
  }

  public mutating func update(
    target: GimbalAngles,
    timestamp: TimeInterval,
    timeConstant: TimeInterval
  ) -> GimbalAngles {
    guard let lastValue, let lastTimestamp, timeConstant > 0 else {
      self.lastValue = target
      self.lastTimestamp = timestamp
      return target
    }

    let dt = max(0, timestamp - lastTimestamp)
    let alpha = dt / (timeConstant + dt)
    let filtered = GimbalAngles(
      pan: blend(lastValue.pan, target.pan, alpha: alpha),
      tilt: blend(lastValue.tilt, target.tilt, alpha: alpha)
    )
    self.lastValue = filtered
    self.lastTimestamp = timestamp
    return filtered
  }

  private func blend(_ current: Angle, _ target: Angle, alpha: Double) -> Angle {
    Angle(radians: current.radians + (target.radians - current.radians) * min(max(alpha, 0), 1))
  }
}
