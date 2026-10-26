import Foundation

final class XtreamContentLoader {
    private struct InfoResponse: Decodable {
        let userInfo: UserInfo
        /// Servers answer a wrong login with only `user_info` (auth 0), so this can be missing.
        let serverInfo: ServerInfo?
        
        enum CodingKeys: String, CodingKey {
            case userInfo = "user_info"
            case serverInfo = "server_info"
        }
    }
    
    private struct UserInfo: Decodable {
        let auth: Int?
        let username: String?
        let status: String?
        let allowedOutputFormats: [String]?
        
        enum CodingKeys: String, CodingKey {
            case auth
            case username
            case status
            case allowedOutputFormats = "allowed_output_formats"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            auth = container.decodeLossyIntIfPresent(forKey: .auth)
            username = try container.decodeIfPresent(String.self, forKey: .username)
            status = try container.decodeIfPresent(String.self, forKey: .status)
            allowedOutputFormats = try container.decodeIfPresent([String].self, forKey: .allowedOutputFormats)
        }
    }
    
    private struct ServerInfo: Decodable {
        let serverProtocol: String?
        let port: String?
        let httpsPort: String?
        
        enum CodingKeys: String, CodingKey {
            case serverProtocol = "server_protocol"
            case port
            case httpsPort = "https_port"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            serverProtocol = try container.decodeIfPresent(String.self, forKey: .serverProtocol)
            port = container.decodeLossyStringIfPresent(forKey: .port)
            httpsPort = container.decodeLossyStringIfPresent(forKey: .httpsPort)
        }
    }
    
    private struct Category: Decodable {
        let categoryID: String
        let categoryName: String
        
        enum CodingKeys: String, CodingKey {
            case categoryID = "category_id"
            case categoryName = "category_name"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            categoryID = container.decodeLossyStringIfPresent(forKey: .categoryID) ?? ""
            categoryName = try container.decodeIfPresent(String.self, forKey: .categoryName) ?? ""
        }
    }
    
    private struct XtreamLive: Decodable {
        let streamID: Int?
        let name: String?
        let streamIcon: String?
        let categoryID: String?
        
        enum CodingKeys: String, CodingKey {
            case streamID = "stream_id"
            case name
            case streamIcon = "stream_icon"
            case categoryID = "category_id"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            streamID = container.decodeLossyIntIfPresent(forKey: .streamID)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            streamIcon = try container.decodeIfPresent(String.self, forKey: .streamIcon)
            categoryID = container.decodeLossyStringIfPresent(forKey: .categoryID)
        }
    }
    
    private struct XtreamVod: Decodable {
        let streamID: Int?
        let name: String?
        let streamIcon: String?
        let categoryID: String?
        let containerExtension: String?
        
        enum CodingKeys: String, CodingKey {
            case streamID = "stream_id"
            case name
            case streamIcon = "stream_icon"
            case categoryID = "category_id"
            case containerExtension = "container_extension"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            streamID = container.decodeLossyIntIfPresent(forKey: .streamID)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            streamIcon = try container.decodeIfPresent(String.self, forKey: .streamIcon)
            categoryID = container.decodeLossyStringIfPresent(forKey: .categoryID)
            containerExtension = try container.decodeIfPresent(String.self, forKey: .containerExtension)
        }
    }
    
    private struct XtreamSeries: Decodable {
        let seriesID: Int?
        let name: String?
        let cover: String?
        let categoryID: String?
        
        enum CodingKeys: String, CodingKey {
            case seriesID = "series_id"
            case name
            case cover
            case categoryID = "category_id"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            seriesID = container.decodeLossyIntIfPresent(forKey: .seriesID)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            cover = try container.decodeIfPresent(String.self, forKey: .cover)
            categoryID = container.decodeLossyStringIfPresent(forKey: .categoryID)
        }
    }
    
    private let serverURL: String
    private let username: String
    private let password: String
    private let session: URLSession
    private let decoder = JSONDecoder()
    private var currentTask: URLSessionDataTask?
    private var isCancelled = false
    
