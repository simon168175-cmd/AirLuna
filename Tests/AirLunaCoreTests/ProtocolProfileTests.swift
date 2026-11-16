import XCTest
@testable import AirLunaCore

final class ProtocolProfileTests: XCTestCase {
  func testDefaultProfileCannotDrive() {
    let profile = LunaProtocolProfile()
    XCTAssertFalse(profile.canDrive)
    XCTAssertTrue(profile.allowsFirmware("1.0.288"))
    XCTAssertFalse(profile.allowsFirmware("1.0.289"))
  }

  func testHexBytesDecodeAndEncodeGoldenFrame() throws {
    let frame = try HexBytes.decode("aa bb:0c-01")
    XCTAssertEqual(HexBytes.encode(frame), "aabb0c01")
  }

  func testEncoderRefusesUnverifiedProfile() {
    let encoder = LunaFrameEncoder(profile: LunaProtocolProfile())

    XCTAssertThrowsError(try encoder.frame(for: .stop)) { error in
      XCTAssertEqual(error as? ProtocolProfileError, .unverifiedProfile)
    }
  }

  func testEncoderReturnsVerifiedStopFrame() throws {
    let profile = LunaProtocolProfile(
      controlMode: .absoluteAngles,
      stopFrameHex: "aa bb 00 00",
      absoluteFrameTemplateHex: "aa bb 00 00 00 00",
      absoluteEncoding: FrameValueEncoding(panOffset: 2, tiltOffset: 4, scale: 10)
    )
    let encoder = LunaFrameEncoder(profile: profile)

    XCTAssertEqual(HexBytes.encode(try encoder.frame(for: .stop)), "aabb0000")
    XCTAssertEqual(
      HexBytes.encode(try encoder.frame(for: .absolute(GimbalAngles()))),
      "aabb00000000"
    )
    XCTAssertEqual(
      HexBytes.encode(try encoder.frame(for: .absolute(GimbalAngles(
        pan: Angle(degrees: 12.3),
        tilt: Angle(degrees: -4.5)
      )))),
      "aabb7b00d3ff"
    )
  }

  func testEncoderReturnsDirectionalFrame() throws {
    let profile = LunaProtocolProfile(
      controlMode: .directionalFrames,
      stopFrameHex: "aa bb 00 00",
      directionFramesHex: ["left": "aa bb 10 01"]
    )
    let encoder = LunaFrameEncoder(profile: profile)

    XCTAssertEqual(
      HexBytes.encode(try encoder.frame(for: .rawFrame(name: "left"))),
      "aabb1001"
    )
  }

  func testEncoderReturnsDirectionalFrameSequence() throws {
    let profile = LunaProtocolProfile(
      controlMode: .directionalFrames,
      stopFrameHex: "aa bb 00 00",
      directionFrameSequencesHex: ["left": ["aa bb 10 01", "aa bb 00 00"]]
    )
    let encoder = LunaFrameEncoder(profile: profile)

    XCTAssertEqual(
      try encoder.frames(for: .rawFrame(name: "left")).map(HexBytes.encode),
      ["aabb1001", "aabb0000"]
    )
  }
}
