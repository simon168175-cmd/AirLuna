import XCTest
import simd
@testable import AirLunaCore

final class PoseMathTests: XCTestCase {
  func testRelativeYawAndPitch() {
    let neutral = simd_quatd(angle: 0, axis: SIMD3<Double>(0, 1, 0))
    let current = simd_quatd(angle: -.pi / 6, axis: SIMD3<Double>(0, 1, 0))
      * simd_quatd(angle: .pi / 9, axis: SIMD3<Double>(1, 0, 0))

    let pose = PoseMath.relativePose(neutral: neutral, current: current)

    XCTAssertEqual(pose.yaw.degrees, 30, accuracy: 0.5)
    XCTAssertEqual(pose.pitch.degrees, 20, accuracy: 0.5)
  }

  func testYawDoesNotJumpAtOneEightyDegrees() {
    let neutral = simd_quatd(angle: 0, axis: SIMD3<Double>(0, 1, 0))
    let left = PoseMath.relativePose(
      neutral: neutral,
      current: simd_quatd(angle: -.pi + 0.01, axis: SIMD3<Double>(0, 1, 0))
    )
    let right = PoseMath.relativePose(
      neutral: neutral,
      current: simd_quatd(angle: .pi - 0.01, axis: SIMD3<Double>(0, 1, 0))
    )

    XCTAssertEqual(abs(left.yaw.degrees), 179.4, accuracy: 0.2)
    XCTAssertEqual(abs(right.yaw.degrees), 179.4, accuracy: 0.2)
  }

  func testDeadzoneAndLimits() {
    let settings = ControlSettings(deadzone: Angle(degrees: 1.5))
    let tiny = PoseMath.targetAngles(
      pose: RelativeHeadPose(yaw: Angle(degrees: 1.0), pitch: Angle(degrees: -1.0)),
      settings: settings
    )
    XCTAssertEqual(tiny.pan.degrees, 0, accuracy: 0.001)
    XCTAssertEqual(tiny.tilt.degrees, 0, accuracy: 0.001)

    let limited = PoseMath.targetAngles(
      pose: RelativeHeadPose(yaw: Angle(degrees: 500), pitch: Angle(degrees: -500)),
      settings: settings
    )
    XCTAssertEqual(limited.pan.degrees, 230, accuracy: 0.001)
    XCTAssertEqual(limited.tilt.degrees, -52, accuracy: 0.001)
  }
}
