import Foundation

public struct LunaProtocolProfile: Codable, Equatable, Sendable {
  public enum ControlMode: String, Codable, Sendable {
    case unverified
    case directionalFrames
    case absoluteAngles
    case velocity
  }

  public var verifiedFirmware: String
  public var controlMode: ControlMode
  public var stopFrameHex: String
  public var directionFramesHex: [String: String]
  public var directionFrameSequencesHex: [String: [String]]
  public var absoluteFrameTemplateHex: String?
  public var velocityFrameTemplateHex: String?
  public var absoluteEncoding: FrameValueEncoding?
  public var velocityEncoding: FrameValueEncoding?

  public init(
    verifiedFirmware: String = "1.0.288",
    controlMode: ControlMode = .unverified,
    stopFrameHex: String = "",
    directionFramesHex: [String: String] = [:],
    directionFrameSequencesHex: [String: [String]] = [:],
    absoluteFrameTemplateHex: String? = nil,
    velocityFrameTemplateHex: String? = nil,
    absoluteEncoding: FrameValueEncoding? = nil,
    velocityEncoding: FrameValueEncoding? = nil
  ) {
    self.verifiedFirmware = verifiedFirmware
    self.controlMode = controlMode
    self.stopFrameHex = stopFrameHex
    self.directionFramesHex = directionFramesHex
    self.directionFrameSequencesHex = directionFrameSequencesHex
    self.absoluteFrameTemplateHex = absoluteFrameTemplateHex
    self.velocityFrameTemplateHex = velocityFrameTemplateHex
    self.absoluteEncoding = absoluteEncoding
    self.velocityEncoding = velocityEncoding
  }

  public var canDrive: Bool {
    switch controlMode {
    case .unverified:
      return false
    case .directionalFrames:
      return !stopFrameHex.isEmpty && (!directionFramesHex.isEmpty || !directionFrameSequencesHex.isEmpty)
    case .absoluteAngles:
      return !stopFrameHex.isEmpty && !(absoluteFrameTemplateHex ?? "").isEmpty && absoluteEncoding != nil
    case .velocity:
      return !stopFrameHex.isEmpty && !(velocityFrameTemplateHex ?? "").isEmpty && velocityEncoding != nil
    }
  }

  public func allowsFirmware(_ firmware: String) -> Bool {
    firmware == verifiedFirmware
  }
}

public enum ProtocolProfileError: Error, Equatable {
  case missingFrame
  case unsupportedCommand
  case unverifiedProfile
  case missingEncoding
  case frameTooShort
}

public struct FrameValueEncoding: Codable, Equatable, Sendable {
  public enum ByteOrder: String, Codable, Sendable {
    case littleEndian
    case bigEndian
  }

  public var panOffset: Int
  public var tiltOffset: Int
  public var scale: Double
  public var byteOrder: ByteOrder

  public init(
    panOffset: Int,
    tiltOffset: Int,
    scale: Double,
    byteOrder: ByteOrder = .littleEndian
  ) {
    self.panOffset = panOffset
    self.tiltOffset = tiltOffset
    self.scale = scale
    self.byteOrder = byteOrder
  }
}
