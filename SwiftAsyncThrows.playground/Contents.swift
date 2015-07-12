//: Playground - noun: a place where people can play

import Foundation


struct ExampleValue {
	let number: Int
}

enum ExampleError: ErrorType {
	case DidFail
}



// Same as: http://appventure.me/2015/06/19/swift-try-catch-asynchronous-closures/

func willAlwaysSucceed(resultReturner: (() throws -> ExampleValue) -> Void) {
	resultReturner {
		return ExampleValue(number: 15)
	}
}

func willAlwaysFail(resultReturner: (() throws -> ExampleValue) -> Void) {
	resultReturner {
		throw ExampleError.DidFail
	}
}


willAlwaysSucceed { result in
	do {
		let value = try result()
		print("Got value \(value)")
	}
	catch let error {
		print("Caught error \(error)")
	}
}

willAlwaysFail { resultReturner in
	do {
		let result = try resultReturner()
		print("Got result \(result)")
	}
	catch let error {
		print("Caught error \(error)")
	}
}



// Using Swift 2 compatible Result type

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

func willAlwaysSucceed2(resultReturner: (Result<ExampleValue>) -> Void) {
	resultReturner(
		Result(ExampleValue(number: 15))
	)
}

func willAlwaysFail2(resultReturner: (Result<ExampleValue>) -> Void) {
	resultReturner(
		Result.Error(ExampleError.DidFail)
	)
}

func useResult(result: Result<ExampleValue>) {
	do {
		let value = try result.use()
		print("Got value \(value)")
	}
	catch let error {
		print("Caught error \(error)")
	}
}

willAlwaysSucceed2(useResult)
willAlwaysFail2(useResult)



// Based on: https://realm.io/news/swift-summit-javier-soto-futures/

struct ResultPromise<T> {
	typealias Value = T
	typealias ResultType = Result<T>
	typealias Completion = (ResultType) -> Void
	typealias AsyncOperation = (Completion) -> Void
	private let operation: AsyncOperation
	
	init(operation: AsyncOperation) {
		self.operation = operation
	}
	
	init(result: ResultType) {
		self.init(operation: { $0(result) })
	}
	
	init(_ success: T) {
		self.init(result: .Success(success))
	}
	
	init(error: ErrorType) {
		self.init(result: .Error(error))
	}
	
	func start(completion: Completion) {
		operation { result in
			completion(result)
		}
	}
}

extension ResultPromise {
	func map<U>(f: T -> U) -> ResultPromise<U> {
		return ResultPromise<U>(operation: { completion in
			self.start { result in
				switch result {
				case .Success(let value):
					completion(Result(f(value)))
				case .Error(let error):
					completion(Result.Error(error))
				}
			}
		})
	}
	
	func andThen<U>(f: T -> ResultPromise<U>) -> ResultPromise<U> {
		return ResultPromise<U>(operation: { completion in
			self.start { result in
				switch result {
				case .Success(let value):
					f(value).start(completion)
				case .Error(let error):
					completion(Result.Error(error))
				}
			}
		})
	}
}

let succeedPromise = ResultPromise(operation: willAlwaysSucceed2)
succeedPromise.start(useResult)

let failPromise = ResultPromise(operation: willAlwaysFail2)
failPromise.start(useResult)


// When function has more arguments:

func willAlwaysSucceed2WithArg(argument: Int, resultReturner: (Result<ExampleValue>) -> Void) {
	resultReturner(
		Result(ExampleValue(number: 15))
	)
}

let succeedPromiseWithArg = ResultPromise(operation: {
	willAlwaysSucceed2WithArg(5, resultReturner: $0)
})
