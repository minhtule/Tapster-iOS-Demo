//
//  ComicViewController.swift
//  Tapster iOS Demo
//
//  Created by Minh Tu Le on 3/23/15.
//  Copyright (c) 2015 PredictionIO. All rights reserved.
//

import UIKit
import Alamofire
import PredictionIO

class ComicViewController: UIViewController {

    @IBOutlet weak var collectionView: CustomCollectionView!
    @IBOutlet weak var collectionViewLayout: ComicCollectionViewLayout!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!

    // This data is only for initialized some comics at the beginning
    // so we use the smaller list to reduce the loading time.
    lazy var comicsData: CSVData = CSVData(fileName: "seed_episode_list")

    let engineClient = EngineClient()
    var directionComicDeleted: Direction = .right
    var likedComicIDs = [String]()
    var displayedComicIDs = [String]()
    var comics = [Comic]()
    var isAnimating = false

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.layer.speed = 0.75
        collectionView.customDelegate = self
        collectionViewLayout.delegate = self

        dislikeButton.imageView?.contentMode = .scaleAspectFit
        likeButton.imageView?.contentMode = .scaleAspectFit

        // Start with 2 random comics
        comics = randomizeComics(numberOfComics: 2)
        displayedComicIDs += comics.map { $0.id }
    }

    @IBAction func handleSwipeRightGesture(_ sender: UISwipeGestureRecognizer) {
        if !shouldAcceptGesture() {
            return
        }

        likeComic()
    }

    @IBAction func handleSwipeLeftGesture(_ sender: UISwipeGestureRecognizer) {
        if !shouldAcceptGesture() {
            return
        }

        dislikeComic()
    }

    @IBAction func likeButtonAction(_ sender: UIButton) {
        if !shouldAcceptGesture() {
            return
        }

        likeComic()
    }

    @IBAction func dislikeButtonAction(_ sender: UIButton) {
        if !shouldAcceptGesture() {
            return
        }

        dislikeComic()
    }

    private func shouldAcceptGesture() -> Bool {
        return !comics.isEmpty && !isAnimating
    }

    private func likeComic() {
        likedComicIDs.append(comics[0].id)
        directionComicDeleted = .right
        updateComics()
    }

    private func dislikeComic() {
        directionComicDeleted = .left
        updateComics()
    }

    private func updateComics() {
        let comicIDs = comics.map { $0.id }
        print("current comics: \(comicIDs)")
        comics.remove(at: 0)

        // Animate the removal of the top comic
        isAnimating = true
        collectionView.performBatchUpdates({
            self.collectionView.deleteItems(at: [IndexPath(item: 0, section: 0)])
        }, completion: { _ in
            self.isAnimating = false
        })

        // We can't query PredictionIO with no likes,
        // so we just add a new random comic
        if likedComicIDs.isEmpty {
            let comic = randomizeComics(numberOfComics: 1)[0]
            addAndAnimateNewComic(comic)

            return
        }

        print("querying ...")
        print("liked: \(likedComicIDs)")
        print("blackList: \(displayedComicIDs)")
        let query: [String: Any] = [
            "num": 1,
            "items": likedComicIDs,
            "blackList": displayedComicIDs
        ]

        engineClient.sendQuery(query, responseType: RecommendationResponse.self) { result in
            guard case let .success(response) = result, !response.comics.isEmpty else { return }

            DispatchQueue.main.async {
                self.addAndAnimateNewComic(response.comics[0])
            }
        }
    }

    private func addAndAnimateNewComic(_ comic: Comic) {
        comics.append(comic)
        displayedComicIDs.append(comic.id)
        collectionView.insertItems(at: [IndexPath(item: comics.count - 1, section: 0)])
    }

    private func randomizeComics(numberOfComics: Int = 2) -> [Comic] {
        var randomizedNumbers = [Int: Bool]()

        while randomizedNumbers.count < numberOfComics {
            let random = Int(arc4random_uniform(UInt32(comicsData.rows.count)))
            randomizedNumbers[random] = true
        }

        return randomizedNumbers.keys.map { rowIndex in
            let row = self.comicsData.rows[rowIndex]

            return Comic(
                id: row[0],
                title: row[1],
                imageURLs: row[4].components(separatedBy: CharacterSet(charactersIn: ";")),
                score: 0)
        }
    }
}

extension ComicViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comics.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: comicCellReuseIdentifier, for: indexPath) as! ComicCollectionViewCell
        cell.comic = comics[indexPath.item]

        return cell
    }
}

