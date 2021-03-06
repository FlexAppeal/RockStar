import Dispatch

extension Future {
    /// Switches to a new thread before continueing async processing
    ///
    /// This is especially useful for UIKit operations on iOS where the main thread
    /// is required for GUI changes.
    public func switchThread(to thread: AnyThread) -> Future<FutureValue> {
        let promise = self.makePromise()
        
        self.onCompletion { result in
            thread.execute {
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
            thread.execute {
                writeStream.write(result)
            }
        }
        
        writeStream.onCancel(run: self.cancel)
        return writeStream.listener
    }
}
