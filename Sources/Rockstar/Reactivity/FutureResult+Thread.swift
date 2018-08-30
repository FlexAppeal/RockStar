import Dispatch

extension Future {
    /// Switches to a new thread before continueing async processing
    ///
    /// This is especially useful for UIKit operations on iOS where the main thread
    /// is required for GUI changes.
    public func switchThread(to thread: AnyThread) -> Future<FutureValue> {
        let promise = Promise<FutureValue>(onCancel: self.cancel)
        
        self.onCompletion { result in
            DispatchQueue.main.async {
                promise.fulfill(result)
            }
        }
        
        promise.onCancel(run: self.cancel)
        return promise.future
    }
}

extension ReadStream {
    /// Switches to a new thread before continueing async processing
    ///
    /// This is especially useful for UIKit operations on iOS where the main thread
    /// is required for GUI changes.
    public func switchThread(to thread: AnyThread) -> ReadStream<FutureValue> {
        let writeStream = WriteStream<FutureValue>()
        
        self.onCompletion { result in
            DispatchQueue.main.async {
                writeStream.write(result)
            }
        }
        
        writeStream.onCancel(run: self.cancel)
        return writeStream.listener
    }
}
