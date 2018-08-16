import Foundation

public extension Array where Element == IndexPath {
    init(section: Int, start: Int, count: Int) {
        var paths = [IndexPath]()
        
        for i in start..<start + count {
            paths.append(IndexPath(row: i, section: section))
        }
        
        self = paths
    }
}
