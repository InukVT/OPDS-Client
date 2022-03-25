extension ServerModel {
    public var endpoints: [EndpointModel] {
        let set = self.enpointRelation as? Set<EndpointModel> ?? []
        return set.sorted {
            ($0.path ?? "") < ($1.path ?? "")
        }
    }
}
