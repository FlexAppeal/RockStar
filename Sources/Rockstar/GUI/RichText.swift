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
    case color(Color)
}

public struct RangedRichTextAttributes {
    public var attribute: RichTextAttribute
    public let from: Int
    public private(set) var to: Int
    
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
            self.attributes = []
        }
    }
    
    public var alignment: TextAlignment = .left
    public private(set) var attributes = [RangedRichTextAttributes]()
    
    public init(stringLiteral value: String) {
        self._string = value
    }
    
    public init(string: String, attributes: [RichTextAttribute]) {
        self._string = string
        
        for attribute in attributes {
            self.apply(attribute: attribute, inRange: 0..<string.count)
        }
    }
    
    public func attributes(at index: Int) -> RichCharacter {
        let attributes = self.attributes.compactMap { attribute in
            return attribute.affects(characterAt: index) ? attribute.attribute : nil
        }
        
        return RichCharacter(attributes: attributes)
    }
    
    public mutating func remove(at index: Int) {
        _string.remove(at: String.Index(encodedOffset: index))
        var removableIndices = [Int]()
        
        for i in 0..<attributes.count where attributes[i].affects(characterAt: index) {
            attributes[i].popCharacter(at: index)
            
            if attributes[i].rangeIsEmpty {
                removableIndices.append(i)
            }
        }
        
        for index in removableIndices {
            self.attributes.remove(at: index)
        }
    }
    
    public mutating func append(_ string: String) {
        _string += string
    }
    
    public mutating func apply(attribute: RichTextAttribute, inRange range: Range<Int>) {
        assert(range.lowerBound >= 0, "The range starts at a negative offset")
        assert(range.upperBound < _string.count, "Range exceeds the RichText characters count")
        
        self.attributes.append(RangedRichTextAttributes(
            attribute: attribute,
            from: range.lowerBound,
            to: range.upperBound
        ))
    }
    
    public mutating func apply(font: TextFont, inRange range: Range<Int>) {
        self.apply(attribute: .font(font), inRange: range)
    }
}
