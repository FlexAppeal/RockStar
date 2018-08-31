# Rockstar Reactiivty Concepts

Reactivity is separated into three main categories that interface cleanly.

- Promises & Futures
- Streams
- Bindings

Some other helper types are present but are reliant on the above. All of these types are generic.

## Promises & Futures

Promises are a type that can be used to emit a single Observation.
Futures are the other side of the promise API and can only add actions to events emited by the promise.

Actions are already available in a [wide array of features](promise-future.md).

## Streams

Streams are similar to promise & futures with the big difference being that notifications can be emitted more than once or not at all.
Cancel notifications are still present but may not influence the stream's lifetime as significantly as a promise would be affected.

Promise and WriteStream share a lot of APIs as do Futures and ReadStreams.

[More about Stream APIs here.](streams.md)

## Bindings

Bindings are literal values that are _not_ asynchronously received but are already present. Bindings are used to reduce internal state and improve the cleanliness of your code by responding to a change of a variable reactively rather than requiring the programmer to _proactively_ update the rest of the state in their logic and UI.

Bindings come in two primary forms:

- Binding
- ComputedBinding

A normal binding is a wrapper around a concrete value. Normal bindings can have their value mutated as you please at any time. ComputedBindings can not be manually mutated as they are derived from another type of Binding (normal or computed) and are not directly set.

They can not be manually created and must be created through the computational mapping of a (concrete) binding.

Both are subclasses from AnyBinding, and common functionality or generic logic between both types of bindings should make use of `AnyBinding<...>`

Bindings also share APIs with Futures and ReadStreams to improve the simplicity of your codebase. [More about binding APIs here](bindings.md)

## Observations

Observations are used in both promise/future notifications and stream notifications. An observation represents an asynchronous result. Observations exist in one of 3 states:

- A successful state with an expected value
- A failure state with an error
- A cancelled state

The cancelled state is used in Promises/Futures as a form of notification by a Future that it is no longer interested in the result. Promises can be configured to ignore this notification. A cancel notification is used to abort heavy operations such as network requests or CPU/GPU heavy operations.
