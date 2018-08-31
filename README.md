# Rockstar

[![Version](https://img.shields.io/cocoapods/v/Rockstar.svg?style=flat)](https://cocoapods.org/pods/Rockstar)
[![License](https://img.shields.io/cocoapods/l/Rockstar.svg?style=flat)](https://cocoapods.org/pods/Rockstar)

RockStar is a Swift framework for frontend programming in iOS 10+, macOS 10.12+ and Linux.

RockStar is split up into a few modules:

<!-- - [Services (dependency inversion)](docs/dependency-inversion,md) -->
- Services
- [Reactivity](docs/reactivity/concepts.md)
- Helpers
    - NSURLSession services
    - Logging
    - Runtime analytics
    - Testing
<!-- - Helpers -->
    <!-- - [NSURLSession services](docs/services/url-session.md)
    - [Logging](docs/services/logging.md)
    - [Runtime Analytics](docs/services/runtime-analytics.md) -->

<!-- - [Testing](docs/testing.md) -->

## Example

```swift
index.map { index in
    return pages[index]
}.bind(to: pageView.renderedPage) // Changes the rendered page when the index changes

navBar.next.onClick.then { index += 1 } // These operators also works on bindings
navBar.previous.onClick.then { index -= 1}

index.reduceMap(==, pages.count) // `true` for the last page
    .map(!) // `!lastPage``{"data":[]}
    .bind(to: navBar.next, atKeyPath: \.isUserInteractionEnabled) // disables on last page

index.reduceMap(==, 0) // `true` for the first page
    .map(!)
    .bind(to: navBar.previous, atKeyPath: \.isUserInteractionEnabled)

// new > old == forward
index.changeMap(>).map { forward -> AnimationDirection in
    if forward {
        return .rightToLeft
    } else {
        return .leftToRight
    }
}.then(currentPage.reload) // takes the animation direction as argument
```

## Installation

Rockstar is available through [CocoaPods](https://cocoapods.org) and [Swift Package Manager](https://swift.org/package-manager/).

Rockstar is in Alpha now, it will be developed a lot before a stable API has been achieved.
If you'd like to use Rockstar it's recommended to lock to minor versions for now.

```ruby
pod 'Rockstar'
```

or

```swift
.package(url: "https://github.com/RockStarSwift/RockStar.git", from: "0.3.0")
```
