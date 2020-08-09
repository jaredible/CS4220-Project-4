import UIKit
import ObjectLibrary
import class AVFoundation.AVAudioPlayer

final class ListViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    private var model: ListModel!
    private let searchController = UISearchController(searchResultsController: nil)
    private var isFiltering: Bool { searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true) }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureModel()
        configureSearchController()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let detailViewController = segue.destination as? DetailViewController else { return }
        detailViewController.pokémon = sender as? Pokémon
    }
    
}

extension ListViewController {
    
    private func configureModel() {
        model = ListModel(
            pokédexPersistence: PokédexPersistence(directoryName: "Pokédex"),
            pokémonPersistence: PokémonPersistence(directoryName: "Pokémon"),
            serviceClient: PokéAPIServiceClient.instance,
            delegate: self
        )
        model.loadPokédex()
    }
    
}

extension ListViewController {
    
    private func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
}

extension ListViewController: ListModelDelegate {
    
    func willDownload() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.activityIndicator.startAnimating()
        }
    }
    
    func didDownload(error: ServiceCallError?, reloadData: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            if reloadData {
                strongSelf.tableView.reloadData()
            }
            
            if error != nil {
                strongSelf.presentSingleActionAlert(alerTitle: "Error", message: error?.message ?? "", actionTitle: "OK", completion: {})
            }
            
            strongSelf.activityIndicator.stopAnimating()
        }
    }
    
    func show(_ pokémon: Pokémon) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.performSegue(withIdentifier: "ShowDetail", sender: pokémon)
        }
    }
    
}

extension ListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        model.loadPokémon(for: indexPath, isFiltering: isFiltering)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension ListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let numberOfSections = model.numberOfSections(isFiltering: isFiltering)
        
        if numberOfSections == 0 {
            tableView.addEmptyListLabel(withText: "No Pokémon", adjustSeparatorStyle: true)
        } else {
            tableView.removeEmptyListLabel()
        }
        
        return numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model.numberOfRows(in: section, isFiltering: isFiltering)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "pokémon") as! ListTableViewCell
        cell.setup(entry: model.pokémon(for: indexPath, isFiltering: isFiltering))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return model.titleForHeader(in: section, isFiltering: isFiltering)
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return model.sectionIndexTitles
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return model.section(for: title, index: index, isFiltering: isFiltering)
    }

}

extension ListViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        let text = searchController.searchBar.text ?? ""
        model.filterContentForSearchText(text)
        tableView.reloadData()
    }
    
}
