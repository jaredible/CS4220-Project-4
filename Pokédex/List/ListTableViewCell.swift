import UIKit
import struct ObjectLibrary.Pokédex

final class ListTableViewCell: UITableViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    
}

extension ListTableViewCell {
    
    func setup(entry: Pokédex.Entry) {
        titleLabel.text = entry.displayText
    }
    
}
