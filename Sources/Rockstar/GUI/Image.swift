public struct ImageFile {
    public private(set) var data: Data
    public private(set) var mediaType: MediaType
    
    public init(jpeg data: Data) {
        self.data = data
        self.mediaType = .jpeg
    }
}
