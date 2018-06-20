extension Future where FutureValue == String {
    @discardableResult
    public func write<O: AnyObject & TextualElement>(to type: O) -> Future<RichText> {
        return self.map(RichText.init).write(to: type, atKeyPath: \O.richText)
    }
}
