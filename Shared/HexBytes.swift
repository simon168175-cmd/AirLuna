import Foundation

public enum HexBytes {
  public static func decode(_ hex: String) throws -> Data {
    let compact = hex.filter { !$0.isWhitespace && $0 != ":" && $0 != "-" }
    guard compact.count.isMultiple(of: 2) else { throw HexBytesError.oddLength }

    var data = Data()
    var index = compact.startIndex
    while index < compact.endIndex {
      let next = compact.index(index, offsetBy: 2)
      guard let byte = UInt8(compact[index..<next], radix: 16) else {
        throw HexBytesError.invalidByte
      }
      data.append(byte)
      index = next
    }
    return data
  }

  public static func encode(_ data: Data) -> String {
    data.map { String(format: "%02x", $0) }.joined()
  }
}

public enum HexBytesError: Error, Equatable {
  case oddLength
  case invalidByte
}
