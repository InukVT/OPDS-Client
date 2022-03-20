import Foundation
import Combine
import UIKit
import SwiftUI
import CryptoKit
import XMLCoder
import os

class OPDS : ObservableObject {
    @Published
    private(set) var feed: Feed?
    private(set) var baseURL: URL?
    
    private let logger = Logger()
    
    @Published
    private(set) var downloadProgress: Progress? = nil
    
    //private var downloadDelegates: [OPDSDownloadDelegate] = []
    
    init(feed: Feed? = nil) {
        self.feed = feed
    }
    
    func load(
        from url: URL? = nil,
        path: String,
        needsLogin login: @escaping (() async -> (URLCredential))
    ) async throws {
        if url != nil {
            baseURL = url
        }
        
        guard let workingURL = URL(string: path, relativeTo: baseURL) else {
            throw Err.noURL
        }

        logger.debug("Working on \(workingURL.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: workingURL, delegate: OPDSURLDelegate(needLogin: login))
        
        guard !data.isEmpty else {
            logger.error("Error on \(workingURL.absoluteString), response is \(response)")
            throw Err.noData
        }
        
        let decoder = XMLDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.dataDecodingStrategy = .deferredToData
        do {
            let feed = try decoder.decode(Feed.self, from: data)
            
            await MainActor.run {
                self.feed = feed
            }
        } catch {
            logger.error("Error decoding XML on \(workingURL.absoluteString). Error is \(error.localizedDescription)")
            if let errorString = try? String(data: data, encoding: .utf8) {
                logger.debug("With contests of \(errorString)")
            }
            throw Err.illForm
        }
    }
    
    var delegate: OPDSDownloadDelegate?
    
    func download(
        path: String,
        expectedBytes: Int64,
        identifier: String
    ) throws {
        guard delegate?.backgroundTask.state != .running
        else {
            throw Err.alreadyRunning
        }
        guard let workingURL = URL(string: path, relativeTo: baseURL)
        else {
            throw Err.noURL
        }
        
        delegate = OPDSDownloadDelegate(
            id: identifier,
            progress: &$downloadProgress,
            url: workingURL,
            expectedBytes: expectedBytes + 400
        )
        
    }
    
    func unload() {
        self.feed = nil
    }
    
    enum Err: String, Error {
        case noData = "No Data"
        case illForm = "Data isn't formatted correctly"
        case noURL = "No URL provided"
        case alreadyRunning = "There is already a download going on"
    }
}

class OPDSDownloadDelegate : NSObject, URLSessionDownloadDelegate {
    let id: String
    
    var backgroundTask: URLSessionDownloadTask!
    
    var logger = Logger()
    
    lazy var session: URLSession = {
        
        let config = URLSessionConfiguration.background(withIdentifier: id)
        config.isDiscretionary = true
        config.sessionSendsLaunchEvents = true
        //downloadDelegates.append(delegate)
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    //lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    
    init(id: String,
         progress: inout Published<Progress?>.Publisher,
         url workingURL: URL,
         expectedBytes: Int64) {
        
        self.id = id
        super.init()
        self.backgroundTask = session.downloadTask(with: workingURL)
        
        backgroundTask.countOfBytesClientExpectsToReceive = expectedBytes
        
        backgroundTask.resume()
        logger.debug("Url task \(self.backgroundTask.state == .running ? "running" : "not running")")
        
        backgroundTask.publisher(for: \.progress)
            .print("Progress")
            .map { Optional($0) }
            .assign(to: &progress)
    }
    
    deinit {
        print("De-initialised")
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard downloadTask == backgroundTask else { return }
        logger.debug("\(self.id): \(downloadTask.progress)%")
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard downloadTask == backgroundTask else { return }
        logger.debug("\(self.id): Finished downloading book to \(location)")
        let documents = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)
        for folder in documents {
            logger.debug("Found folder at \(folder)")
        }
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard task == backgroundTask else { return }
        if let error = error ?? task.error {
            logger.debug("\(self.id): failed downloading with \( error.localizedDescription)")
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        logger.debug("download done, done.")
    }
    
}

class OPDSURLDelegate : NSObject, URLSessionTaskDelegate {
    let login: () async -> (URLCredential)
    
    init(needLogin: @escaping () async -> (URLCredential)) {
        self.login = needLogin
    }
    
    func urlSession(
        _ session: URLSession,
        task : URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let credentials = await login()
        return (.useCredential, credentials )
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
        let length: Int?
    }
}
