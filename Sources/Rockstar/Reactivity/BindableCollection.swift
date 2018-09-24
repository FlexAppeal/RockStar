//// TODO: `Collection` conformance || os(
//open class BindableCollection<E>: RSObject, Sequence {
//    var storage: [Binding<E>]
//    var objectIds: [ObjectIdentifier]
//    
//    public override init() {
//        self.storage = []
//        self.objectIds = []
//        
//        super.init()
//    }
//    
//    public var count: Int {
//        return storage.count
//    }
//    
//    public func append<C: BidirectionalCollection>(contentsOf collection: C) where C.Element == E {
//        for element in collection {
//            let binding = Binding(element)
//            let identifier = ObjectIdentifier(binding)
//            
//            storage.append(binding)
//            objectIds.append(identifier)
//        }
//    }
//    
//    public func insert<C: BidirectionalCollection>(contentsOf collection: C, at offset: Int) where C.Element == E {
//        var newBindings = [Binding<E>]()
//        var newObjectIds = [ObjectIdentifier]()
//        
//        for element in collection {
//            let binding = Binding(element)
//            let identifier = ObjectIdentifier(binding)
//            
//            newBindings.append(binding)
//            newObjectIds.append(identifier)
//        }
//        
//        storage.insert(contentsOf: newBindings, at: offset)
//        objectIds.insert(contentsOf: newObjectIds, at: offset)
//    }
//    
//    public subscript(index: Int) -> Binding<E> {
//        return self.storage[index]
//    }
//    
//    public func makeIterator() -> IndexingIterator<[Binding<E>]> {
//        return self.storage.makeIterator()
//    }
//    
//    public subscript(range: Range<Int>) -> BindableCollectionSlice<E> {
//        let slice = self.storage[range]
//        
//        return BindableCollectionSlice {
//            return slice.makeIterator()
//        }
//    }
//}
//
//// TODO: Conform to `Slice`/`Collection`
//public struct BindableCollectionSlice<E>: Sequence {
//    var iteratorFactory: () -> (IndexingIterator<ArraySlice<Binding<E>>>)
//    
//    public func makeIterator() -> IndexingIterator<ArraySlice<Binding<E>>> {
//        return iteratorFactory()
//    }
//}
