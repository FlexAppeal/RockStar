# Localization

## Features

- Literal translation
- Number formatting options
- Pluralization
- Date formatting

## Goals

- Compile-time safety. Find bugs before running/deploying
- Little boilerplate code
- Adding new languages with guarantees every String is translated
- Switching languages doesn't require manually changing all views

## Examples

```swift
struct Phrases: Decodable {
	let welcomeMessage: String
}

typealias MyTranslator = Translator<Phrases>

let englishGB = Phrases(
	welcomeMessage: "Welcome to my app!"
)

let dutch = Phrases(
	welcomeMessage: "Welkom in mijn app!"
)

let german: Data = ... // File reading

MyTranslator.register(englishGB, for: .enGB)
MyTranslator.register(dutch, for: .nl)
try MyTranslator.register(fromJSON: german, for: .de)
```

```swift
let label = UILabel()
let welcome = MyTranslator.translation(of: \.welcomeMessage)
label.text = welcome
```

```swift
let label = UILabel()
MyTranslator.apply(translationOf: \.welcomeMessage, to: label)
```

```swift
enum Progress {
	var current: Double
	var max: Double

	var percentage: Double {
		return (current / max) * 100
	}
}

struct Translation<T> {
	let mapper: (T) -> (String)

	init(_ mapper: (T) -> (String)) {
		self.mapper = mapper
	}

	func translate(_ t: T) {
		return mapper(t)
	}
}

struct ComplexPhrases {
	let completionStatus: Translation<Progress>
}

let english = ComplexPhrases(
	completionStatus: { progress in
		return "You did \(progress.percentage) of the work"
	}
)

let dutch = ComplexPhrases(
	completionStatus: { progress in
		return "Je hebt al \(progress.percentage)% gedaan"
	}
)
```
