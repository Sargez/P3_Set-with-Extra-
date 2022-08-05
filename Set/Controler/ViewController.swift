//
//  ViewController.swift
//  Set
//
//  Created by 1C on 30/04/2022.
//

import UIKit

class ViewController: UIViewController {

    var game = Game()
        
    private var player: PlayerMode? {
        didSet {
            game.playerMode = player?.rawValue
            
            switch player {
            case .playerOne :
                SetP1.isEnabled = true
                SetP2.isEnabled = false
                SetP1.isSelected = true
                SetP2.isSelected = false
            case .playerTwo :
                SetP1.isEnabled = false
                SetP2.isEnabled = true
                SetP1.isSelected = false
                SetP2.isSelected = true
            default:
                SetP1.isSelected = false
                SetP2.isSelected = false
                SetP1.isEnabled = true
                SetP2.isEnabled = true
            }
            
        }
    }
    
    private enum PlayerMode: Int {
        case playerOne = 0
        case playerTwo
    }
    
    private var deckCount = 0 { didSet {updateDeckCountLabel()} }
    private var messageText = "" {didSet {messageTextLabel.text = messageText}}
    private var scoreCountPlayerOne = 0 {didSet {updateScoreCountLabelPlayerOne()}}
    private var scoreCountPlayerTwo = 0 {didSet {updateScoreCountLabelPlayerTwo()}}
    private var scoreHints = 0 {didSet {updateHintsTitle()}}
    
    private weak var timerForHints: Timer?
    private weak var timerForPlayer: Timer?
    
    @IBOutlet weak var setTableView: SetTableView! {
        didSet{
        
            let swipeUp = UISwipeGestureRecognizer.init(target: self, action: #selector(swipeUpHandlerOfViewControler(_:)))
            swipeUp.direction = .up
            
            let rotate = UIRotationGestureRecognizer.init(target: self, action: #selector(rotateCardsOnTheTable(_:)))
            
            setTableView.addGestureRecognizer(rotate)
            setTableView.addGestureRecognizer(swipeUp)
            
        }
    }
    @IBOutlet private weak var deal3CardButton: ManageButtonsView!
    @IBOutlet private weak var hints: ManageButtonsView! {didSet {updateHintsTitle()}}
    
    @IBAction func swipeDownGesture(_ sender: UISwipeGestureRecognizer) {
        switch sender.state {
        case .ended :
            deal3Cards()
        default:
            break
        }
    }
        
    @objc func touchCard(_ recognizer: UITapGestureRecognizer) {

        switch recognizer.state {
        case .ended :
            if let playerMode = player, let card = (recognizer.view as? SetCardView)?.setCard {
                timerForHints?.fire()
                game.playerMode = playerMode.rawValue
                game.selectCard(card)
                updateViewFromModel()
            }
        default:
            break
        }

    }
    
    @IBOutlet weak var SetP1: ManageButtonsView!
    @IBOutlet weak var SetP2: ManageButtonsView!
    
    private func lookingForSet(by playerMode: PlayerMode, withInterval interval: TimeInterval) {
            
        timerForHints?.fire()
        
        player = playerMode
         
        updateViewFromModel()
        
        timerForPlayer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false){
            [weak self] timer in
                                    
            if self?.game.setCards.count == 3 {
                let cardView = self?.setTableView.cardsView.filter {!(self?.game.setCards.contains($0.setCard!))!}.first
                if let card = cardView?.setCard {
                    self?.game.selectCard(card)
                }
                self?.player = nil
                self?.updateViewFromModel()
            } else if Constants.playingModeTime != interval/2 {
                self?.updateViewFromModel()
                self?.lookingForSet(by: self?.player == PlayerMode.playerOne ? PlayerMode.playerTwo : PlayerMode.playerOne, withInterval: interval * 2)

            } else {
                self?.player = nil
                self?.updateViewFromModel()
            }
            
            
        }

    }
    
    @IBAction func playerOneLookingForSet(_ sender: ManageButtonsView) {
        timerForPlayer?.invalidate()
        lookingForSet(by: .playerOne, withInterval: TimeInterval(Constants.playingModeTime))
    }
    
    @IBAction func playerTwoLookingForSet(_ sender: ManageButtonsView) {
        timerForPlayer?.invalidate()
        lookingForSet(by: .playerTwo, withInterval: TimeInterval(Constants.playingModeTime))
    }
    
    @IBAction func newGame(_ sender: ManageButtonsView) {
        newGame()
    }
    
    private func newGame() {
        timerForHints?.invalidate()
        timerForPlayer?.invalidate()
        game = Game()
        player = nil
        updateViewFromModel()
    }
    
    @IBAction private func showMeSet(_ sender: ManageButtonsView) {
        
        timerForHints?.invalidate()
        
        if let setToShow = game.findAllSetsOnTheTable().randomElement() {

            setTableView.cardsView.forEach { cardView in
                
                if let card = cardView.setCard, setToShow.contains(card) {
                    cardView.isHinted = true
                } else {
                    cardView.isHinted = false
                }
            }

            timerForHints = Timer.scheduledTimer(withTimeInterval: TimeInterval(Constants.flashingTime), repeats: false) {
                [weak self] timer in
                self!.setTableView.cardsView.forEach { cardView in
                    cardView.isHinted = false
                }

            }
        }
        
    }
    
    @IBAction private func deal3Card(_ sender: ManageButtonsView) {
        deal3Cards()
    }
    
    @IBOutlet private weak var deckCountLabel: UILabel! {didSet {updateDeckCountLabel()}}
    @IBOutlet private weak var messageTextLabel: UILabel! {didSet {messageTextLabel.text = messageText}}
    @IBOutlet private weak var scoreCountLabelPlayerOne: UILabel! {didSet {updateScoreCountLabelPlayerOne()}}
    @IBOutlet private weak var scoreCountLabelPlayerTwo: UILabel! {didSet {updateScoreCountLabelPlayerTwo()}}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateViewFromModel()
                
    }
    
