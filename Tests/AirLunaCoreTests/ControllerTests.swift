import XCTest
import simd
@testable import AirLunaCore

final class ControllerTests: XCTestCase {
  func testControllerStopsWithoutCalibration() {
    var controller = GimbalController()
    let sample = HeadPoseSample(timestamp: 1, attitude: simd_quatd(angle: 0, axis: SIMD3<Double>(0, 1, 0)))

    XCTAssertEqual(controller.command(for: sample, now: 1), .stop)
  }

  func testControllerStopsForStaleSample() {
    var controller = GimbalController()
    let neutral = HeadPoseSample(timestamp: 1, attitude: simd_quatd(angle: 0, axis: SIMD3<Double>(0, 1, 0)))
    controller.calibrate(with: neutral)

    let stale = HeadPoseSample(timestamp: 1, attitude: simd_quatd(angle: -.pi / 6, axis: SIMD3<Double>(0, 1, 0)))
    XCTAssertEqual(controller.command(for: stale, now: 1.2), .stop)
  }

  func testControllerEmitsAtConfiguredRate() {
    var controller = GimbalController(settings: ControlSettings(commandRateHz: 30))
    let neutral = HeadPoseSample(timestamp: 1, attitude: simd_quatd(angle: 0, axis: SIMD3<Double>(0, 1, 0)))
    controller.calibrate(with: neutral)

    let sample = HeadPoseSample(timestamp: 1.01, attitude: simd_quatd(angle: -.pi / 6, axis: SIMD3<Double>(0, 1, 0)))

    XCTAssertNotNil(controller.command(for: sample, now: 1.01))
    XCTAssertNil(controller.command(for: sample, now: 1.02))
    XCTAssertNotNil(controller.command(for: sample, now: 1.05))
  }

  func testLowPassFilterMovesTowardTarget() {
    var filter = LowPassFilter()
    _ = filter.update(
      target: GimbalAngles(pan: Angle(degrees: 0), tilt: Angle(degrees: 0)),
      timestamp: 1,
      timeConstant: 0.03
    )

    let filtered = filter.update(
      target: GimbalAngles(pan: Angle(degrees: 30), tilt: Angle(degrees: 0)),
      timestamp: 1.03,
      timeConstant: 0.03
    )

    XCTAssertGreaterThan(filtered.pan.degrees, 0)
    XCTAssertLessThan(filtered.pan.degrees, 30)
  }
}
