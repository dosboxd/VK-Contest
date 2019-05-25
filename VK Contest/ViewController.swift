//
//  ViewController.swift
//  VK Contest
//
//  Created by Dosbol Duysekov on 5/15/19.
//  Copyright © 2019 Dosbol Duysekov. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    
    let goal = 2048
    
    var grid = [[Int]]() {
        didSet {
            isGameOver ? showButton() : hideButton()
            collectionView.reloadData()
        }
    }
    
    lazy var tryAgainButton: UIButton = {
        let button = UIButton()
        let attributedString = NSAttributedString(string: "Попробовать еще раз", attributes: [.font: UIFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: UIColor(red: 0.17, green: 0.18, blue: 0.18, alpha: 1.0)])
        button.setAttributedTitle(attributedString, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 5
        button.layer.shadowOpacity = 0.1
        button.addTarget(self, action: #selector(restartTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        return collectionView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupGame()
    }
    
    private func setupViews() {
        view.addSubview(collectionView)
        view.backgroundColor = UIColor.StyleGuide.background.color
        
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint(item: collectionView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: collectionView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: collectionView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: UIScreen.main.bounds.width - 32).isActive = true
        NSLayoutConstraint(item: collectionView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: UIScreen.main.bounds.width - 32).isActive = true
        
        view.addSubview(tryAgainButton)
        
        tryAgainButton.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 11.0, *) {
            NSLayoutConstraint(item: tryAgainButton, attribute: .centerX, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: tryAgainButton, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: -30).isActive = true
        } else {
            NSLayoutConstraint(item: tryAgainButton, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: tryAgainButton, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: -30).isActive = true
        }
        
        let topSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        topSwipe.numberOfTouchesRequired = 1
        topSwipe.direction = .up
        let bottomSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        bottomSwipe.numberOfTouchesRequired = 1
        bottomSwipe.direction = .down
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        leftSwipe.numberOfTouchesRequired = 1
        leftSwipe.direction = .left
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
        rightSwipe.numberOfTouchesRequired = 1
        rightSwipe.direction = .right
        
        view.addGestureRecognizer(topSwipe)
        view.addGestureRecognizer(bottomSwipe)
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
    }
    
    func setupGame() {
        if let savedState = UserDefaults.standard.value(forKey: "SavedState") as? [[Int]] {
            grid = savedState
        } else {
            grid = Array(repeating: Array(repeating: 0, count: 4), count: 4)
            addNumber()
            addNumber()
        }
    }
    
    func addNumber() {
        var options = [(x: Int, y: Int)]()
        for (o, k) in grid.enumerated() {
            for (o2, _) in k.enumerated() {
                if grid[o][o2] == 0 {
                    options.append((x: o, y: o2))
                }
            }
        }
        if !options.isEmpty, let position = options.randomElement() {
            grid[position.x][position.y] = Float(Int.random(in: 0...1)) > 0.1 ? 2 : 4
        }
    }
    
    func flip() {
        for i in 0..<4 {
            grid[i].reverse()
        }
    }
    
    func rotate() -> [[Int]] {
        var blank = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        for (o, k) in blank.enumerated() {
            for (o2, _) in k.enumerated() {
                blank[o][o2] = grid[o2][o]
            }
        }
        return blank
    }
    
    @objc func slideTapped(_ sender: UIButton) {
        guard let direction = Direction(rawValue: sender.tag) else { return }
        slide(direction: direction)
    }
    
    func slide(direction: Direction) {
        
        var flipped = false
        var rotated = false
        
        switch direction {
        case .top:
            grid = rotate()
            flip()
            rotated = true
            flipped = true
        case .bottom:
            grid = rotate()
            rotated = true
        case .left:
            flip()
            flipped = true
        case .right:
            break
        }
        
        let past = grid
        _ = grid.enumerated().map { index, _ in
            grid[index] = move(row: grid[index])
            grid[index] = combine(row: grid[index])
            grid[index] = move(row: grid[index])
        }
        
        if !grid.elementsEqual(past) {
            addNumber()
        }
        
        if flipped {
            flip()
            flipped = false
        }
        
        if rotated {
            grid = rotate()
            grid = rotate()
            grid = rotate()
        }
        
        UserDefaults.standard.set(grid, forKey: "SavedState")
        UserDefaults.standard.synchronize()
    }
    
    func move(row: [Int]) -> [Int] {
        var array = row.filter({$0>0})
        let missing = 4 - array.count
        let zeros = Array(repeating: 0, count: missing)
        array.insert(contentsOf: zeros, at: 0)
        return array
    }
    
    func combine(row: [Int]) -> [Int] {
        var mRow = row
        for (o, _) in mRow.enumerated().reversed() {
            if o > 0 {
                let a = mRow[o]
                let b = mRow[o - 1]
                if a == b {
                    mRow[o] = a + b
                    mRow[o - 1] = 0
                }
            }
        }
        return mRow
    }
    
    var isGameWon: Bool {
        return !grid.flatMap({$0}).filter({$0>=goal}).isEmpty
    }
    
    var isGameOver: Bool {
        
        if isGameWon {
            return true
        }
        
        for (o, k) in grid.enumerated() {
            for (o2, _) in k.enumerated() {
                if grid[o][o2] == 0 {
                    return false
                }
                
                if o != 3 && grid[o][o2] == grid[o + 1][o2] {
                    return false
                }
                
                if o2 != 3 && grid[o][o2] == grid[o][o2 + 1] {
                    return false
                }
            }
        }
        
        return true
    }
    
    @objc func restartTapped() {
        UserDefaults.standard.removeObject(forKey: "SavedState")
        UserDefaults.standard.synchronize()
        
        setupGame()
        hideButton()
    }
    
    @objc func swiped(_ sender: UISwipeGestureRecognizer) {
        guard sender.state == .ended else { return }
        switch sender.direction {
        case .up:
            slide(direction: .top)
        case .down:
            slide(direction: .bottom)
        case .left:
            slide(direction: .left)
        case .right:
            slide(direction: .right)
        default:
            break
        }
    }
    
    func showButton() {
        UIView.animate(withDuration: 0.3) {
            self.tryAgainButton.alpha = 1
        }
    }
    
    func hideButton() {
        UIView.animate(withDuration: 0.3) {
            self.tryAgainButton.alpha = 0
        }
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        let data = grid[indexPath.section][indexPath.row]
        let dataColor = UIColor.StyleGuide(rawValue: data)
        let label = UILabel()
        label.text = dataColor == .some(.empty) ? "" : String(data)
        
        cell.backgroundColor = dataColor?.color
        cell.layer.cornerRadius = 8
        
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        label.textColor = dataColor?.textColor
        
        _ = cell.subviews.map({$0.removeFromSuperview()})
        
        cell.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: cell, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: cell, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: label, attribute: .left, relatedBy: .equal, toItem: cell, attribute: .left, multiplier: 1, constant: 8).isActive = true
        NSLayoutConstraint(item: label, attribute: .right, relatedBy: .equal, toItem: cell, attribute: .right, multiplier: 1, constant: -8).isActive = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width / 4 - 16, height: UIScreen.main.bounds.width / 4 - 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
    }
    
}

