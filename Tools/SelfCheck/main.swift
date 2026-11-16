import AirLunaCore
import Foundation
import simd

func approx(_ value: Double, _ expected: Double, _ tolerance: Double = 0.5) {
  precondition(abs(value - expected) <= tolerance, "expected \(expected), got \(value)")
}

let neutral = simd_quatd(angle: 0, axis: SIMD3<Double>(0, 1, 0))
let current = simd_quatd(angle: -.pi / 6, axis: SIMD3<Double>(0, 1, 0))
  * simd_quatd(angle: .pi / 9, axis: SIMD3<Double>(1, 0, 0))
let pose = PoseMath.relativePose(neutral: neutral, current: current)
approx(pose.yaw.degrees, 30)
approx(pose.pitch.degrees, 20)

let settings = ControlSettings(deadzone: Angle(degrees: 1.5))
let tiny = PoseMath.targetAngles(
  pose: RelativeHeadPose(yaw: Angle(degrees: 1), pitch: Angle(degrees: -1)),
  settings: settings
)
approx(tiny.pan.degrees, 0, 0.001)
approx(tiny.tilt.degrees, 0, 0.001)

let limited = PoseMath.targetAngles(
  pose: RelativeHeadPose(yaw: Angle(degrees: 500), pitch: Angle(degrees: -500)),
  settings: settings
)
approx(limited.pan.degrees, 230, 0.001)
approx(limited.tilt.degrees, -52, 0.001)

var controller = GimbalController(settings: ControlSettings(commandRateHz: 30))
let sample0 = HeadPoseSample(timestamp: 1, attitude: neutral)
controller.calibrate(with: sample0)
let stale = HeadPoseSample(timestamp: 1, attitude: current)
precondition(controller.command(for: stale, now: 1.2) == .stop)

let profile = LunaProtocolProfile()
precondition(!profile.canDrive)
precondition(profile.allowsFirmware("1.0.288"))
precondition(!profile.allowsFirmware("1.0.289"))

let frame = try HexBytes.decode("aa bb:0c-01")
precondition(HexBytes.encode(frame) == "aabb0c01")

print("AirLunaCore self-check passed")