    init(serverURL: String, username: String, password: String, session: URLSession = .shared) {
        self.serverURL = serverURL
        self.username = username
        self.password = password
        self.session = session
    }
    
    func load(completion: @escaping (Result<[IPTVChannel], Error>) -> Void) {
        requestInfo { [weak self] result in
            guard let self, !self.isCancelled else { return }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let info):
                guard self.isValid(info) else {
                    completion(.failure(IPTVPlaylistError.xtreamAccessDenied))
                    return
                }
                
                self.requestAllContent(info: info, completion: completion)
            }
        }
    }
    
    func cancel() {
        isCancelled = true
        currentTask?.cancel()
    }
    
    private func requestAllContent(
        info: InfoResponse,
        completion: @escaping (Result<[IPTVChannel], Error>) -> Void
    ) {
        requestCategories(action: "get_live_categories") { [weak self] liveCategoriesResult in
            guard let self, !self.isCancelled else { return }
            self.requestCategories(action: "get_vod_categories") { [weak self] vodCategoriesResult in
                guard let self, !self.isCancelled else { return }
                self.requestCategories(action: "get_series_categories") { [weak self] seriesCategoriesResult in
                    guard let self, !self.isCancelled else { return }
                    
                    let liveCategories = (try? liveCategoriesResult.get()) ?? []
                    let vodCategories = (try? vodCategoriesResult.get()) ?? []
                    let seriesCategories = (try? seriesCategoriesResult.get()) ?? []
                    
                    self.requestLives(categories: liveCategories, info: info) { [weak self] livesResult in
                        guard let self, !self.isCancelled else { return }
                        self.requestVods(categories: vodCategories) { [weak self] vodsResult in
                            guard let self, !self.isCancelled else { return }
                            self.requestSeries(categories: seriesCategories) { [weak self] seriesResult in
                                guard let self, !self.isCancelled else { return }
                                
                                do {
                                    let channels = try livesResult.get()
                                        + vodsResult.get()
                                        + seriesResult.get()
                                    completion(.success(channels))
                                } catch {
                                    completion(.failure(error))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func requestInfo(completion: @escaping (Result<InfoResponse, Error>) -> Void) {
        request(url: infoURL(), completion: completion)
    }
    
    private func requestCategories(
        action: String,
        completion: @escaping (Result<[Category], Error>) -> Void
    ) {
        request(url: actionURL(action), completion: completion)
    }
    
    private func requestLives(
        categories: [Category],
        info: InfoResponse,
        completion: @escaping (Result<[IPTVChannel], Error>) -> Void
    ) {
        request(url: actionURL("get_live_streams")) { [weak self] (result: Result<[XtreamLive], Error>) in
            guard let self else { return }
            completion(result.map { lives in
                let extensionName = self.liveExtension(from: info)
                return lives.compactMap { live in
                    guard let streamID = live.streamID else { return nil }
                    return IPTVChannel(
                        id: "\(self.channelIDPrefix)-live-\(streamID)",
                        title: live.name ?? "",
                        url: self.streamURL(path: "live", id: streamID, extensionName: extensionName),
                        imageURL: live.streamIcon ?? "",
                        groupTitle: self.categoryName(for: live.categoryID, categories: categories)
                    )
                }
            })
        }
    }
    
    private func requestVods(
        categories: [Category],
        completion: @escaping (Result<[IPTVChannel], Error>) -> Void
    ) {
        request(url: actionURL("get_vod_streams")) { [weak self] (result: Result<[XtreamVod], Error>) in
            guard let self else { return }
            completion(result.map { vods in
                vods.compactMap { vod in
                    guard let streamID = vod.streamID else { return nil }
                    return IPTVChannel(
                        id: "\(self.channelIDPrefix)-vod-\(streamID)",
                        title: vod.name ?? "",
                        url: self.streamURL(
                            path: "movie",
                            id: streamID,
                            extensionName: vod.containerExtension?.isEmpty == false ? vod.containerExtension! : "mp4"
                        ),
                        imageURL: vod.streamIcon ?? "",
                        groupTitle: self.categoryName(for: vod.categoryID, categories: categories)
                    )
                }
            })
        }
    }
    
    private func requestSeries(
        categories: [Category],
        completion: @escaping (Result<[IPTVChannel], Error>) -> Void
    ) {
        request(url: actionURL("get_series")) { [weak self] (result: Result<[XtreamSeries], Error>) in
            guard let self else { return }
            completion(result.map { series in
                series.compactMap { item in
                    guard let seriesID = item.seriesID else { return nil }
                    return IPTVChannel(
                        id: "\(self.channelIDPrefix)-series-\(seriesID)",
                        title: item.name ?? "",
                        url: self.actionURL("get_series_info", extraQueryItems: [
                            URLQueryItem(name: "series_id", value: "\(seriesID)")
                        ]).absoluteString,
                        imageURL: item.cover ?? "",
                        groupTitle: self.categoryName(for: item.categoryID, categories: categories)
                    )
                }
            })
        }
    }
    
    private func request<T: Decodable>(
        url: URL,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard !isCancelled else { return }
        
        let task = session.dataTask(with: url) { [weak self] data, response, error in
            guard let self, !self.isCancelled else { return }
            
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode,
                  let data else {
                completion(.failure(IPTVPlaylistError.xtreamAccessDenied))
                return
            }
            
            do {
                completion(.success(try self.decoder.decode(T.self, from: data)))
            } catch {
                completion(.failure(error))
            }
        }
        currentTask = task
        task.resume()
    }
    
    private func isValid(_ info: InfoResponse) -> Bool {
        let invalidStatuses = ["disabled", "banned", "expired", "trial_expired"]
        let status = info.userInfo.status?.lowercased()
        return info.userInfo.auth != 0
            && info.userInfo.username?.isEmpty == false
            && !(status.map { invalidStatuses.contains($0) } ?? false)
    }
    
    private func liveExtension(from info: InfoResponse) -> String {
        let formats = info.userInfo.allowedOutputFormats ?? []
        return formats.contains("ts") ? "ts" : (formats.first ?? "ts")
    }
    
    private var channelIDPrefix: String {
        let rawValue = "\(serverURL)|\(username)"
        let encoded = Data(rawValue.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return "xtream-\(encoded.prefix(24))"
    }
    
    private func categoryName(for id: String?, categories: [Category]) -> String {
        guard let id else { return "" }
        return categories.first { $0.categoryID == id }?.categoryName ?? ""
    }
    
    private func infoURL() -> URL {
        actionURL(nil)
    }
    
    private func actionURL(
        _ action: String?,
        extraQueryItems: [URLQueryItem] = []
    ) -> URL {
        var components = URLComponents(url: URL(string: serverURL)!, resolvingAgainstBaseURL: false)!
        components.path = components.path.hasSuffix("/") ? "\(components.path)player_api.php" : "\(components.path)/player_api.php"
        
        var queryItems = [
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "password", value: password)
        ]
        if let action {
            queryItems.append(URLQueryItem(name: "action", value: action))
        }
        queryItems.append(contentsOf: extraQueryItems)
        components.queryItems = queryItems
        
        return components.url!
    }
    
    private func streamURL(path: String, id: Int, extensionName: String) -> String {
        var components = URLComponents(url: URL(string: serverURL)!, resolvingAgainstBaseURL: false)!
        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let streamPath = [basePath, path, username, password, "\(id).\(extensionName)"]
            .filter { !$0.isEmpty }
            .joined(separator: "/")
        components.path = "/\(streamPath)"
        components.queryItems = nil
        return components.url?.absoluteString ?? ""
    }
}

private extension KeyedDecodingContainer {
    func decodeLossyIntIfPresent(forKey key: Key) -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return Int(value)
        }
        return nil
    }
    
    func decodeLossyStringIfPresent(forKey key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return "\(value)"
        }
        return nil
    }
}
