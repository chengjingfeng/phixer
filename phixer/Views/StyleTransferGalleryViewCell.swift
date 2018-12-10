//
//  StyleTransferGalleryViewCell.swift
//  phixer
//
//  Created by Philip Price on 10/25/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import CoreImage


class StyleTransferGalleryViewCell: UICollectionViewCell {
    
    var theme = ThemeManager.currentTheme()
    

    
    public static let reuseID: String = "StyleTransferGalleryViewCell"

    var cellIndex:Int = -1 // used for tracking cell reuse
    
    var sourceView : UIImageView! = UIImageView()
    var arrowView  : UIImageView! = UIImageView()
    var styledView : MetalImageView! // only allocate when configured

    var descriptor: FilterDescriptor!
    
    let defaultWidth:CGFloat = 128.0
    let defaultHeight:CGFloat = 64.0
    
    // static vars (shared across all instances)
    fileprivate static var filterManager:FilterManager = FilterManager.sharedInstance
    fileprivate static var input:CIImage? = nil
    fileprivate static var arrow:UIImageView? = nil
    
    fileprivate static var rowSize:CGSize = CGSize.zero
    fileprivate static var imgSize:CGSize = CGSize.zero

    fileprivate var initDone:Bool = false
    
    fileprivate var source:CIImage? = nil
    fileprivate var styledImage:UIImage? = nil
    
    fileprivate var filter:FilterDescriptor? = nil
    
    fileprivate var filterDescriptor:FilterDescriptor?

    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        doInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func doInit(){
        if (!initDone){
            initDone = true
            loadInputs()
        }
    }
    
    
    
    private func doLayout(){
        
        doInit()
        // set up theme
        self.backgroundColor = theme.backgroundColor
        //self.layer.cornerRadius = 2.0
        //self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.clear.cgColor
        self.clipsToBounds = true

        // set up images
        for view in [sourceView, arrowView, styledView] {
            //view?.contentMode = .scaleAspectFill
            view?.contentMode = .scaleAspectFit
            view?.isHidden = false
            view?.clipsToBounds = true
            view?.frame.size = StyleTransferGalleryViewCell.imgSize
            view?.layer.borderColor = theme.borderColor.cgColor
            self.layer.borderWidth = 1.0
            self.addSubview(view!)
        }


        // set constraints
        /***
        log.verbose("row size:\(self.frame.size) view size:\(sourceView.frame.size)")
        sourceView.anchorToEdge(.left, padding: 0, width: sourceView.frame.size.width, height: sourceView.frame.size.height)
        arrowView.anchorInCenter(width: arrowView.frame.size.width, height: arrowView.frame.size.height)
        styledView.anchorToEdge(.right, padding: 0, width: styledView.frame.size.width, height: styledView.frame.size.height)
         ***/
        self.groupInCenter(group: .horizontal, views: [sourceView, arrowView, styledView], padding: 12,
                           width: StyleTransferGalleryViewCell.imgSize.width, height: StyleTransferGalleryViewCell.imgSize.height)

    }
 
    
    
    fileprivate func loadInputs(){
        
        // load static data
        if StyleTransferGalleryViewCell.input == nil {
            StyleTransferGalleryViewCell.rowSize = self.frame.size
            StyleTransferGalleryViewCell.imgSize = CGSize(width: (self.frame.size.width / 4.0).rounded(), height: (self.frame.size.height * 0.9).rounded())

            log.verbose("Loading source and icon")
            StyleTransferGalleryViewCell.input = InputSource.getCurrentImage()?.resize(size: StyleTransferGalleryViewCell.imgSize)
            if StyleTransferGalleryViewCell.input == nil {
                log.error("NIL Input")
            }
            
            StyleTransferGalleryViewCell.arrow?.frame.size = StyleTransferGalleryViewCell.imgSize
            StyleTransferGalleryViewCell.arrow = UIImageView()
            StyleTransferGalleryViewCell.arrow?.image = UIImage(named:"ic_right_arrow")?.withRenderingMode(.alwaysTemplate)
            if StyleTransferGalleryViewCell.arrow?.image == nil {
                log.error("Failed to load arrow icon")
            }
        }
    }
    
    
    
    // MARK: - Configuration

/***
    override func prepareForReuse() {
        //styledView = RenderView()
        styledView = nil
        //styledView.isHidden = true
        super.prepareForReuse()
    }
***/
    public func setStyledImage(index:Int, key:String, image:CIImage?){
        DispatchQueue.main.async(execute: { () -> Void in
            log.debug("index:\(index), key:\(key)")

            self.cellIndex = index // allows tracking of cells for re-use or pre-loading
            self.styledView = StyleTransferGalleryViewCell.filterManager.getRenderView(key: key)

            self.loadInputs()
            self.doLayout()
            
            // display the source image
            self.descriptor = StyleTransferGalleryViewCell.filterManager.getFilterDescriptor(key: key)
            self.sourceView.image = self.descriptor?.getSourceImage()
            if self.sourceView.image == nil {
                log.warning("NIL source image")
            }

            // display the arrow icon
            self.arrowView.image = UIImage(named:"ic_right_arrow")?.withRenderingMode(.alwaysTemplate)
            self.arrowView.tintColor =  self.theme.tintColor
            self.arrowView.alpha = 0.8
            
            // update the styled view
           self.styledView.image = image
            
            //self.doLayout()

        })
    }
    
    public func configureCell(frame: CGRect, index:Int, key:String) {
        
        DispatchQueue.main.async(execute: { () -> Void in
            log.debug("index:\(index), key:\(key)")
            self.cellIndex = index // allows tracking of cells for re-use or pre-loading
            
            // get the renderable view for this filter
            self.styledView = StyleTransferGalleryViewCell.filterManager.getRenderView(key: key)
            
            // get the descriptor and setup adornments etc. accordingly
            self.descriptor = StyleTransferGalleryViewCell.filterManager.getFilterDescriptor(key: key)
            
            // If filter is disabled, show at half intensity
            if (self.descriptor != nil){
                if (StyleTransferGalleryViewCell.filterManager.isHidden(key: key)){
                    self.styledView.alpha = 0.25
                    self.layer.borderColor = self.theme.borderColor.cgColor
                }
                
            } else {
                log.error("NIL descriptor for key: \(key)")
            }
            
            // get the source image
            self.sourceView.image = self.descriptor?.getSourceImage()
            if self.sourceView.image == nil {
                log.warning("NIL source image")
            }

            self.doLayout()
            self.updateRenderView(key: key, styledView: self.styledView)
        })
        
    }
    
    
    // update the supplied RenderView with the supplied filter
    public func updateRenderView(key: String, styledView:MetalImageView?){
        
        //var descriptor: FilterDescriptor?
        
        self.descriptor = StyleTransferGalleryViewCell.filterManager.getFilterDescriptor(key: key)
 
        if (StyleTransferGalleryViewCell.input == nil){
            loadInputs()
        }
        
        guard (StyleTransferGalleryViewCell.input != nil) else {
            log.error("Could not load input image")
            return
        }

        // apply the filter
        log.verbose("Running style filter: \(key)")
        styledView?.image = self.descriptor?.apply(image: StyleTransferGalleryViewCell.input)
 
    }

    open func suspend(){
        //log.debug("Suspending cell: \((filterDescriptor?.key)!)")
        //input?.removeAllTargets()
        //blend?.removeAllTargets()
        //filter?.removeAllTargets()
        //filterGroup?.removeAllTargets()
    }
    

}
