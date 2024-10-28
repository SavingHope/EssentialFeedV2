//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Jaavion Davis on 9/25/24.
//

import Foundation




public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(url: URL, completion: @escaping (HTTPClientResult)-> Void)
}
public final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    //what is the fail case saying
    // if we are expecting an error
    // seperation this is domain enum so
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    // these are domain results
    // we expect to see an array of feed results
    
    public typealias Result = LoadFeedResult
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    // we shouldnt have a domain error we need to have something a little bit more concrete
    // this isnt a contract
    public func load(completion: @escaping (Result)-> Void = { _ in }) {
        client.get(url: url, completion:{ [weak self] result in
            guard self != nil else {return }
            // right now this function is doing alot it's mapping as well return the data
            // we can seperate the functionality
            switch(result) {
                case let .success(data, response):
                    // this is beginning to get cluttered
                    completion(FeedItemsMapper.map(data, response))
                case .failure:
                    completion(.failure(Error.connectivity))
            }
        })
    }
    // maybe we can map this function out
    // the mapping function will take the data and return a resul
}

