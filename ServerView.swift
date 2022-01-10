import SwiftUI

struct ServerView : View {
    @ObservedObject
    var server: OPDS
    let needsLogin: () async -> (String, String)
    
    @State
    private var alignment: HorizontalAlignment = .center
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: alignment) {
                if case let .some(feed) = server.feed {
                    ForEach(feed.entries, id: \.id) { entry in
                        HStack(alignment:.top) {
                            if let coverURL = cover(link: entry.link) {
                                AsyncImage(url: coverURL) { image in
                                    image.resizable()
                                        .scaledToFit()
                                } placeholder: {
                                    Color.purple.opacity(0.1)
                                }
                                .frame(width: 100, height: 150)
                                .cornerRadius(10)
                                .task {
                                    alignment = .leading
                                }
                            }
                            if let feedURL = (entry.link.first {
                                $0.type == "application/atom+xml;type=feed;profile=opds-catalog"
                            }) {
                                AsyncButton{
                                    try? await load(feedURL)
                                } label: {
                                    Text(entry.title)
                                }.padding()
                                    .buttonStyle(.bordered)
                                    .task {
                                        alignment = .center
                                    }
                            } else {
                                Text(entry.title)
                            }
                        }
                    }
                }
            }
        }.padding()
    }
    
    func cover(link: [OPDS.Link]) -> URL? {
        link.first {
            $0.rel == "http://opds-spec.org/image/thumbnail"
            || $0.rel == "http://opds-spec.org/image"
        }.flatMap { URL(string: $0.href, relativeTo: server.baseURL) }
        .map {
            print($0)
            return $0
        }
    }
    
    func load(_ link: OPDS.Link) async throws {
        try await server.load(path: link.href, needsLogin: needsLogin)
    }
}


struct ServerViewPreview : PreviewProvider {
    static var server = OPDS(feed: .init(entries: [
            .init(
                id: "Test 1",
                title: "Test",
                updated: .now,
                content: .init(type: "Test", value: "Test"),
                link: []
            ),
            .init(
                id: "Test 2",
                title: "Test",
                updated: .now,
                content: .init(type: "Test", value: "Test"),
                link: []
            ),
            .init(
                id: "Test 3",
                title: "Test",
                updated: .now,
                content: .init(type: "Test", value: "Test"),
                link: []
            ),
            .init(
                id: "Test 4",
                title: "Test",
                updated: .now,
                content: .init(type: "Test", value: "Test"),
                link: []
            ),
        ]))
    
    static var previews: some View {
        ServerView(server: server) {
            abort()
        }
    }
}
