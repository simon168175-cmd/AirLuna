import Foundation

public struct ControlSettings: Equatable, Sendable {
  public var panGain: Double
  public var tiltGain: Double
  public var deadzone: Angle
  public var smoothingTimeConstant: TimeInterval
  public var commandRateHz: Double
  public var maxSpeed: Angle

  public init(
    panGain: Double = 1.0,
    tiltGain: Double = 1.0,
    deadzone: Angle = Angle(degrees: 1.5),
    smoothingTimeConstant: TimeInterval = 0.030,
    commandRateHz: Double = 30,
    maxSpeed: Angle = Angle(degrees: 120)
  ) {
    self.panGain = panGain
    self.tiltGain = tiltGain
    self.deadzone = deadzone
    self.smoothingTimeConstant = smoothingTimeConstant
    self.commandRateHz = commandRateHz
    self.maxSpeed = maxSpeed
  }
}
