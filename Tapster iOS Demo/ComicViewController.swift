//
//  ComicViewController.swift
//  Tapster iOS Demo
//
//  Created by Minh Tu Le on 3/23/15.
//  Copyright (c) 2015 PredictionIO. All rights reserved.
//

import UIKit
import Alamofire
import ObjectMapper
import PredictionIOSDK

class ComicViewController : UIViewController {
    
    @IBOutlet weak var collectionView: CustomCollectionView!
    @IBOutlet weak var collectionViewLayout: ComicCollectionViewLayout!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var dislikeButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    
    // This data is only for initialized some comics at the beginning
    // so we use the smaller list to reduce the loading time.
    lazy var comicsData: CSVData = CSVData(fileName: "seed_episode_list")
    
    let engineClient = EngineClient()
    var directionComicDeleted: Direction = .Right
    var likedComicIDs = [String]()
    var displayedComicIDs = [String]()
    var comics = [Comic]()
    var isAnimating = false


    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.viewForBaselineLayout()?.layer.speed = 0.75
        collectionView.customDelegate = self
        collectionViewLayout.delegate = self

        dislikeButton.imageView?.contentMode = .ScaleAspectFit
        likeButton.imageView?.contentMode = .ScaleAspectFit
        
        // Start with 2 random comics
        comics = randomizeComics(numberOfComics: 2)
        displayedComicIDs.extend(comics.map { $0.ID })
    }
    
    @IBAction func handleSwipeRightGesture(sender: UISwipeGestureRecognizer) {
        if !shouldAcceptGesture() {
            return
        }
        
        likeComic()
    }
    
    @IBAction func handleSwipeLeftGesture(sender: UISwipeGestureRecognizer) {
        if !shouldAcceptGesture() {
            return
        }
        
        dislikeComic()
    }
    
    @IBAction func likeButtonAction(sender: UIButton) {
        if !shouldAcceptGesture() {
            return
        }
        
        likeComic()
    }
    
    @IBAction func dislikeButtonAction(sender: UIButton) {
        if !shouldAcceptGesture() {
            return
        }
        
        dislikeComic()
    }
    
    private func shouldAcceptGesture() -> Bool {
        return comics.count > 0 && !isAnimating
    }
    
    private func likeComic() {
        likedComicIDs.append(comics[0].ID)
        directionComicDeleted = .Right
        updateComics()
    }
    
    private func dislikeComic() {
        directionComicDeleted = .Left
        updateComics()
    }
    
    private func updateComics() {
        let comicIDs = comics.map { $0.ID }
        println("current comics: \(comicIDs)")
        comics.removeAtIndex(0)
        
        // Animate the removal of the top comic
        isAnimating = true
        collectionView.performBatchUpdates({
            self.collectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: 0, inSection: 0)])
        }, completion: { (finished) in
            self.isAnimating = false
        })
        
        // We can't query PredictionIO with no likes,
        // so we just add a new random comic
        if likedComicIDs.isEmpty {
            let comic = randomizeComics(numberOfComics: 1)[0]
            addAndAnimateNewComic(comic)
            
            return
        }
        
        println("querying ...")
        println("liked: \(likedComicIDs)")
        println("blackList: \(displayedComicIDs)")
        let query: [String: NSObject] = [
            "num": 1,
            "items": likedComicIDs,
            "blackList": displayedComicIDs
        ]
        
        engineClient.sendQuery(query, completionHandler: { (request, response, data, error) in
            if let result = Mapper<Result>().map(data) {
                if result.comics.count > 0 {
                    self.addAndAnimateNewComic(result.comics[0])
                }
            }
        })
    }
    
    private func addAndAnimateNewComic(comic: Comic) {
        comics.append(comic)
        displayedComicIDs.append(comic.ID)
        collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: comics.count - 1, inSection: 0)])
    }
    
    private func randomizeComics(numberOfComics: Int = 2) -> [Comic] {
        var randomizedNumbers = [Int:Bool]()
        
        while randomizedNumbers.count < numberOfComics {
            let random = Int(arc4random_uniform(UInt32(comicsData.rows.count)))
            randomizedNumbers[random] = true
        }
        
        return map(randomizedNumbers.keys) { (rowIndex: Int) -> Comic in
            let row = self.comicsData.rows[rowIndex]

            return Comic(
                ID: row[0],
                title: row[1],
                imageURLs: row[4].componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: ";")),
                score: 0)
        }
    }
}

extension ComicViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comics.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ComicCellReuseIdentifier, forIndexPath: indexPath) as! ComicCollectionViewCell
        cell.comic = comics[indexPath.item]
        
        return cell
    }
}

