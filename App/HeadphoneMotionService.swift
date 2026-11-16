import CoreMotion
import Foundation
import simd

final class HeadphoneMotionService {
  var onSample: ((HeadPoseSample) -> Void)?
  var onStatus: ((String) -> Void)?

  private let manager = CMHeadphoneMotionManager()
  private let queue = OperationQueue()

  init() {
    queue.name = "AirLunaHeadphoneMotion"
    queue.qualityOfService = .userInteractive
  }

  func start() {
    guard manager.isDeviceMotionAvailable else {
      onStatus?("耳机运动不可用")
      return
    }

    onStatus?("监听中")
    manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
      guard let self else { return }
      if error != nil {
        self.onStatus?("运动更新错误")
        return
      }
      guard let motion else { return }
      let q = motion.attitude.quaternion
      let attitude = simd_quatd(ix: q.x, iy: q.y, iz: q.z, r: q.w)
      self.onSample?(HeadPoseSample(
        timestamp: ProcessInfo.processInfo.systemUptime,
        attitude: attitude
      ))
    }
  }

  func stop() {
    manager.stopDeviceMotionUpdates()
    onStatus?("已停止")
  }
}
