#if os(Linux)
public class RSObject {
    init() {}
}
#else
public typealias RSObject = NSObject
#endif
