public struct GimbalLimits: Equatable, Sendable {
  public var pan: ClosedRange<Angle>
  public var tilt: ClosedRange<Angle>

  public init(
    pan: ClosedRange<Angle> = Angle(degrees: -52)...Angle(degrees: 230),
    tilt: ClosedRange<Angle> = Angle(degrees: -52)...Angle(degrees: 115)
  ) {
    self.pan = pan
    self.tilt = tilt
  }
}
