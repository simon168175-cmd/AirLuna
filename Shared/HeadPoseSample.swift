import Foundation
import simd

public struct HeadPoseSample: Equatable, Sendable {
  public var timestamp: TimeInterval
  public var attitude: simd_quatd

  public init(timestamp: TimeInterval, attitude: simd_quatd) {
    self.timestamp = timestamp
    self.attitude = attitude.normalized
  }
}
