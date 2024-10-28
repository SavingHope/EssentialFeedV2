//
//  EssentialFeedTests.swift
//  EssentialFeedTests
//
//  Created by Jaavion Davis on 9/24/24.
//

import XCTest
import EssentialFeed

final class EssentialFeedTests: XCTestCase {

    func test_init_doesNotRequestData() {
        // we never want to test the implementation layer because we will see majority of the time the implementation will be the native api
        // right now we have an http client and we want to request some URL we need to test the higher module
        // given
     
        // when this object initalizes we should not expect any data so it should be nil
        let (_, client) = makeSUT()
        // but whenever we load it should load
        
        XCTAssertEqual([], client.requestedURLS)
    }
    
    func test_load_doesRequestDataFromURL() {
        // now i can test the url
        let url: URL! = URL(string: "https://a-given-url.com")
        let (sut, client) = makeSUT()
        // here we see probably shouldnt soley test out the variable we need some way to check and see if we can capture it twice
        sut.load()
        
        //we probably should test soley the url because what happens if invoke the function more than once
        XCTAssertEqual([url], client.requestedURLS)
    }
    //always remember to make the test fail
    
    func test_loadTwice_doesRequestDataFromURLTwice() {
        let url: URL! = URL(string: "https://a-given-url.com")
        let (sut, client) = makeSUT()
        sut.load()
        sut.load()
        XCTAssertEqual([url, url], client.requestedURLS)
    }
    // we see some duplication so we can create a factory pattern
    // we need to make sure that we are returning a client error
    
//    func test_load_doesDelieverErrorOnClientRequest() {
//        // we need to make sure that we are able to get an error from the client
//        // given
//        // we have a client and a sut
//        // when we use the load functionality
//        // we expect to receieve a client error
//        
//        let (sut, client) = makeSUT()
//        let error = NSError(domain: "remote feed", code: 0)
//        
//        // we can stub this because we don't have an error
//        // we need to be able to test this value so we need to capture this value
//        // we need to be able to invoke a method that does error
//        // we want to handle asynchrnous error
//        var capturedErrors: Array<RemoteFeedLoader.Result> = Array()
//        sut.load { capturedErrors.append($0) }
//        client.completeWith(error: error)
//        XCTAssertEqual(capturedErrors, [])
//        
//    }
    
    
    func test_load_delieversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        // act
        [199, 201, 299, 401, 499, 501].enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData)) {
            
                client.completeWith(statusCode: code, at: index)
            }
        }
    }
    
    func failure(_ error: RemoteFeedLoader.Error)-> RemoteFeedLoader.Result {
        return .failure(error)
    }
    
    func test_load_delieversItemsWithResponseStatusCode200() {
        // when
        let (sut, client) = makeSUT()
                let item1 = makeItems(
                    title: "out with friends",
                    description: nil,
                    location: nil,
                    imageURL: URL(string: "https://test-image-1")!)
        
                let item2 =  makeItems(
                    title: "hanging with the guys",
                    description: nil,
                    location: nil,
                    imageURL: URL(string: "https://test-image-2")!
                )
        // we can create a tuple because we aer going to compare both of thesse valiues
        
        let model = [item1.model, item2.model]

        expect(sut, toCompleteWith: .success(model)) {
            let items = makeJSON(items: [item1.json, item2.json])
            client.completeWith(statusCode: 200, data: items)
        }
    }
    func test_load_delieversEmptyJSONFromStatusCode200() {
        // I want to assert that whenever we give an Empty JSON
        let(sut, client) = makeSUT()

            // act
        expect(sut, toCompleteWith: .success([])) {
            let items = makeJSON(items: [])
            client.completeWith(statusCode: 200, data: items)
            }
        }
    
    //hold on give me 10 minutes
    
    func test_load_delieversErrorONInvalidData200StatusCode() {
        // when
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWith: failure(.invalidData)) {
            let data: Data = Data("invalidJSON".utf8)
            client.completeWith(statusCode: 200, data: data)
        }
    }
    
    func test_load_doesNotDelieverResultAfterSutInstanceHasBeenDeallocated() {
        // assert
        let url: URL! = URL(string: "https://any-random-url.com")
        let client: HTTPClientSpy = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)        // when
        // captured values
        var capturedValues: [RemoteFeedLoader.Result] = [RemoteFeedLoader.Result]()
       
        sut?.load { capturedValues.append($0)}
        sut = nil
        
        client.completeWith(statusCode: 200, data: makeJSON(items: []) )
        XCTAssertTrue(capturedValues.isEmpty)
    }
        
        
        
    private func makeSUT(url: URL = URL(string: "https://a-given-url.com")!)-> (RemoteFeedLoader, HTTPClientSpy) {
        // we just want this function to return an SUT
        let client = HTTPClientSpy()
        // the remote feed loader should be responsible for loading knowing the url
        let sut: RemoteFeedLoader = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeak(sut)
        trackForMemoryLeak(client)
        return (sut, client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWith expectedResult: RemoteFeedLoader.Result, when action: ()-> Void,  file: StaticString = #file, line: UInt = #line ) {
        // we don't need the client
        // i need to use pattern matching
        let exp = expectation(description: "wait for load completion")
        sut.load { recievedResult in
            switch(expectedResult, recievedResult) {
                // we are unpacking the items that are in here
            case let (.success(recievedItems), .success(expectedItems)):
                XCTAssertEqual(recievedItems, expectedItems)
            case let (.failure(recievedItems as RemoteFeedLoader.Error), .failure(expectedItems as RemoteFeedLoader.Error) ):
                XCTAssertEqual(recievedItems, expectedItems)
            default:
                    XCTAssertNil("expected: \(expectedResult) but recieved: \(recievedResult)", file: file, line: line)

            }
            exp.fulfill()
        }
        action()
        
        wait(for: [exp], timeout: 1.0)

       
        
    }
    private func makeItems(title: String, description: String? = nil, location: String? = nil, imageURL: URL!)-> (model: FeedItem, json: [String: Any]) {
        let feedItem: FeedItem = FeedItem(title: title,
                                          description: description,
                                          location: location,
                                          imageURL: imageURL)
        let json = [
                    "title": title,
                    "description": description,
                    "location": location,
                    "image": imageURL.absoluteString
                ].reduce(into: [String: Any]()) { (acc, e) in
                    if let value = e.value { acc[e.key] = value }
                }
        
        return (feedItem, json)
    }
    private func makeJSON(items: [[String: Any]]) -> Data {
        let items: [String: Any] = ["items": items]
        return try! JSONSerialization.data(withJSONObject: items)
    }
    
    private func trackForMemoryLeak(_ object: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Object has not been deallocated from memory", file: file, line: line)
        }
    }
}


