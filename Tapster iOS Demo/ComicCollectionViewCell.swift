//
//  ComicCollectionViewCell.swift
//  Tapster iOS Demo
//
//  Created by Minh Tu Le on 3/27/15.
//  Copyright (c) 2015 PredictionIO. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage

let comicCellReuseIdentifier = "ComicCellReuseIdentifier"
let comicImageCellReuseIdentifier = "ComicImageCellReuseIdentifier"

class ComicCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imagesCollectionView: UICollectionView!
    @IBOutlet weak var overlayView: UIView!

    let imageCache = NSCache<NSString, AnyObject>()

    override func awakeFromNib() {
        super.awakeFromNib()

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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comic.imageURLs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: comicImageCellReuseIdentifier, for: indexPath) as! ComicImageCollectionViewCell
        let imageURL = comic.imageURLs[indexPath.item]
        cell.position = indexPath.item
        cell.delegate = self
        cell.image = imageCache.object(forKey: imageURL as NSString) as? UIImage
        cell.imageURL = imageURL
        return cell
    }
}

extension ComicCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // If the image is already downloaded, use the image aspect ratio to calculate the height
        let imageURL = comic.imageURLs[indexPath.item]
        let width = collectionView.bounds.size.width

        if let image = imageCache.object(forKey: imageURL as NSString) as? UIImage {
            return CGSize(width: width, height: width / image.aspectRatio)
        }

        // Otherwise, use the width as height
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let overlayViewHeight = overlayView.frame.height

        // Give a padding empty space so that the last comic image is displayed above the overlay.
        return UIEdgeInsets(top: 0, left: 0, bottom: overlayViewHeight, right: 0)
    }
}

extension ComicCollectionViewCell: ComicImageCollectionViewCellDelegate {
    func comicImageCollectionViewCellDidLoadImage(_ cell: ComicImageCollectionViewCell) {
        if imageCache.object(forKey: cell.imageURL as NSString) == nil {
            imageCache.setObject(cell.image, forKey: cell.imageURL as NSString)
        }

        // Refresh the layout
        imagesCollectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: - ComicImageCollectionViewFlowLayout

class ComicImageCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = true
        return context
    }
}

// MARK: - ComicImageCollectionViewCell

protocol ComicImageCollectionViewCellDelegate: class {
    func comicImageCollectionViewCellDidLoadImage(_ cell: ComicImageCollectionViewCell)
}

class ComicImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!

    var position: Int!
    var image: UIImage!
    weak var delegate: ComicImageCollectionViewCellDelegate?
    var request: Request!

    var imageURL: String! {
        didSet {
            if let image = image {
                imageView.contentMode = .scaleAspectFit
                imageView.image = image
            } else {
                request = AF.request(imageURL).responseImage { response in
                    if case let .success(image) = response.result {
                        self.image = image
                        self.imageView.contentMode = .scaleAspectFit
                        self.imageView.image = image
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
        imageView.contentMode = .center
        imageView.image = #imageLiteral(resourceName: "refresh")
        delegate = nil
    }
}
