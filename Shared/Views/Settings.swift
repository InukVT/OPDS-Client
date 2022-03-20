//
//  Settings.swift
//  OPDS-Client
//
//  Created by Bastian Inuk Christensen on 2022-03-20.
//

import SwiftUI
import CoreData

struct Settings: View {
    @FetchRequest(sortDescriptors: [])
    var servers: FetchedResults<ServerModel>
    
    var body: some View {
        NavigationView {
            Form {
                Section() {
                    if servers.count > 0 {
                        List(servers) { server in
                            NavigationLink(destination: Text("Server")) {
                                Text(server.friendlyName ?? "Unknown hostname")
                                
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
