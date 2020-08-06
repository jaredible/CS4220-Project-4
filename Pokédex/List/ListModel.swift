import UIKit
import ObjectLibrary

protocol ListModelDelegate: class {
    func willDownload()
    func didDownload(error: ServiceCallError?, reloadData: Bool)
    func show(_ pokémon: Pokémon)
}

final class ListModel {
    
    private let pokédexPersistence: PokédexPersistence
    private let pokémonPersistence: PokémonPersistence
    private let serviceClient: PokéAPIServiceClient
    private weak var delegate: ListModelDelegate?
    
    private let collation = UILocalizedIndexedCollation.current()
    private var pokémon: [Pokédex.Entry] = [] { didSet { sortSections() }}
    private var sections: [Section] = []
    private var filteredSections: [Section] = []
    
    var sectionIndexTitles: [String] { collation.sectionIndexTitles }
    
    init(pokédexPersistence: PokédexPersistence, pokémonPersistence: PokémonPersistence, serviceClient: PokéAPIServiceClient, delegate: ListModelDelegate) {
        self.pokédexPersistence = pokédexPersistence
        self.pokémonPersistence = pokémonPersistence
        self.serviceClient = serviceClient
        self.delegate = delegate
    }
    
    func loadPokédex() {
        guard let pokédex = pokédexPersistence.pokédex else {
            delegate?.willDownload()
            serviceClient.getPokédex(completion: { result in
                switch result {
                case .success(let pokédex):
                    self.pokémon = pokédex.entries
                    self.pokédexPersistence.save(pokédex)
                    self.delegate?.didDownload(error: nil, reloadData: true)
                case .failure(let error):
                    self.delegate?.didDownload(error: error, reloadData: false)
                }
            })
            return
        }
        
        pokémon = pokédex.entries
    }
    
    func loadPokémon(for indexPath: IndexPath, isFiltering: Bool) {
        let entry = pokémon(for: indexPath, isFiltering: isFiltering)
        guard let pokémon = pokémonPersistence.pokémon(named: entry.name) else {
            delegate?.willDownload()
            serviceClient.getPokémon(fromUrl: entry.url, completion: { result in
                switch result {
                case .success(let pokémon):
                    self.pokémonPersistence.save(pokémon)
                    self.delegate?.didDownload(error: nil, reloadData: true)
                    self.delegate?.show(pokémon)
                case .failure(let error):
                    self.delegate?.didDownload(error: error, reloadData: false)
                }
            })
            return
        }
        
        delegate?.show(pokémon)
    }
    
    func pokémon(for indexPath: IndexPath, isFiltering: Bool) -> Pokédex.Entry {
        return sections(for: isFiltering)[indexPath.section].pokémon[indexPath.row]
    }
    
    func numberOfSections(isFiltering: Bool) -> Int {
        return sections(for: isFiltering).count
    }
    
    func numberOfRows(in section: Int, isFiltering: Bool) -> Int {
        return sections(for: isFiltering)[section].pokémon.count
    }
    
    func titleForHeader(in section: Int, isFiltering: Bool) -> String? {
        guard pokémon.count > 5 else { return nil }
        
        return sections(for: isFiltering)[section].title
    }
    
    func section(for title: String, index: Int, isFiltering: Bool) -> Int {
        return sections(for: isFiltering).firstIndex(where: { $0.title == title }) ?? index
    }
    
    func filterContentForSearchText(_ searchText: String) {
        let searchTerms = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { $0 != "" }
        
        filteredSections = sections.compactMap { $0.filtered(by: searchTerms) }
    }
    
}

extension ListModel {
    
    private func sections(for isFiltering: Bool) -> [Section] {
        return isFiltering ? filteredSections : sections
    }
    
    private func sortSections() {
        let selector: Selector = #selector(getter: Pokédex.Entry.collationString)
        //swiftlint:disable:next force_cast
        let sortedPokémon = collation.sortedArray(from: pokémon, collationStringSelector: selector) as! [Pokédex.Entry]
        let sectionedPokémon: [[Pokédex.Entry]] = sortedPokémon.reduce(into: Array(repeating: [], count: collation.sectionTitles.count)) {
            let index = collation.section(for: $1, collationStringSelector: selector)
            $0[index].append($1)
        }
        
        sections = collation.sectionTitles.enumerated().compactMap {
            let pokémon = sectionedPokémon[$0.offset]
            return Section(title: $0.element, pokémon: pokémon)
        }
    }
    
}

extension ListModel {
    
    private struct Section {
        let title: String
        let pokémon: [Pokédex.Entry]
        
        init?(title: String, pokémon: [Pokédex.Entry]) {
            guard !pokémon.isEmpty else { return nil }
            
            self.title = title
            self.pokémon = pokémon
        }

        func filtered(by searchTerms: [String]) -> Section? {
            let pokémon = self.pokémon.filter { $0.displayText.contains(elements: searchTerms) }
            return Section(title: title, pokémon: pokémon)
        }
    }
    
}
