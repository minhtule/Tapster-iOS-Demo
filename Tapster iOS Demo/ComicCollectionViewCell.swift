//
//  ComicCollectionViewCell.swift
//  Tapster iOS Demo
//
//  Created by Minh Tu Le on 3/27/15.
//  Copyright (c) 2015 PredictionIO. All rights reserved.
//

import UIKit
import Alamofire

let ComicCellReuseIdentifier = "ComicCellReuseIdentifier"
let ComicImageCellReuseIdentifier = "ComicImageCellReuseIdentifier"

class ComicCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var overlayView: UIView!
    
    let imageCache = NSCache()
    
    override func awakeFromNib() {
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 20)
        layer.masksToBounds = false
    }
    
    var comic: Comic! {
        didSet {
            imagesCollectionView.reloadData()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        // clean up things here
        imagesCollectionView.contentSize = frame.size
        imagesCollectionView.contentOffset = CGPoint(x: 0, y: 0)
        imageCache.removeAllObjects()
    }
}

extension ComicCollectionViewCell: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comic.imageURLs.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ComicImageCellReuseIdentifier, forIndexPath: indexPath) as! ComicImageCollectionViewCell
        let imageURL = comic.imageURLs[indexPath.item]
        cell.position = indexPath.item
        cell.delegate = self
        cell.image = imageCache.objectForKey(imageURL) as? UIImage
        cell.imageURL = imageURL
        return cell
    }
}

extension ComicCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        // If the image is already downloaded, use the image aspect ratio to calculate the height
        let imageURL = comic.imageURLs[indexPath.item]
        let width = collectionView.bounds.size.width
        
        if let image = imageCache.objectForKey(imageURL) as? UIImage {
            return CGSize(width: width, height: width / image.aspectRatio)
        }
        
        // Otherwise, use the width as height
        return CGSize(width: width, height: width)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let overlayViewHeight = overlayView.frame.height

        // Give a padding empty space so that the last comic image is displayed above the overlay.
        return UIEdgeInsetsMake(0, 0, overlayViewHeight, 0)
    }
}

extension ComicCollectionViewCell : ComicImageCollectionViewCellDelegate {
    func comicImageCollectionViewCellDidLoadImage(cell: ComicImageCollectionViewCell) {
        if imageCache.objectForKey(cell.imageURL) == nil {
            imageCache.setObject(cell.image, forKey: cell.imageURL)
        }
        
        // Refresh the layout
        imagesCollectionView.collectionViewLayout.invalidateLayout()
    }
}


// MARK: - ComicImageCollectionViewFlowLayout

class ComicImageCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func invalidationContextForBoundsChange(newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContextForBoundsChange(newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = true
        return context
    }
}


// MARK: - ComicImageCollectionViewCell

protocol ComicImageCollectionViewCellDelegate: class {
    func comicImageCollectionViewCellDidLoadImage(cell: ComicImageCollectionViewCell)
}

class ComicImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!

    var position: Int!
    var image: UIImage!
    weak var delegate: ComicImageCollectionViewCellDelegate?
    var request: Request!

    
    var imageURL: String! {
        didSet {            
            if image != nil {
                imageView.contentMode = .ScaleAspectFit
                imageView.image = image
            } else {
                request = Alamofire.request(.GET, imageURL).responseImage { (request, _, image, error) in
                    if error == nil && image != nil && request.URLString == self.imageURL {
                        self.image = image
                        self.imageView.contentMode = .ScaleAspectFit
                        self.imageView.image = image!
                        self.delegate?.comicImageCollectionViewCellDidLoadImage(self)
                    }
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        request?.cancel()
        position = nil
        image = nil
        imageView.contentMode = .Center
        imageView.image = UIImage(named: "refresh")
        delegate = nil
    }
}