extension ComicViewController: CustomCollectionViewDelegate {
    func collectionViewDidReloadData(collectionView: CustomCollectionView) {
        updateNavigationItemTitle()
    }
    
    func collectionView(collectionView: CustomCollectionView, didInsertItemsAtIndexPaths indexPaths: [AnyObject]) {
        updateNavigationItemTitle()
    }
    
    func collectionView(collectionView: CustomCollectionView, didDeleteItemsAtIndexPaths indexPaths: [AnyObject]) {
        updateNavigationItemTitle()
    }
    
    private func updateNavigationItemTitle() {
        if self.comics.count > 0 {
            self.navigationItem.title = self.comics[0].title
        } else {
            self.navigationItem.title = ""
        }
    }
}

extension ComicViewController: ComicCollectionViewLayoutDelegate {
    func directionToDeleteItem() -> Direction {
        return directionComicDeleted
    }
}


// MARK: CustomCollectionView

protocol CustomCollectionViewDelegate: class {
    func collectionViewDidReloadData(collectionView: CustomCollectionView)
    func collectionView(collectionView: CustomCollectionView, didInsertItemsAtIndexPaths indexPaths: [AnyObject])
    func collectionView(collectionView: CustomCollectionView, didDeleteItemsAtIndexPaths indexPaths: [AnyObject])
}

class CustomCollectionView: UICollectionView {
    var customDelegate: CustomCollectionViewDelegate?
    
    override func reloadData() {
        super.reloadData()
        self.customDelegate?.collectionViewDidReloadData(self)
    }
    
    override func insertItemsAtIndexPaths(indexPaths: [AnyObject]) {
        super.insertItemsAtIndexPaths(indexPaths)
        self.customDelegate?.collectionView(self, didInsertItemsAtIndexPaths: indexPaths)
    }
    
    override func deleteItemsAtIndexPaths(indexPaths: [AnyObject]) {
        super.deleteItemsAtIndexPaths(indexPaths)
        self.customDelegate?.collectionView(self, didDeleteItemsAtIndexPaths: indexPaths)
    }
}


// MARK: Layout

enum Direction {
    case Left, Up, Right, Down
}

protocol ComicCollectionViewLayoutDelegate: class {
    func directionToDeleteItem() -> Direction
}

class ComicCollectionViewLayout : UICollectionViewLayout {
    let xDisappearingOffsetScale: CGFloat = 1.5
    var delegate: ComicCollectionViewLayoutDelegate?
    var removedIndexPaths = [NSIndexPath]()
    
    override func collectionViewContentSize() -> CGSize {
        return collectionView!.bounds.size
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        let oldBounds = collectionView!.bounds
        if CGRectEqualToRect(oldBounds, newBounds) {
            return false
        }
        return true
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
        // Only display the first 2 commics
        let numberOfComicsDisplayed = min(collectionView!.numberOfItemsInSection(0), 2)
        return map(0..<numberOfComicsDisplayed) {
            self.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: $0, inSection: 0))
        }
    }
    
    override func prepareForCollectionViewUpdates(updateItems: [AnyObject]!) {
        super.prepareForCollectionViewUpdates(updateItems)
        
        var removedIndexPaths = [NSIndexPath]()
        
        for updateItem in updateItems as! [UICollectionViewUpdateItem] {
            switch updateItem.updateAction {
            case .Delete:
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
    
    override func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        var layoutAttributes = super.finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath)
        
        if itemIndexPath.item == 0 && contains(removedIndexPaths, itemIndexPath) {
            layoutAttributes = layoutAttributesForItemAtIndexPath(itemIndexPath)
            let dx: CGFloat = {
                // We calculate dx with a certain such that the final position is complete 
                // off the screen, including the shadow. So when the cell is removed, 
                // there's no sudden disappearing.
                switch self.delegate?.directionToDeleteItem() {
                case .Some(.Left):
                    return -layoutAttributes!.size.width * self.xDisappearingOffsetScale
                case .Some(.Right):
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
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        let scale = CGFloat(2 - indexPath.item) / 2.0
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)

        layoutAttributes.size = collectionView!.frame.size
        layoutAttributes.center = CGPoint(x: CGRectGetMidX(collectionView!.bounds), y: CGRectGetMidY(collectionView!.bounds))
        layoutAttributes.zIndex = -indexPath.item
        layoutAttributes.transform = CGAffineTransformMakeScale(scale, scale)
        
        return layoutAttributes
    }
}
