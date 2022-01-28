import SwiftUI

struct ContentView: View {
    @State
    var servers: [Server] = []
    
    @State
    var submit: ((String, String) -> ())? = nil
    
    @State
    var showLoginSheet = false
    
    @StateObject
    var activeServer = OPDS()
    
    @State
    var password = ""
    @State
    var username = ""
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(servers, id: \.name) { server in
                    Text(server.name)
                }
            }
        }
        ServerBar(onSearch: search)
            .padding(10)
            .background(Color(uiColor: .secondarySystemBackground))
        
            .sheet(isPresented: $showLoginSheet) {
                List {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                    Button("submit") {
                        submit?(username, password)
                        showLoginSheet = false
                    }
                }
            }
        
            .sheet(isPresented: .init {
                activeServer.feed != nil && !showLoginSheet
            } set: {
                _ in self.activeServer.unload()
                
            }) {
                ServerView(server: self.activeServer, needsLogin: login)
            }
    }
    
    func search(address: String) {
        Task {
            let url = URL(string:address)
            guard let url = url else {
                print("Url failure")
                return
            }
            do {
                let _ = try await self.activeServer.load(from: url, path: "/opds", needsLogin: login)
                
            } catch {
                print(error)
            }
        }
    }
    
    func login() async -> (URLCredential) {
        return await withCheckedContinuation { c in
            self.submit = { (username, password) in
                c.resume(returning: URLCredential(user: username, password: password, persistence: .permanent))
            }
            self.showLoginSheet = true
        }
    }
}

/// Simple search bar with callback to search and adding fields
struct ServerBar : View {
    /// Called when the user presses the search button
    let onSearch: (String) -> ()
    
    func action(fun : KeyPath<ServerBar,(String)->()>) -> () -> () {
        return { self[keyPath: fun](address) }
    }
    
    static let addressKey = "Server Adress"
    @AppStorage(Self.addressKey)
    private var address: String = ""
    
    var body: some View {
        HStack {
            TextField("Server", text: $address)
                .textContentType(.URL)
                .onSubmit(of: .text, action(fun: \.onSearch) )
            Button("Search", action: action(fun: \.onSearch) )
        }
    }
}

struct Server {
    let name: String
    let server: String
}

extension Server {
    var id: String {
        name + server
    }
}
