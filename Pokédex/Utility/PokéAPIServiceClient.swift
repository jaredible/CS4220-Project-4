import ObjectLibrary
import class Foundation.JSONDecoder
import struct Foundation.URL

final class PokéAPIServiceClient {
    
    static var instance: PokéAPIServiceClient { .init(baseServiceClient: BaseServiceClient(), urlProvider: URLProvider()) }
    
    private let baseServiceClient: BaseServiceClient
    private let urlProvider: URLProvider
    
    private init(baseServiceClient: BaseServiceClient, urlProvider: URLProvider) {
        self.baseServiceClient = baseServiceClient
        self.urlProvider = urlProvider
    }
    
    func getPokédex(completion: @escaping (PokédexResult) -> ()) {
        let pokéAPIURL = URL(string: "https://pokeapi.co")!
        let pathComponents = ["api", "v2", "pokemon"]
        let parameters = ["offset": "0", "limit": "964"]
        let url = urlProvider.url(forBaseURL: pokéAPIURL, pathComponents: pathComponents, parameters: parameters)
        
        baseServiceClient.get(from: url, completion: { result in
            switch result {
            case .success(let data):
                if let pokédex = try? JSONDecoder().decode(Pokédex.self, from: data) {
                    completion(.success(pokédex))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
    
    func getPokémon(fromUrl url: URL, completion: @escaping (PokémonResult) -> ()) {
        baseServiceClient.get(from: url, completion: { result in
            switch result {
            case .success(let data):
                if let servicePokémon = try? JSONDecoder().decode(ServicePokémon.self, from: data) {
                    self.getSprite(for: servicePokémon, completion: { result in
                        completion(result)
                    })
                }
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
    
}

extension PokéAPIServiceClient {
    
    private func getSprite(for servicePokémon: ServicePokémon, completion: @escaping (PokémonResult) -> ()) {
        let url = servicePokémon.spriteUrl
        
        baseServiceClient.get(from: url, completion: { result in
            switch result {
            case .success(let data):
                let pokémon = Pokémon(servicePokémon: servicePokémon, sprite: data)
                completion(.success(pokémon))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
    
}
