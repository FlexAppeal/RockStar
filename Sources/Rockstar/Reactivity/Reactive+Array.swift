import Dispatch

extension Array {
    public func joined<T>() -> Future<[T]> where Element == Future<T> {
        var values = [T]()
        var size = self.count
        values.reserveCapacity(size)
        let promise = Promise<[T]>()
        
        promise.onCancel {
            /// TODO: Is this always a good idea?
            for future in self {
                future.cancel()
            }
        }
        
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
    
    public func streamed<T>(sequentially: Bool) -> OutputStream<T> where Element == Future<T> {
        let inputStream = InputStream<T>()
        
        if sequentially {
            var iterator = self.makeIterator()
            
            func next() {
                guard let future = iterator.next() else {
                    return
                }
                
                future.onCompletion(inputStream.write).always(next)
            }
            
            next()
        } else {
            for element in self {
                element.onCompletion(inputStream.write)
            }
        }
        
        return inputStream.listener
    }
}

extension OutputStream where FutureValue: Sequence {
    public func mapContents<NewValue>(
        _ transform: @escaping (FutureValue.Element) throws -> NewValue
    ) -> OutputStream<[NewValue]> {
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
