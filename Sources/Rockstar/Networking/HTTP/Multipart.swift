import Foundation

public protocol FormPart {
    var name: String { get }
    var filename: String? { get }
    var headers: HTTPHeaders { get }
    var data: Data { get }
}

public struct File {
    public let name: String
    public let type: MediaType
    public let data: Data
    
    public init(name: String, type: MediaType, data: Data) {
        self.name = name
        self.type = type
        self.data = data
    }
}

public struct MultipartFile: FormPart {
    public let name: String
    public let filename: String?
    public var headers: HTTPHeaders
    public let data: Data
    
    public init(named name: String, file: File) {
        self.name = name
        self.filename = file.name
        self.data = file.data
        self.headers = [
            "Content-Type": file.type.headerValue
        ]
    }
}

public struct MultipartForm {
    public let data: Data
    public let boundary: String
    
    init(data: Data, boundary: String) {
        self.data = data
        self.boundary = boundary
    }
    
    public var baseHeaders: HTTPHeaders {
        return [
            "Content-Type": "multipart/form-data; boundary=\(self.boundary)"
        ]
    }
}

extension Array where Element == FormPart {
    public func makeFormData() -> MultipartForm {
        let boundary = NSUUID().uuidString
        
        var body = Data()
        let bytes = self.reduce(0) { bytes, part in
            return bytes &+ 256 &+ part.data.count
        }
        
        body.reserveCapacity(bytes)
        
        let boundaryMark = "--\(boundary)\r\n".utf8
        let boundaryEnd = "--\(boundary)--\r\n".utf8
        
        for part in self {
            body.append(contentsOf: boundaryMark)
            
            var mainHeader = "Content-Disposition: form-data; name=\(part.name)"
            
            if let filename = part.filename {
                mainHeader += "; filename=\(filename)"
            }
            
            body.append(contentsOf: mainHeader.utf8)
            body.append(.carriageReturn)
            body.append(.newLine)
            
            body.append(part.headers.data)
            
            // End of headers
            body.append(contentsOf: "\r\n".utf8)
            
            body.append(part.data)
            body.append(contentsOf: "\r\n".utf8)
        }
        
        body.append(contentsOf: boundaryEnd)
        
        return MultipartForm(data: body, boundary: boundary)
    }
}
