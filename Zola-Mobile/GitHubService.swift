// GitHubService.swift
import Foundation

class GitHubService {
    static let shared = GitHubService()
    
    private let owner = "linxz-coder"
    private let repo = "zola-basic"
    private let branch = "main"
//    private let path = "content/blog"
    private let token: String
    
    init() {
        // 从配置文件中读取 token
        guard let token = Bundle.main.object(forInfoDictionaryKey: "GITHUB_API_TOKEN") as? String else {
            fatalError("GitHub token not found in configuration")
        }
        self.token = token
    }
    
    func uploadContent(content: String, filename: String, path: String = "content/blog", completion: @escaping (Result<Void, Error>) -> Void) {
        let endpoint = "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)/\(filename)"
        
        guard let url = URL(string: endpoint),
              let contentData = content.data(using: .utf8) else {
            completion(.failure(NSError(domain: "", code: -1)))
            return
        }
        
        let base64Content = contentData.base64EncodedString()
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "message": "Add new blog post",
            "content": base64Content,
            "branch": branch
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "", code: -1)))
            }
        }.resume()
    }
}
