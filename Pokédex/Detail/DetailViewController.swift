import UIKit
import class AVFoundation.AVAudioPlayer
import struct ObjectLibrary.Pokémon

final class DetailViewController: UIViewController {
    
    @IBOutlet private weak var pokémonImage: UIImageView!
    @IBOutlet private weak var heightLabel: UILabel!
    @IBOutlet private weak var typesLabel: UILabel!
    
    var pokémon: Pokémon!
    private var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = pokémon.displayName
        pokémonImage.image = pokémon.image
        heightLabel.text = "Height: \(pokémon.height)"
        typesLabel.text = "Types: \(pokémon.displayTypes)"
        
        NSDataAsset(name: pokémon.displayName).flatMap {
            audioPlayer = try? AVAudioPlayer(data: $0.data, fileTypeHint: "wav")
        }
    }
    
    @IBAction private func playButtonTapped(_ sender: Any) {
        if let audioPlayer = self.audioPlayer {
            audioPlayer.play()
            return
        }
        
        presentSingleActionAlert(alerTitle: "", message: "Audio not available", actionTitle: "OK", completion: {})
    }
    
}
