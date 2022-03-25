//
//  Settings.swift
//  OPDS-Client
//
//  Created by Bastian Inuk Christensen on 2022-03-20.
//

import SwiftUI
import CoreData
import os
import XMLCoder

class OPDSFeeder {
    private let logger = Logger()
    let server: ServerModel
    
    init(server: ServerModel) {
        self.server = server
    }
    
    func load(at path: String) async throws -> OPDS.Feed {
        
        guard let workingURL = URL(string: path, relativeTo: server.host) else {
            throw Err.noURL
        }

        logger.debug("Working on \(workingURL.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: workingURL, delegate: OPDSURLDelegate(needLogin: {
            let cred = URLCredential(user: self.server.username!, password: self.server.password!, persistence: .forSession)
            return cred
        }))
        
        guard !data.isEmpty else {
            logger.error("Error on \(workingURL.absoluteString), response is \(response)")
            throw Err.noData
        }
        
        let decoder = XMLDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.dataDecodingStrategy = .deferredToData
        do {
            let feed = try decoder.decode(OPDS.Feed.self, from: data)
            
            return feed
        } catch {
            logger.error("Error decoding XML on \(workingURL.absoluteString). Error is \(error.localizedDescription)")
            if let errorString = String(data: data, encoding: .utf8) {
                logger.debug("With contests of \(errorString)")
            }
            throw Err.illForm
        }
    }
    
    enum Err: String, Error {
        case noData = "No Data"
        case illForm = "Data isn't formatted correctly"
        case noURL = "No URL provided"
        case alreadyRunning = "There is already a download going on"
    }
}

struct FeedBrowser: View {
    let feeder: OPDSFeeder
    let path: String
    
    private let logger = Logger()
    
    @State
    private var feed: OPDS.Feed? = nil
    let title: String
    
    var body: some View {
        List(feed?.entries ?? []) { entry in
            if let feedURL = (entry.link.first {
                $0.type == "application/atom+xml;type=feed;profile=opds-catalog"
            }) {
                NavigationLink {
                    FeedBrowser(feeder: feeder, path: feedURL.href, title: entry.title)
                } label: {
                    Text(entry.title)
                }
            }
        }
            .navigationTitle(title)
            .task {
                do {
                    feed = try await feeder.load(at: path)
                } catch {
                    logger.error("Error fetching feed: \(error.localizedDescription, privacy: .private)")
                }
            }
    }
}

struct Endpoints: View {
    let server: ServerModel
    let endpoints: [EndpointModel]
    
    var body: some View {
        VStack {
            if (endpoints.count > 0) {
                List(endpoints) {
                    Text($0.path!)
                }
            } else {
                VStack {
                    Text("No endpoints :(")
                    Text("Please add some ;)")
                }
            }
            
            
            NavigationLink("Add Endpoint") {
                FeedBrowser(feeder: .init(server: server), path: "/opds", title: "Root")
            }
        }
    }
    
}

struct Settings: View {
    @FetchRequest(sortDescriptors: [])
    var servers: FetchedResults<ServerModel>
    
    var body: some View {
        NavigationView {
            Form {
                Section() {
                    if servers.count > 0 {
                        List(servers) { server in
                            NavigationLink(server.friendlyName ?? "Unknown hostname") {
                                Endpoints(server: server, endpoints: server.endpoints)
                                    
                            }
                        }
                    } else {
                        Text ("No servers yet")
                    }
                } header: {
                    Text("Servers")
                        .font(.title)
                }
                AddServer()
            }
            .navigationBarHidden(true)
        }
    }
}

struct AddServer : View {
    @Environment(\.managedObjectContext)
    private var moc
        
    @State
    private var name: String = ""
    @State
    private var host: String = ""
    
    @State
    private var username: String = ""
    @State
    private var password: String = ""
    
    var body: some View {
        Section() {
            TextField("Friendly Name", text: $name)
            TextField("Server Host", text: $host)
                .onSubmit(of: .text) {
                    addServer()
                }
            TextField("Username", text: $username)
            TextField("Password", text: $password)
                .onSubmit(of: .text) {
                    addServer()
                }
            Button() {
                addServer()
            } label: {
                Text("Add server")
            }
            
            
        } header: {
            Text("Add Server")
                .font(.title)
        }
    }
    
    func addServer() {
        let model = ServerModel(context: moc)
        
        guard let host = URL(string: self.host) else {
            // TODO: proper error management
            return
        }
        
        if name == "" {
            name = host.host ?? ""
        }
        
        model.friendlyName = name
        model.host = host
        model.password = password
        model.username = username
        
        try? moc.save()
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
