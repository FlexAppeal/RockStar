extension Future where FutureValue: RichTextRepresentable {
    @discardableResult
    public func write<O: AnyObject & RichTextConvertible>(to type: O) -> Future<RichText> {
        return self.map { $0.richText }.write(to: type, atKeyPath: \O.richText)
    }
}

public protocol RichTextRepresentable {
    var richText: RichText { get }
}

public protocol RichTextConvertible: RichTextRepresentable {
    var richText: RichText { get set }
}

extension RichText: RichTextConvertible {
    public var richText: RichText {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
}

extension String: RichTextConvertible {
    public var richText: RichText {
        get {
            return RichText(string: self)
        }
        set {
            self = newValue.string
        }
    }
}

extension RichTextRepresentable {
    public func fontSize(_ size: Float, inRange range: Range<Int>? = nil) -> RichText {
        return self.richText.applying(attribute: .font(TextFont(size: size)), inRange: range)
    }
    
    public func color(_ color: Color, inRange range: Range<Int>? = nil) -> RichText {
        return self.richText.applying(attribute: .color(color), inRange: range)
    }
}
