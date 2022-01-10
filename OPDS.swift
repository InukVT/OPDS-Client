import Foundation
import Combine
import UIKit
import SwiftUI
import CryptoKit
import Alamofire
import XMLCoder

class OPDS : ObservableObject {
    @Published
    private(set) var feed: Feed?
    private(set) var baseURL: URL?
    
    init(feed: Feed? = nil) {
        self.feed = feed
    }
    
    func load(
        from url: URL? = nil,
        path: String,
        needsLogin login: (() async -> (String, String))
    ) async throws {
        if url != nil {
            baseURL = url
        }
        
        guard let workingURL = URL(string: path, relativeTo: baseURL) else {
            throw Err.noURL
        }

        print("Working on \(workingURL.absoluteString)")
        
        var response = await AF.request(workingURL).serializingData().response

        while (response.response?.statusCode == 401) {
            print(response.response?.headers ?? "")
            async let (username,password) = login()
            response = await AF.request(workingURL).authenticate(username: username, password: password).serializingData().response
        }
        
        guard let data = response.value else {
            throw Err.noData
        }
        
        let decoder = XMLDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.dataDecodingStrategy = .deferredToData
        let feed = try decoder.decode(Feed.self, from: data)
        
        await MainActor.run {
            self.feed = feed
        }
    }
    
    func unload() {
        self.feed = nil
    }
    
    enum Err: String, Error {
        case noData = "No Data"
        case illForm = "Data isn't formatted correctly"
        case noURL = "No URL provided"
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
        let updated: Date
        /*
        var lastUpdated: Date {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let date = dateFormatter.date(from:updated)!
            return date
        }*/
        let content: Content
        let link: [Link]
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
        let rel: String?
    }
}