    @objc private func rotateCardsOnTheTable(_ recognizer: UIRotationGestureRecognizer) {
        
        switch recognizer.state {
        case .ended:
            game.rotateCardsOnTheTable()
            updateViewFromModel()
        default:
            break
        }
                
    }
    
    @objc private func swipeUpHandlerOfViewControler(_ recognizer: UISwipeGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            newGame()
        default:
            break
        }
    }
    
    private func deal3Cards() {
        if deckCount > 0, player != nil {
            game.deal3Cards()
            updateViewFromModel()
        }
    }
    
    private func updateViewFromModel() {
        
        updateCardsFromModel()

        var message = ""
        messageText = ""
        
        deckCount = game.deck.cards.count
        deal3CardButton.isEnabled = deckCount != 0 && player != nil
        scoreCountPlayerOne = game.score[0]
        scoreCountPlayerTwo = game.score[1]
        scoreHints = game.findAllSetsOnTheTable().count
        hints.isEnabled = scoreHints > 0

        if game.isGameOver() {
            updateCardsFromModel()
            message = "Game over!!!"
        } else if !game.setCards.isEmpty {
            message = "😆 Set!"
        } else if (game.selectedCards.count == 3 && game.setCards.isEmpty) {
            message = "😡 Ohh No..."
        }

        messageText = message

    }
    
    private func updateCardsFromModel() {
        
        setTableView.cardsView.removeAll()
        
        var cardsViewToAppend:[SetCardView] = []
        
        for cardModel in game.cardsOnTheTable {
            
            let cardView = SetCardView()
            cardView.setCard = cardModel
            cardView.count = cardModel.amount.rawValue
            cardView.symbolInt = cardModel.type.rawValue
            cardView.colorInt = cardModel.color.rawValue
            cardView.fillInt = cardModel.fill.rawValue
            cardView.isSelected = game.isSelected(this: cardModel)
            cardView.isMatched = game.isMatched(this: cardModel)
            cardView.isDismatched = game.isDismatched(this: cardModel)
               
            let tap = UITapGestureRecognizer.init(target: self, action: #selector(touchCard(_:)))
            tap.numberOfTapsRequired = 1
            cardView.addGestureRecognizer(tap)
            
            cardsViewToAppend.append(cardView)
                        
        }
        
        setTableView.cardsView += cardsViewToAppend
        
    }
    
    private func updateDeckCountLabel() {
        deckCountLabel.text = "Deck: \(deckCount)"
    }
  
    private func updateScoreCountLabelPlayerOne() {
        scoreCountLabelPlayerOne.text = "Score P1: \(scoreCountPlayerOne)"
    }
    
    private func updateScoreCountLabelPlayerTwo() {
        scoreCountLabelPlayerTwo.text = "Score P2: \(scoreCountPlayerTwo)"
    }
    
    private func updateHintsTitle() {
        hints.setTitle("Hints:\(scoreHints)", for: UIControl.State.normal)
    }
    
    private struct Constants {
        static let flashingTime = 3.0
        static let playingModeTime = 5.0
    }
    
}

