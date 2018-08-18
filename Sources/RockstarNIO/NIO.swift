@_exported import NIO
@_exported import Rockstar

extension Future {
    public func makeNIO(on loop: EventLoop) -> EventLoopFuture<FutureValue> {
        let app: EventLoopPromise<FutureValue> = loop.newPromise()
        
        self.then(app.succeed).catch(app.fail)
        
        return app.futureResult
    }
}

extension EventLoopFuture {
    public func makeRockstar() -> Future<T> {
        let promise = Promise<T>()
        
        self.whenSuccess(promise.complete)
        self.whenFailure(promise.fail)
        
        return promise.future
    }
}

extension Future
