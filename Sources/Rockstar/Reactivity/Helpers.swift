import Dispatch

extension Array where Element: ObservableProtocol {
    public func combined() -> Observable<[Element.FutureValue]> {
        var values = [Element.FutureValue]()
        var size = self.count
        values.reserveCapacity(size)
        let promise = Promise<[Element.FutureValue]>()
        
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
    
    public func streamed() -> Observable<Element.FutureValue> {
        let observer = Observer<Element.FutureValue>()
        
        for element in self {
            element.onCompletion(observer.emit)
        }
        
        return observer.observable
    }
}

extension Observable where FutureValue: Sequence {
    public func mapContents<NewValue>(
        _ transform: @escaping (FutureValue.Element) throws -> NewValue
    ) -> Observable<[NewValue]> {
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

public struct PromiseTimeout: Error {
    public init() {}
}

extension ObservableProtocol {
    public func switchThread(to thread: AnyThread) -> Observable<FutureValue> {
        let promise = Promise<FutureValue>()
        
        self.onCompletion { result in
            DispatchQueue.main.async {
                promise.fulfill(result)
            }
        }
        
        promise.onCancel(self.cancel)
        return promise.future
    }
    
    public func timeout(
        _ timeout: RSTimeout,
        throwing error: Error = PromiseTimeout()
    ) -> Observable<FutureValue> {
        let promise = Promise<FutureValue>()
        self.onCompletion(promise.fulfill)
        
        timeout.execute {
            promise.fail(error)
        }
        
        return promise.future
    }
}

extension Promise {
    @discardableResult
    public func timeout(
        _ timeout: RSTimeout,
        throwing error: Error = PromiseTimeout()
    ) -> Promise<FutureValue> {
        timeout.execute {
            self.fail(error)
        }
        
        return self
    }
}
