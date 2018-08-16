import Foundation

internal extension Array where Element == UInt8 {
    /// The 12 bytes represented as 24-character hex-string
    var lowerHexString: String {
        var data = Data()
        data.reserveCapacity(self.count * 2)
        
        for byte in self {
            data.append(lowerRadix16table[Int(byte / 16)])
            data.append(lowerRadix16table[Int(byte % 16)])
        }
        
        return String(data: data, encoding: .utf8)!
    }
    
    var upperHexString: String {
        var data = Data()
        data.reserveCapacity(self.count * 2)
        
        for byte in self {
            data.append(upperRadix16table[Int(byte / 16)])
            data.append(upperRadix16table[Int(byte % 16)])
        }
        
        return String(data: data, encoding: .utf8)!
    }
}

extension String {
    var hexToBytes: [UInt8]? {
        var bytes = [UInt8]()
        
        let utf8 = [UInt8](self.utf8)
        bytes.reserveCapacity(utf8.count / 2)
        
        var index = 0
        let characterCount = utf8.count
        
        while index &+ 1 < characterCount {
            guard let upper = utf8[index].hexDecoded(), let lower = utf8[index &+ 1].hexDecoded() else {
                return nil
            }
            
            bytes.append((upper << 4) | lower)
            index = index &+ 2
        }
        
        if index < characterCount {
            guard let lower = utf8[index].hexDecoded() else {
                return nil
            }
            
            bytes.append(lower)
        }
        
        return bytes
    }
}

fileprivate let lowerRadix16table: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46]
fileprivate let upperRadix16table: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66]

fileprivate extension UInt8 {
    func hexDecoded() -> UInt8? {
        if self >= 0x30 && self <= 0x39 {
            return self &- 0x30
        } else if self >= 0x41 && self <= 0x46 {
            return self &- UInt8.lowercasedOffset
        } else if self >= 0x61 && self <= 0x66 {
            return self &- UInt8.uppercasedOffset
        }
        
        return nil
    }
    
    static let lowercasedOffset: UInt8 = 0x41 &- 10
    static let uppercasedOffset: UInt8 = 0x61 &- 10
}