extension ComicViewController: CustomCollectionViewDelegate {
    func collectionViewDidReloadData(_ collectionView: CustomCollectionView) {
        updateNavigationItemTitle()
    }

    func collectionView(_ collectionView: CustomCollectionView, didInsertItemsAt indexPaths: [IndexPath]) {
        updateNavigationItemTitle()
    }

    func collectionView(_ collectionView: CustomCollectionView, didDeleteItemsAt indexPaths: [IndexPath]) {
        updateNavigationItemTitle()
    }

    private func updateNavigationItemTitle() {
        self.navigationItem.title = self.comics.isEmpty ? "" : self.comics[0].title
    }
}

extension ComicViewController: ComicCollectionViewLayoutDelegate {
    func directionToDeleteItem() -> Direction {
        return directionComicDeleted
    }
}

// MARK: CustomCollectionView

protocol CustomCollectionViewDelegate: class {
    func collectionViewDidReloadData(_ collectionView: CustomCollectionView)
    func collectionView(_ collectionView: CustomCollectionView, didInsertItemsAt indexPaths: [IndexPath])
    func collectionView(_ collectionView: CustomCollectionView, didDeleteItemsAt indexPaths: [IndexPath])
}

class CustomCollectionView: UICollectionView {
    weak var customDelegate: CustomCollectionViewDelegate?

    override func reloadData() {
        super.reloadData()
        self.customDelegate?.collectionViewDidReloadData(self)
    }

    override func insertItems(at indexPaths: [IndexPath]) {
        super.insertItems(at: indexPaths)
        self.customDelegate?.collectionView(self, didInsertItemsAt: indexPaths)
    }

    override func deleteItems(at indexPaths: [IndexPath]) {
        super.deleteItems(at: indexPaths)
        self.customDelegate?.collectionView(self, didDeleteItemsAt: indexPaths)
    }
}

// MARK: Layout

enum Direction {
    case left, up, right, down
}

protocol ComicCollectionViewLayoutDelegate: class {
    func directionToDeleteItem() -> Direction
}

class ComicCollectionViewLayout: UICollectionViewLayout {
    let xDisappearingOffsetScale: CGFloat = 1.5
    weak var delegate: ComicCollectionViewLayoutDelegate?
    var removedIndexPaths = [IndexPath]()

    override var collectionViewContentSize: CGSize {
        return collectionView!.bounds.size
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let oldBounds = collectionView!.bounds
        if oldBounds == newBounds {
            return false
        }
        return true
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // Only display the first 2 commics
        let numberOfComicsDisplayed = min(collectionView!.numberOfItems(inSection: 0), 2)
        return (0..<numberOfComicsDisplayed).map {
            self.layoutAttributesForItem(at: IndexPath(item: $0, section: 0))
        }
    }

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)

        var removedIndexPaths = [IndexPath]()

        for updateItem in updateItems {
            switch updateItem.updateAction {
            case .delete:
                removedIndexPaths.append(updateItem.indexPathBeforeUpdate!)
            default:
                break
            }
        }

        self.removedIndexPaths = removedIndexPaths
    }

    override func finalize() {
        self.removedIndexPaths = []
    }

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        var layoutAttributes = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)

        if itemIndexPath.item == 0 && removedIndexPaths.contains(itemIndexPath) {
            layoutAttributes = layoutAttributesForItem(at: itemIndexPath)
            let dx: CGFloat = {
                // We calculate dx with a certain such that the final position is complete 
                // off the screen, including the shadow. So when the cell is removed, 
                // there's no sudden disappearing.
                switch self.delegate?.directionToDeleteItem() {
                case .some(.left):
                    return -layoutAttributes!.size.width * self.xDisappearingOffsetScale
                case .some(.right):
                    return layoutAttributes!.size.width * self.xDisappearingOffsetScale
                default:
                    return 0
                }
            }()

            layoutAttributes!.transform3D = CATransform3DMakeTranslation(0, 0, 1)
            layoutAttributes!.center = layoutAttributes!.center.translate(dx: dx, dy: 0)
        }

        return layoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let scale = CGFloat(2 - indexPath.item) / 2.0
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

        layoutAttributes.size = collectionView!.frame.size
        layoutAttributes.center = CGPoint(x: collectionView!.bounds.midX, y: collectionView!.bounds.midY)
        layoutAttributes.zIndex = -indexPath.item
        layoutAttributes.transform = CGAffineTransform(scaleX: scale, y: scale)

        return layoutAttributes
    }
}
