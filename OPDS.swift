import Foundation
import Combine
import UIKit
import SwiftUI
import CryptoKit
import Alamofire
import XMLCoder

class OPDS : ObservableObject {
    @Published
    private(set) var feed: Feed? = nil
    
    init(
        from url: URL,
        needsLogin login: (() async -> (String, String))
    ) async throws {
        var response = await AF.request(url).serializingData().response

        while (response.response?.statusCode == 401) {
            print(response.response?.headers ?? "")
            async let (username,password) = login()
            response = await AF.request(url).authenticate(username: username, password: password).serializingData().response
            guard response.response?.statusCode != 401 else {
                continue
            }
        }
        guard let data = response.value else {
            throw Err.noData
        }
        
        let decoder = XMLDecoder()
        let feed = try decoder.decode(Feed.self, from: data)
        
        self.feed = feed
    }
    
    enum Err: String, Error {
        case noData = "No Data"
        case illForm = "Data isn't formatted correctly"
    }
}

extension OPDS {
    struct Feed: Codable {
        let entries: [Entry]
        
        enum CodingKeys: String, CodingKey {
            case entries = "entry"
        }
    }
    
    struct Entry: Codable {
        let id: String
        let title: String
        private let updated: String
        var lastUpdated: Date {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let date = dateFormatter.date(from:updated)!
            return date
        }
        let content: Content
        let link: Link
    }
    
    struct Content : Codable {
        let type: String
        let value: String
        
        enum CodingKeys: String, CodingKey {
            case type
            case value = ""
        }

    }
    
    struct Link: Codable {
        let href: String
        let type: String
    }
}
