import struct Foundation.URL
import class Foundation.FileManager
import struct ObjectLibrary.Pokémon
import protocol ObjectLibrary.FileStoragePersistence

final class PokémonPersistence: FileStoragePersistence {
    
    let directoryURL: URL
    let fileType: String = "json"
    
    public init(directoryName: String) {
        self.directoryURL = FileManager.default.directoryInUserLibrary(named: directoryName)
    }
    
    func save(_ pokémon: Pokémon) {
        save(pokémon, withId: pokémon.name)
    }
    
    func pokémon(named name: String) -> Pokémon? {
        return read(url: directoryURL.appendingPathComponent(name).appendingPathExtension(fileType))
    }
    
}
