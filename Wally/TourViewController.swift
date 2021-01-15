//
//  TourViewController.swift
//  Wally
//
//  Created by John Marr on 1/14/21.
//

import Foundation
import UIKit
import AVKit
import AVFoundation

class TourViewController: UIViewController, UIScrollViewDelegate {
    
    var imageArray:[UIImage] = [#imageLiteral(resourceName: "Tour_1"), #imageLiteral(resourceName: "Tour_2"), #imageLiteral(resourceName: "Tour_3"), #imageLiteral(resourceName: "Tour_4"), #imageLiteral(resourceName: "Tour_5"), #imageLiteral(resourceName: "Tour_6"), #imageLiteral(resourceName: "Tour_7")]
    var imageViewArray = [UIImageView]()
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var tourView: UIScrollView!
    @IBOutlet weak var buttonContinueView: UIView!
    @IBOutlet weak var buttonContinueViewVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var pageControlVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var gradientView: UIView!
    
    var pageControlVerticalConstraintConstant = CGFloat(20)
    
    var bgPlayer: AVPlayer!
    var bgPlayerLayer: AVPlayerLayer!
    @IBOutlet var playerContainer: UIView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Set up the tour view by placing all images in a paginated scrollview.
        tourView.delegate = self
        var centerX = view.frame.width/2
        let centerY = view.frame.height/2
        let offset = view.frame.width
        var fullWidth = CGFloat(0)
        
        for image in imageArray {
            let frame = view.frame
            let imageView = UIImageView(frame: frame)
            imageView.image = image
            imageView.center = CGPoint(x: centerX, y: centerY)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFit
            centerX += offset
            fullWidth += offset
            tourView.addSubview(imageView)

            imageView.frame = view.bounds

            if image == imageArray.last {
                let tap = UITapGestureRecognizer(target: self, action: #selector(TourViewController.launch))
                imageView.addGestureRecognizer(tap)
                imageView.isUserInteractionEnabled = true
            }
            imageViewArray.append(imageView)
        }
        alignSubviews(size: view.bounds.size)
        
        // Update the tourView's content size now that all images have been placed.
        tourView.contentSize = CGSize(width: fullWidth, height: view.frame.height)
        tourView.isPagingEnabled = true
        tourView.showsVerticalScrollIndicator = false
        tourView.showsHorizontalScrollIndicator = true
        pageControl.numberOfPages = imageViewArray.count
        
        // Determine if this is an inital or secondary launch and react accordingly.
        let hasToured = UserDefaults.standard.bool(forKey: "hasToured")
        if hasToured {
            let offsetX = view.frame.width * CGFloat(imageViewArray.count - 1)
            tourView.contentOffset = CGPoint(x: offsetX, y: tourView.contentOffset.y)
            scrollViewDidEndDecelerating(tourView)
        }
        
        // Create, place, and play the looping background video file
        guard let theURL = Bundle.main.url(forResource: "WallyBG", withExtension: "mp4") else { return }
        bgPlayer = AVPlayer(url: theURL)
        bgPlayerLayer = AVPlayerLayer(player: bgPlayer)
        bgPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        bgPlayer.volume = 0
        bgPlayer.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        bgPlayerLayer.frame = gradientView.frame
        bgPlayerLayer.opacity = 0.65
        gradientView.layer.insertSublayer(bgPlayerLayer, at: 1)
        bgPlayerLayer.position = CGPoint(x: gradientView.frame.width/2, y: gradientView.frame.height/2)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: bgPlayer.currentItem)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bgPlayer.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bgPlayer.pause()
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    @objc func playerItemDidReachEnd(notification: NSNotification) {
        let p: AVPlayerItem = notification.object as! AVPlayerItem
        p.seek(to: CMTime.zero, completionHandler: nil)
    }
    
    func alignSubviews(size: CGSize) {
        
        let width = size.width
        let height = size.height
        tourView.contentSize = CGSize(width: width * CGFloat(imageViewArray.count),
                                      height: height)
        var i = 0
        for iv in imageViewArray {
            iv.frame = CGRect(x: CGFloat(i) * width, y: 0, width: width, height: height)
            i += 1
        }
        
        scrollToCurrentPage(size: size)
    }
    
    @objc func launch() {
        UserDefaults.standard.set(true, forKey: "hasToured")
        performSegue(withIdentifier: "tourSegue", sender: self)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Update information when scrolling stops
        let currentPage = Int(scrollView.contentOffset.x / view.frame.width)
        pageControl.currentPage = currentPage
        if pageControl.currentPage == imageArray.count-1 {
            // This is the last image. Move the continue button out.
            buttonContinueViewVerticalConstraint.constant = -buttonContinueView.frame.height
            pageControlVerticalConstraint.constant = pageControlVerticalConstraintConstant
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
            }
        } else {
            // This is not the last image. Make sure the continue button is availabe.
            buttonContinueViewVerticalConstraint.constant = 0
            let size = tourView.bounds.size
            let constant: CGFloat = size.width > size.height ? pageControlVerticalConstraintConstant/4 : pageControlVerticalConstraintConstant
            pageControlVerticalConstraint.constant = constant
            UIView.animate(withDuration: 0.5) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func scrollToNextPage() {
        let width = tourView.bounds.width
        pageControl.currentPage = pageControl.currentPage + 1
        UIView.animate(withDuration: 0.5, animations: {
             self.tourView.contentOffset = CGPoint(x: width * CGFloat(self.pageControl.currentPage), y: 0)
        }) { _ in
            self.scrollViewDidEndDecelerating(self.tourView)
        }
    }
    
    func scrollToCurrentPage(size: CGSize) {
        self.tourView.contentOffset = CGPoint(x: size.width * CGFloat(self.pageControl.currentPage), y: 0)
        let constant = size.width > size.height ?
            pageControlVerticalConstraintConstant/4 :
            pageControlVerticalConstraintConstant
        pageControlVerticalConstraint.constant = constant
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func continuePressed() {
        if pageControl.currentPage < imageArray.count-1 {
            scrollToNextPage()
        } else {
            launch()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
