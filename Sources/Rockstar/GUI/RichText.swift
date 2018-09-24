public enum TextAlignment {
    case left, center, right
}

public struct TextFont {
    public enum Representation {
        case bold, italic, normal
    }
    
    public var representation: Representation
    public var name: String?
    public var size: Float
    public var underlined: Bool
    
    public init(named name: String? = nil, size: Float) {
        self.name = name
        self.size = size
        self.representation = .normal
        self.underlined = false
    }
}

public enum RichTextAttribute {
    case font(TextFont)
    case centered
    case color(Color)
}

public struct RangedRichTextAttributes {
    public var attribute: RichTextAttribute
    public fileprivate(set) var from: Int
    public fileprivate(set) var to: Int
    
    var rangeIsEmpty: Bool { return to < from }
    
    func affects(characterAt index: Int) -> Bool {
        return index >= from && index <= to
    }
    
    fileprivate mutating func popCharacter(at index: Int) {
        assert(affects(characterAt: index), "A character was popped from a range that didn't affect this character")
        
        to = to &- 1
    }
}

public struct RichCharacter {
    public let bold: Bool
    public let italic: Bool
    public let underlined: Bool
    public let color: Color?
    
    internal init(attributes: [RichTextAttribute]) {
        var bold = false
        var italic = false
        var underlined = false
        var color: Color?
        var centered = false
        
        for attribute in attributes {
            switch attribute {
            case .font(let font):
                if font.underlined {
                    underlined = true
                }
                
                switch font.representation {
                case .bold:
                    bold = true
                case .italic:
                    italic = true
                case .normal:
                    italic = false
                    bold = false
                }
            case .color(let foundColor):
                color = foundColor
            case .centered:
                centered = true
            }
        }
        
        self.bold = bold
        self.italic = italic
        self.underlined = underlined
        self.color = color
    }
}

public struct RichText: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    private var _string: String
    
    /// Setting this directly removes all attributes
    public var string: String {
        get {
            return _string
        }
        set {
            _string = newValue
            self.textAttributes = []
        }
    }
    
    public var alignment: TextAlignment = .left
    public fileprivate(set) var textAttributes = [RangedRichTextAttributes]()
    
    public init(stringLiteral value: String) {
        self._string = value
    }
    
    public init(string: String, attributes: [RichTextAttribute] = []) {
        self._string = string
        
        for attribute in attributes {
            self.apply(attribute: attribute, inRange: 0..<string.count)
        }
    }
    
    public func attributes(at index: Int) -> RichCharacter {
        let textAttributes = self.textAttributes.compactMap { attribute in
            return attribute.affects(characterAt: index) ? attribute.attribute : nil
        }
        
        return RichCharacter(attributes: textAttributes)
    }
    
    public mutating func remove(at index: Int) {
        _string.remove(at: String.Index(encodedOffset: index))
        var removableIndices = [Int]()
        
        for i in 0..<textAttributes.count where textAttributes[i].affects(characterAt: index) {
            textAttributes[i].popCharacter(at: index)
            
            if textAttributes[i].rangeIsEmpty {
                removableIndices.append(i)
            }
        }
        
        for index in removableIndices {
            self.textAttributes.remove(at: index)
        }
    }
    
    public mutating func append(_ string: String) {
        _string += string
    }
    
    public mutating func apply(attribute: RichTextAttribute, inRange range: Range<Int>? = nil) {
        guard self.string.count >= 1 else {
            return
        }
        
        let range = range ?? 0..<self.string.count
        
        assert(range.lowerBound >= 0, "The range starts at a negative offset")
        
        /// TODO: Fail gracefully?
        assert(range.upperBound <= _string.count, "Range exceeds the RichText characters count")
        
        self.textAttributes.append(RangedRichTextAttributes(
            attribute: attribute,
            from: range.lowerBound,
            to: range.upperBound
        ))
    }
    
    public mutating func apply(attributes: RichTextAttribute..., inRange range: Range<Int>? = nil) {
        for attribute in attributes {
            self.apply(attribute: attribute, inRange: range)
        }
    }
    
    public func applying(attribute: RichTextAttribute, inRange range: Range<Int>? = nil) -> RichText {
        var me = self
        me.apply(attribute: attribute, inRange: range)
        return me
    }
    
    public func applying(attributes: RichTextAttribute..., inRange range: Range<Int>? = nil) -> RichText {
        var me = self
        
        for attribute in attributes {
            me.apply(attribute: attribute, inRange: range)
        }
        
        return me
    }
    
    public mutating func apply(font: TextFont, inRange range: Range<Int>? = nil) {
        let range = range ?? 0..<self.string.count &- 1
        
        self.apply(attribute: .font(font), inRange: range)
    }
}

public func +(lhs: RichText, rhs: RichText) -> RichText {
    var lhs = lhs
    let offset = lhs.string.count
    lhs.append(rhs.string)
    
    let rhsAttributes = rhs.textAttributes.map { attribute -> RangedRichTextAttributes in
        var attribute = attribute
        attribute.from += offset
        attribute.to += offset
        return attribute
    }
    
    lhs.textAttributes += rhsAttributes
    return lhs
}
