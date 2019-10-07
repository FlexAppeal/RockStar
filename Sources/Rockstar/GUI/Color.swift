/// A platform agnostic Color type within the RGBA spectrum.
public struct Color {
    /// A representation of a Color with a 0.0-1.0 float based representation
    public struct FloatView {
        public var red: Float
        public var green: Float
        public var blue: Float
        public var alpha: Float
    }
    
    /// A representation of a Color with a 0-255 UInt8 based representation.
    ///
    /// Has less precision than the float view but exactly matches a hexadecimal string representation
    public struct ByteView {
        public var red: UInt8
        public var green: UInt8
        public var blue: UInt8
        public var alpha: UInt8
    }
    
    /// The float representation of this colour
    public var floatView: FloatView {
        get {
            return FloatView(
                red: Float(byteView.red) / 255,
                green: Float(byteView.green) / 255,
                blue: Float(byteView.blue) / 255,
                alpha: Float(byteView.alpha) / 255
            )
        }
        set {
            assert(newValue.red >= 0 && newValue.red <= 1, "Invalid floating point received for the red value")
            assert(newValue.green >= 0 && newValue.green <= 1, "Invalid floating point received for the green value")
            assert(newValue.blue >= 0 && newValue.blue <= 1, "Invalid floating point received for the blue value")
            assert(newValue.alpha >= 0 && newValue.alpha <= 1, "Invalid floating point received for the alpha value")
            
            self.byteView = ByteView(
                red: UInt8(newValue.red * 255),
                green: UInt8(newValue.green * 255),
                blue: UInt8(newValue.blue * 255),
                alpha: UInt8(newValue.alpha * 255)
            )
        }
    }
    
    /// The byte representation of this colour
    public var byteView: ByteView
    
    /// Creates a new Colour from a subset of floats with values in the 0.0-1.0 range
    public static func fromFloats(red: Float, green: Float, blue: Float, alpha: Float = 1.0) -> Color {
        assert(red > 0 && red <= 1, "Invalid floating point received for the red value")
        assert(green > 0 && green <= 1, "Invalid floating point received for the green value")
        assert(blue > 0 && blue <= 1, "Invalid floating point received for the blue value")
        assert(alpha > 0 && alpha <= 1, "Invalid floating point received for the alpha value")
        
        let view = ByteView(
            red: UInt8(red * 255),
            green: UInt8(green * 255),
            blue: UInt8(blue * 255),
            alpha: UInt8(alpha * 255)
        )
        
        return Color(byteView: view)
    }
    
    /// Creates a new Colour from RGB bytes and an optional alpha value.
    public static func fromBytes(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) -> Color {
        let view = ByteView(
            red: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
        
        return Color(byteView: view)
    }
}

extension Color {
    /// A fully transparent colour
    public static var clear: Color {
        return Color.fromBytes(red: 0, green: 0, blue: 0, alpha: 0)
    }
    
    /// Pure 0xFF0000 red
    public static var red: Color {
        return Color.fromBytes(red: 255, green: 0, blue: 0, alpha: 255)
    }
    
    /// Pure 0x00FF00 green
    public static var green: Color {
        return Color.fromBytes(red: 0, green: 255, blue: 0, alpha: 255)
    }
    
    /// Pure 0x0000FF blue
    public static var blue: Color {
        return Color.fromBytes(red: 0, green: 0, blue: 255, alpha: 255)
    }
    
    /// 0xFFFFFF white
    public static var white: Color {
        return Color.fromBytes(red: 255, green: 255, blue: 255, alpha: 255)
    }
    
    /// 0x000000 black
    public static var black: Color {
        return Color.fromBytes(red: 0, green: 0, blue: 0, alpha: 255)
    }
    
    /// The transparency as a float
    public var transparency: Float {
        get {
            return self.floatView.alpha
        }
        set {
            self.floatView.alpha = newValue
        }
    }
    
    /// Creates a new Colour from a hexadecimal RGB String.
    ///
    /// Allows a custom valuea for transparency.
    public init?(hex: String, transparency: UInt8 = .max) {
        var hex = hex
        
        if hex.first == "#" {
            hex.removeFirst()
        }
        
        guard let bytes = hex.hexToBytes, bytes.count == 3 else { return nil }
        
        self = Color.fromBytes(red: bytes[0], green: bytes[1], blue: bytes[2], alpha: transparency)
    }
}
