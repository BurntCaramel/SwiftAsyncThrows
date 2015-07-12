# SwiftAsyncThrows

Using try and throws in Swift 2 with Asynchronous code.

## Swift 2 flavoured Result type:

```swift
enum Result<T> {
	case Success(T)
	case Error(ErrorType)
	
	init(_ value: T) {
		self = .Success(value)
	}
	
	init(doClosure: () throws -> T) {
		do {
			let value = try doClosure()
			self = .Success(value)
		}
		catch let error {
			self = .Error(error)
		}
		
	}
	
	func use() throws -> T {
		switch self {
		case .Success(let value):
			return value
		case .Error(let error):
			throw error
		}
	}
}
```

## Promises inspired by:

https://realm.io/news/swift-summit-javier-soto-futures/

## See also:

http://appventure.me/2015/06/19/swift-try-catch-asynchronous-closures/
