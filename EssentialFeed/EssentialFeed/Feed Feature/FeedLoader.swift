//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Jaavion Davis on 9/25/24.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader{
    func load(completion: @escaping (LoadFeedResult)-> Void )
}
