import Foundation

public struct GimbalAngles: Equatable, Sendable {
  public var pan: Angle
  public var tilt: Angle

  public init(pan: Angle = .init(degrees: 0), tilt: Angle = .init(degrees: 0)) {
    self.pan = pan
    self.tilt = tilt
  }
}

public enum LunaGimbalCommand: Equatable, Sendable {
  case stop
  case rawFrame(name: String)
  case absolute(GimbalAngles)
  case velocity(panRate: Angle, tiltRate: Angle)
}
