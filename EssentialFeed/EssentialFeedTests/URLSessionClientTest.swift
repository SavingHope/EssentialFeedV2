//
//  URLSessionClientTest.swift
//  EssentialFeedTests
//
//  Created by Jaavion Davis on 10/19/24.
//

import XCTest
import EssentialFeed



class URLSessionClient {
    // we need to have another implementation layer
    let session: URLSession
    init(session: URLSession) {
        self.session = session
    }
    
    private struct UnexpectedValue: Error {}
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: URLRequest(url: url)) { data, response, error in
            if let error = error {
                        completion(.failure(error))
                    } else if let data = data, let response = response as? HTTPURLResponse {
                        completion(.success(data, response))
                    } else {
                        completion(.failure(UnexpectedValue()))
                    }
                }.resume()
    }
}


final class URLSessionClientTest: XCTestCase {
    
    override func setUp() {
        URLProtocolStub.startIntereceptingRequest()
    }
    override func tearDown() {
        URLProtocolStub.stopInterceptingRequest()
    }
    
    func test_getFromURL_performGETRequestWithURL() {
        // assert
        URLProtocolStub.stub(data: nil, response: nil, error: anyError())
        let url: URL = anyURL()
        let exp = expectation(description: "wait for completion")
        let sut: URLSessionClient = makeSUT()
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        // we arent testing the results of the sequence of actions
        sut.get(from: url) { _ in }
      
        wait(for: [exp], timeout: 1.0)
    }
    func test_getFromURL_failsOnAllInvalidCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPResponse(), error: nil ))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPResponse(), error: nil ))
        XCTAssertNotNil(resultFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultFor(data: anyData() , response: anyHTTPResponse(), error: nil))
        
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        // assert
        let data = anyData()
        let response = anyHTTPResponse()
        let receivedValues = resultValuesFor(data: data, response: response, error: nil)

                XCTAssertEqual(receivedValues?.data, data)
                XCTAssertEqual(receivedValues?.response.url, response.url)
                XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
        
    }
    
    func test_getFromURL_failsOnAllNilsValues() {
        // let sut
        let url: URL = anyURL()
        let exp = expectation(description: "Wait for completion")
        URLProtocolStub.stub(data: nil, response: nil, error: nil)
        makeSUT().get(from: url) { result in
            switch(result) {
                    // we only care about a failure
                case .failure:
                    break;
                default:
                    XCTFail("expected failure but recieved \(result)")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    private func resultValuesFor(data: Data?, response: HTTPURLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line )-> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error)
        switch(result) {
            case let .success(data , response):
                return (data, response)
            default:
                return nil
                
        }
    }
   
    private func resultFor(data: Data?, response: HTTPURLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line)-> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let expectation = expectation(description: "Wait for completion")
        var receivedResult: HTTPClientResult!
                sut.get(from: anyURL()) { result in
                    receivedResult = result
                    expectation.fulfill()
                }

        wait(for: [expectation], timeout: 1.0)
        return receivedResult
    }
    
    
    private func resultErrorFor(data: Data?, response: HTTPURLResponse?, error: Error?)-> Error? {
        let result = resultFor(data: data, response: response, error: error)
        switch(result) {
            case let .failure(error):
                return error
                
            default:
                 return nil
        }
    }
    private func makeSUT(file: StaticString = #file, line: UInt = #line)-> URLSessionClient {
        let sut: URLSessionClient = URLSessionClient(session: .shared)
        trackForMemoryLeak(sut)
        return sut
    }
    private func trackForMemoryLeak(_ object: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak object] in
            XCTAssertNil(object, "Object has not been deallocated from memory", file: file, line: line)
        }
    }
    private func anyURL()-> URL! {
        URL(string: "https://any-time.com")
    }
    private func anyError()-> Error {
        NSError(domain: "any url", code: 100)
    }
    private func anyData()-> Data {
        Data("some data".utf8)
    }
    private func anyHTTPResponse()-> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(),
                        mimeType: "",
                        expectedContentLength: 0,
                        textEncodingName: "")
    }
    private func requestBuilder()-> URLRequest {
        URLRequest(url: anyURL())
    }
    
    private func anyURLResponse()-> URLResponse {
        URLResponse(url: anyURL(),
                    mimeType: "",
                    expectedContentLength: 0,
                    textEncodingName: "")
    }
}

private class URLProtocolStub: URLProtocol {
    // we need to have some area to store this area
    static private var requestObserver: ((URLRequest)-> Void)?
    private static var stub: Stub?
    internal struct Stub {
        let response: HTTPURLResponse?
        let error: Error?
        let data: Data?
    }
    
    static func observeRequest(request: @escaping (URLRequest)-> Void) {
        // attaching a pointer to the observer
        requestObserver = request
    }
    static func stub(data: Data?, response: HTTPURLResponse?, error: Error?) {
        stub = Stub(response: response, error: error, data: data)
    }
    override class func canInit(with request: URLRequest) -> Bool {
        // this is the what happens when you initalize the object
        // how do we know if we can get the request  if we can get the URL then yes
        //in the instance we have an error we want to register that error
        return true
        
    }
    
    
    // we want to observe the request for more reliable tes
    
    static func startIntereceptingRequest() {
        URLProtocol.registerClass(URLProtocolStub.self)
    }
    
    static func stopInterceptingRequest() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        stub = nil
        requestObserver = nil
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        requestObserver?(request)
        return request
    }
    
    override func stopLoading() {
        
    }
    
    override func startLoading() {
        guard let stub = URLProtocolStub.stub else { return }
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        client?.urlProtocolDidFinishLoading(self)
    }
    
    
}
