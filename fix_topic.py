with open("Group_11_Revisio/Study/Models/Topic.swift", "r") as f:
    content = f.read()

# Add to properties
content = content.replace("var createdDate: String?", "var createdDate: String?\n    var currentProgressIndex: Int?\n    var totalItemsCount: Int?")

# Add to CodingKeys
content = content.replace("case createdDate", "case createdDate\n        case currentProgressIndex\n        case totalItemsCount")

# Add to init(from decoder:)
content = content.replace("self.createdDate = try container.decodeIfPresent(String.self, forKey: .createdDate)", "self.createdDate = try container.decodeIfPresent(String.self, forKey: .createdDate)\n        self.currentProgressIndex = try container.decodeIfPresent(Int.self, forKey: .currentProgressIndex)\n        self.totalItemsCount = try container.decodeIfPresent(Int.self, forKey: .totalItemsCount)")

# Add to init()
content = content.replace("createdDate: String? = nil)", "createdDate: String? = nil,\n         currentProgressIndex: Int? = nil,\n         totalItemsCount: Int? = nil)")
content = content.replace("self.createdDate = createdDate", "self.createdDate = createdDate\n        self.currentProgressIndex = currentProgressIndex\n        self.totalItemsCount = totalItemsCount")

with open("Group_11_Revisio/Study/Models/Topic.swift", "w") as f:
    f.write(content)
