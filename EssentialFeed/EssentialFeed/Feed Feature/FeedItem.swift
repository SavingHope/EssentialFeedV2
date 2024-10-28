//
//  Untitled.swift
//  EssentialFeed
//
//  Created by Jaavion Davis on 9/27/24.
//



public struct FeedItem: Codable, Equatable {
    let title: String
    let description: String?
    let location: String?
    let imageURL: URL
    
    public init(title: String, description: String?, location: String?, imageURL: URL) {
        self.title = title
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}
