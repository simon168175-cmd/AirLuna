import Foundation
import simd

public struct RelativeHeadPose: Equatable, Sendable {
  public var yaw: Angle
  public var pitch: Angle

  public init(yaw: Angle, pitch: Angle) {
    self.yaw = yaw
    self.pitch = pitch
  }
}

public enum PoseMath {
  public static func relativePose(neutral: simd_quatd, current: simd_quatd) -> RelativeHeadPose {
    let relative = (neutral.inverse * current).normalized
    let forward = relative.act(SIMD3<Double>(0, 0, -1))
    let yaw = atan2(forward.x, -forward.z)
    let pitch = atan2(forward.y, hypot(forward.x, forward.z))
    return RelativeHeadPose(yaw: Angle(radians: yaw), pitch: Angle(radians: pitch))
  }

  public static func targetAngles(
    pose: RelativeHeadPose,
    settings: ControlSettings,
    limits: GimbalLimits = GimbalLimits()
  ) -> GimbalAngles {
    let pan = applyDeadzone(pose.yaw, deadzone: settings.deadzone).radians * settings.panGain
    let tilt = applyDeadzone(pose.pitch, deadzone: settings.deadzone).radians * settings.tiltGain
    return GimbalAngles(
      pan: Angle(radians: pan).clamped(to: limits.pan),
      tilt: Angle(radians: tilt).clamped(to: limits.tilt)
    )
  }

  public static func applyDeadzone(_ angle: Angle, deadzone: Angle) -> Angle {
    abs(angle.radians) < deadzone.radians ? Angle(radians: 0) : angle
  }
}
