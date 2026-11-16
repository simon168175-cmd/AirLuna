import Foundation
import Network

final class LunaSession {
  private var connection: NWConnection?
  private var encoder = LunaFrameEncoder(profile: LunaProtocolProfile())
  private var status: ((String) -> Void)?
  private var isReady = false
  private let sequenceFrameSpacing = 0.05

  func connect(host: String, port: UInt16, profile: LunaProtocolProfile, status: @escaping (String) -> Void) {
    self.status = status
    self.encoder = LunaFrameEncoder(profile: profile)
    self.isReady = false

    let connection = NWConnection(
      host: NWEndpoint.Host(host),
      port: NWEndpoint.Port(rawValue: port)!,
      using: .tcp
    )
    self.connection = connection
    connection.stateUpdateHandler = { state in
      switch state {
      case .ready:
        self.isReady = true
        status("已连接")
      case .failed:
        self.isReady = false
        status("连接失败")
      case .cancelled:
        self.isReady = false
        status("已断开")
      default:
        break
      }
    }
    connection.start(queue: .global(qos: .userInteractive))
  }

  func send(_ command: LunaGimbalCommand) throws {
    let frames = try encoder.frames(for: command)
    for (index, frame) in frames.enumerated() {
      DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + Double(index) * sequenceFrameSpacing) { [weak self] in
        self?.connection?.send(content: frame, completion: .contentProcessed { error in
          if error != nil {
            self?.status?("发送失败")
          }
        })
      }
    }
  }

  func sendWhenReady(_ command: LunaGimbalCommand) throws {
    if isReady {
      try send(command)
    } else {
      DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.8) { [weak self] in
        try? self?.send(command)
      }
    }
  }

  func stopAndDisconnect() {
    if let frame = try? encoder.frame(for: .stop) {
      connection?.send(content: frame, completion: .contentProcessed { _ in })
    }
    connection?.cancel()
    connection = nil
  }
}
