import Foundation

public struct LunaFrameEncoder: Sendable {
  public var profile: LunaProtocolProfile

  public init(profile: LunaProtocolProfile) {
    self.profile = profile
  }

  public func frame(for command: LunaGimbalCommand) throws -> Data {
    try frames(for: command).last ?? Data()
  }

  public func frames(for command: LunaGimbalCommand) throws -> [Data] {
    guard profile.canDrive else { throw ProtocolProfileError.unverifiedProfile }

    switch command {
    case .stop:
      guard !profile.stopFrameHex.isEmpty else { throw ProtocolProfileError.missingFrame }
      return [try HexBytes.decode(profile.stopFrameHex)]
    case let .rawFrame(name):
      guard profile.controlMode == .directionalFrames else { throw ProtocolProfileError.unsupportedCommand }
      if let sequence = profile.directionFrameSequencesHex[name], !sequence.isEmpty {
        return try sequence.map(HexBytes.decode)
      }
      guard let hex = profile.directionFramesHex[name], !hex.isEmpty else {
        throw ProtocolProfileError.missingFrame
      }
      return [try HexBytes.decode(hex)]
    case let .absolute(angles):
      guard profile.controlMode == .absoluteAngles else { throw ProtocolProfileError.unsupportedCommand }
      guard let hex = profile.absoluteFrameTemplateHex, !hex.isEmpty else { throw ProtocolProfileError.missingFrame }
      guard let encoding = profile.absoluteEncoding else { throw ProtocolProfileError.missingEncoding }
      var frame = try HexBytes.decode(hex)
      try patch(angles, in: &frame, using: encoding)
      return [frame]
    case let .velocity(panRate, tiltRate):
      guard profile.controlMode == .velocity else { throw ProtocolProfileError.unsupportedCommand }
      guard let hex = profile.velocityFrameTemplateHex, !hex.isEmpty else { throw ProtocolProfileError.missingFrame }
      guard let encoding = profile.velocityEncoding else { throw ProtocolProfileError.missingEncoding }
      var frame = try HexBytes.decode(hex)
      try patch(
        GimbalAngles(pan: panRate, tilt: tiltRate),
        in: &frame,
        using: encoding
      )
      return [frame]
    }
  }

  private func patch(_ angles: GimbalAngles, in data: inout Data, using encoding: FrameValueEncoding) throws {
    try patch(angles.pan.degrees, at: encoding.panOffset, in: &data, using: encoding)
    try patch(angles.tilt.degrees, at: encoding.tiltOffset, in: &data, using: encoding)
  }

  private func patch(_ value: Double, at offset: Int, in data: inout Data, using encoding: FrameValueEncoding) throws {
    guard offset >= 0, offset + 1 < data.count else { throw ProtocolProfileError.frameTooShort }
    let scaled = Int(round(value * encoding.scale))
    let clamped = Int16(min(max(scaled, Int(Int16.min)), Int(Int16.max)))
    let raw = UInt16(bitPattern: clamped)
    switch encoding.byteOrder {
    case .littleEndian:
      data[offset] = UInt8(raw & 0xff)
      data[offset + 1] = UInt8((raw >> 8) & 0xff)
    case .bigEndian:
      data[offset] = UInt8((raw >> 8) & 0xff)
      data[offset + 1] = UInt8(raw & 0xff)
    }
  }
}
