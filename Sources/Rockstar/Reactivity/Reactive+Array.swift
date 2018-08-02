import Dispatch

extension Array {
    public func joined<T>(ordered: Bool = true) -> Future<[T]> where Element == Future<T> {
        if ordered {
            return _orderedJoin()
        } else {
            return _unorderedJoin()
        }
    }
    
    private func _orderedJoin<T>() -> Future<[T]> where Element == Future<T> {
        var values = [T]()
        values.reserveCapacity(self.count)
        var iterator = self.makeIterator()
        let promise = Promise<[T]>()
        var i = 0
        
        func next() {
            if let value = iterator.next() {
                value.onCompletion { value in
                    switch value {
                    case .cancelled:
                        promise.cancel()
                    case .failure(let error):
                        promise.fail(error)
                    case .success(let value):
                        values.append(value)
                        
                        next()
                    }
                }
            } else {
                promise.complete(values)
            }
        }
        
        next()
        
        return promise.future
    }
    
    private func _unorderedJoin<T>() -> Future<[T]> where Element == Future<T> {
        var values = [T]()
        var size = self.count
        values.reserveCapacity(size)
        let promise = Promise<[T]>()
        
        for element in self {
            element.onCompletion { value in
                switch value {
                case .cancelled:
                    promise.cancel()
                case .failure(let error):
                    promise.fail(error)
                case .success(let value):
                    values.append(value)
                }
                
                size = size &- 1
                if size == 0 {
                    promise.complete(values)
                }
            }
        }
        
        return promise.future
    }
    
    public func asyncMap<T, B>(_ function: @escaping (T) throws -> (B)) -> ReadStream<B> where Element == Future<T> {
        return self.streamed(sequentially: true).map(function)
    }
    
    /// TODO: Should the next element be streamed after flatMap returned successfully?
    public func asyncFlatMap<T, B>(_ function: @escaping (T) throws -> (Future<B>)) -> ReadStream<B> where Element == Future<T> {
        return self.streamed(sequentially: true).flatMap(function)
    }
    
    public func streamed<T>(sequentially: Bool) -> ReadStream<T> where Element == Future<T> {
        let writeStream = WriteStream<T>()
        
        if sequentially {
            var iterator = self.makeIterator()
            
            func next() {
                guard let future = iterator.next() else {
                    return
                }
                
                future.onCompletion(writeStream.write).always(run: next)
            }
            
            next()
        } else {
            for element in self {
                element.onCompletion(writeStream.write)
            }
        }
        
        return writeStream.listener
    }
}

extension Future {
    public func filteringNil<T>() -> Future<[T]> where FutureValue == [T?] {
        return self.map { array in
            return array.compactMap { $0 }
        }
    }
}

extension ReadStream where FutureValue: Sequence {
    public func mapContents<NewValue>(
        _ transform: @escaping (FutureValue.Element) throws -> NewValue
    ) -> ReadStream<[NewValue]> {
        return self.map { sequence in
            return try sequence.map(transform)
        }
    }
}

extension Future where FutureValue: Sequence {
    public func mapContents<NewValue>(
        _ transform: @escaping (FutureValue.Element) throws -> NewValue
    ) -> Future<[NewValue]> {
        return self.map { sequence in
            return try sequence.map(transform)
        }
    }
}

public struct AnyThread {
    enum ThreadType {
        case dispatch(DispatchQueue)
    }
    
    private let thread: ThreadType
    
    public func execute(_ closure: @escaping () -> ()) {
        switch thread {
        case .dispatch(let queue):
            queue.async(execute: closure)
        }
    }
    
    public func execute(after timeout: RSTimeInterval, _ closure: @escaping () -> ()) {
        switch thread {
        case .dispatch(let queue):
            let deadline = DispatchTime.now() + timeout.dispatch
            
            queue.asyncAfter(deadline: deadline, execute: closure)
        }
    }
    
    public static func dispatchQueue(_ queue: DispatchQueue) -> AnyThread {
        return AnyThread(thread: .dispatch(queue))
    }
}