extension UIColor {
    enum StyleGuide: Int, CaseIterable {
        case background = -1
        case empty = 0
        case _2 = 2
        case _4 = 4
        case _8 = 8
        case _16 = 16
        case _32 = 32
        case _64 = 64
        case _128 = 128
        case _256 = 256
        case _512 = 512
        case _1024 = 1024
        case _2048 = 2048
        
        var textColor: UIColor {
            if self.rawValue >= 64 {
                return .white
            } else {
                return .black
            }
        }
        
        var color: UIColor {
            switch self {
            case .background:
                return UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
            case .empty:
                return UIColor(red: 0.72, green: 0.76, blue: 0.80, alpha: 1.0)
            case ._2:
                return .white
            case ._4:
                return UIColor(red: 0.88, green: 0.89, blue: 0.90, alpha: 1.0)
            case ._8:
                return UIColor(red: 0.54, green: 0.87, blue: 1.00, alpha: 1.0)
            case ._16:
                return UIColor(red: 0.29, green: 0.69, blue: 1.00, alpha: 1.0)
            case ._32:
                return UIColor(red: 0.00, green: 0.51, blue: 0.94, alpha: 1.0)
            case ._64:
                return UIColor(red: 0.06, green: 0.34, blue: 0.85, alpha: 1.0)
            case ._128:
                return UIColor(red: 0.10, green: 0.22, blue: 0.73, alpha: 1.0)
            case ._256:
                return UIColor(red: 0.12, green: 0.21, blue: 0.53, alpha: 1.0)
            case ._512:
                return UIColor(red: 0.11, green: 0.09, blue: 0.53, alpha: 1.0)
            case ._1024:
                return UIColor(red: 0.17, green: 0.00, blue: 0.73, alpha: 1.0)
            case ._2048:
                return UIColor(red: 0.13, green: 0.00, blue: 0.45, alpha: 1.0)
            }
        }
    }
}

enum Direction: Int {
    case top = 0
    case bottom = 1
    case left = 2
    case right = 3
}