// we shouldn't be testing the implementation production code

// lets create a singleton

// we should not be using a property for testing its we should use function

private class HTTPClientSpy: HTTPClient {
    typealias HTTPResponseCompletions = (HTTPClientResult)-> Void
    var messages: Array<(url: URL, response: HTTPResponseCompletions)> = []
    var requestedURLS: [URL] {
        messages.map {$0.url}
    }
    // now maybe we want multiple http clients theres nothing that stops of from this
    
    // we can store this and access this at which ever time
    func get(url: URL, completion: @escaping (HTTPClientResult)-> Void ) {
        //a method invoking is a message passage
        // we can turn this into a tuple
        messages.append((url, completion))
    }
    
    func completeWith(error: Error, at index: Int = 0) {
        // we need to invoket his method
        //but we can't we have this
        // we need to make sure there's state management as of right now we need to worry about 4 states
        
        messages[index].response(.failure(error))
    }
    
    func completeWith(statusCode: Int, at index: Int = 0, data: Data = Data()) {
        // we need something that will give us a response
        
        let response: HTTPURLResponse! = HTTPURLResponse(url: requestedURLS[index],
                                                        statusCode: statusCode,
                                                        httpVersion: nil,
                                                        headerFields: nil)
        // we want to pass in this value
        messages[index].response(.success(data, response))
        
    }
}

//now we at least know we are testing the production code
// we can see that we have an abstract class at this point
// so we can turn this into a protocol


// theres always a getter setter function
