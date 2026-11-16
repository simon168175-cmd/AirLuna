import Foundation

public struct Angle: Equatable, Sendable {
  public var radians: Double

  public init(radians: Double) {
    self.radians = radians
  }

  public init(degrees: Double) {
    self.radians = degrees * .pi / 180
  }

  public var degrees: Double {
    radians * 180 / .pi
  }

  public func clamped(to range: ClosedRange<Angle>) -> Angle {
    Angle(radians: min(max(radians, range.lowerBound.radians), range.upperBound.radians))
  }
}

extension Angle: Comparable {
  public static func < (lhs: Angle, rhs: Angle) -> Bool {
    lhs.radians < rhs.radians
  }
}

public extension Double {
  var degrees: Angle { Angle(degrees: self) }
  var radiansAngle: Angle { Angle(radians: self) }
}
