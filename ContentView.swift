import SwiftUI

struct ContentView: View {
    @State
    var servers: [Server] = []
    
    @State
    var submit: ((String, String) -> ())? = nil
    @State
    var showSheet = false
    
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
        
            .sheet(isPresented: $showSheet) {
                TextField("Username", text: $username)
                TextField("Password", text: $password)
                Button("submit") {
                    submit?(username, password)
                }
            }
    }
    
    func search(address: String) {
        Task {
            let url = URL(string:address)
            guard var url = url else {
                print("Url failure")
                return
            }
            url.appendPathComponent("/opds")
            do {
                let _ = try await OPDS(from: url) {
                    return await withCheckedContinuation { c in
                        self.submit = { (username, password) in
                            c.resume(returning: (username, password))
                        }
                        self.showSheet = true
                    }
                }
            } catch {
                print(error)
            }
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
    
    @State
    private var address: String = ""
    
    var body: some View {
        HStack {
            TextField("Server", text: $address)
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
