//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Jaavion Davis on 10/19/24.
//


public class FeedItemsMapper {
    private struct Root: Decodable {
        let items: [Item]
        var feed: [FeedItem] {
            return items.map { $0.item }
        }
    }

    private struct Item: Decodable {
        let title: String
        let description: String?
        let location: String?
        let image: URL

        var item: FeedItem {
            return FeedItem(title: title, description: description, location: location, imageURL: image)
        }
    }
    static var OK_200: Int { return 200 }
    
    static func map(_ data: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard let root = try? JSONDecoder().decode(Root.self, from: data),  response.statusCode == OK_200 else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        return  .success(root.feed)
    }
}
