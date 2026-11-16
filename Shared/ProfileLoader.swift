import Foundation

public enum ProfileLoader {
  public static func load(from data: Data) throws -> LunaProtocolProfile {
    try JSONDecoder().decode(LunaProtocolProfile.self, from: data)
  }
}
