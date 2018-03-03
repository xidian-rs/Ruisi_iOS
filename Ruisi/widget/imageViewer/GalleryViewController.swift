//
//  GalleryViewController.swift
//  ImageViewer
//
//  Created by Kristian Angyal on 01/07/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//  Copyright © 2017 - 2018 freedom10086.
//

import UIKit
import AVFoundation

open class GalleryViewController: UIPageViewController, ItemControllerDelegate {
    // UI
    fileprivate var closeButton: UIButton?
    fileprivate var saveButton: UIButton?
    fileprivate let overlayView = BlurView()
    /// A custom view at the bottom of the gallery with layout using default (or custom) pinning settings for footer.
    open var footerView: CounterView?
    fileprivate weak var initialItemController: ItemController?
    fileprivate var currentImageViewController: UIViewController?

    // LOCAL STATE
    // represents the current page index, updated when the root view of the view controller representing the page stops animating inside visible bounds and stays on screen.
    public var currentIndex: Int
    // Picks up the initial value from configuration, if provided. Subsequently also works as local state for the setting.
    fileprivate var decorationViewsHidden = false
    fileprivate var isAnimating = false
    fileprivate var initialPresentationDone = false

    // DATASOURCE/DELEGATE
    fileprivate let itemsDataSource: GalleryItemsDataSource
    fileprivate let pagingDataSource: GalleryPagingDataSource

    // CONFIGURATION
    fileprivate var spineDividerWidth: Float = 10
    fileprivate var galleryPagingMode = GalleryPagingMode.standard
    fileprivate var statusBarHidden = true
    fileprivate var overlayAccelerationFactor: CGFloat = 1
    fileprivate var rotationDuration = 0.15
    fileprivate var rotationMode = GalleryRotationMode.always
    fileprivate let swipeToDismissFadeOutAccelerationFactor: CGFloat = 6
    fileprivate var decorationViewsFadeDuration = 0.15

    /// COMPLETION BLOCKS
    /// If set, the block is executed right after the initial launch animations finish.
    open var launchedCompletion: (() -> Void)?
    /// If set, called every time ANY animation stops in the page controller stops and the viewer passes a page index of the page that is currently on screen
    open var landedPageAtIndexCompletion: ((Int) -> Void)?
    /// If set, launched after all animations finish when the close button is pressed.
    open var closedCompletion: (() -> Void)?
    /// If set, launched after all animations finish when the close() method is invoked via public API.
    open var programmaticallyClosedCompletion: (() -> Void)?

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError()
    }

    public init(startIndex: Int, itemsDataSource: GalleryItemsDataSource, displacedViewsDataSource: GalleryDisplacedViewsDataSource? = nil, configuration: GalleryConfiguration = []) {

        self.currentIndex = startIndex
        self.itemsDataSource = itemsDataSource

        ///Only those options relevant to the paging GalleryViewController are explicitly handled here, the rest is handled by ItemViewControllers
        for item in configuration {

            switch item {
            case .pagingMode(let mode):                         galleryPagingMode = mode
            case .statusBarHidden(let hidden):                  statusBarHidden = hidden
            case .hideDecorationViewsOnLaunch(let hidden):      decorationViewsHidden = hidden
            case .rotationMode(let mode):                       rotationMode = mode
            case .overlayColor(let color):                      overlayView.overlayColor = color
            case .overlayBlurStyle(let style):                  overlayView.blurringView.effect = UIBlurEffect(style: style)
            case .overlayBlurOpacity(let opacity):              overlayView.blurTargetOpacity = opacity
            case .overlayColorOpacity(let opacity):             overlayView.colorTargetOpacity = opacity

            default: break
            }
        }

        pagingDataSource = GalleryPagingDataSource(itemsDataSource: itemsDataSource, displacedViewsDataSource: displacedViewsDataSource, configuration: configuration)

        super.init(transitionStyle: UIPageViewControllerTransitionStyle.scroll,
                navigationOrientation: UIPageViewControllerNavigationOrientation.horizontal,
                options: [UIPageViewControllerOptionInterPageSpacingKey: NSNumber(value: spineDividerWidth as Float)])

        pagingDataSource.itemControllerDelegate = self

        ///This feels out of place, one would expect even the first presented(paged) item controller to be provided by the paging dataSource but there is nothing we can do as Apple requires the first controller to be set via this "setViewControllers" method.
        let initialController = pagingDataSource.createItemController(startIndex, isInitial: true)
        self.setViewControllers([initialController], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
        self.currentImageViewController = initialController

        if let controller = initialController as? ItemController {

            initialItemController = controller
        }

        ///This less known/used presentation style option allows the contents of parent view controller presenting the gallery to "bleed through" the blurView. Otherwise we would see only black color.
        self.modalPresentationStyle = .overFullScreen
        self.dataSource = pagingDataSource

        applicationWindow().windowLevel = (statusBarHidden) ? UIWindowLevelStatusBar + 1 : UIWindowLevelNormal
        NotificationCenter.default.addObserver(self, selector: #selector(GalleryViewController.rotate), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    func updateDataSource(startIndex: Int, itemsDataSource: GalleryItemsDataSource) {
        self.currentIndex = startIndex
        self.footerView?.count = itemsDataSource.itemCount()
        self.footerView?.currentIndex = startIndex
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func didEndPlaying() {
        page(toIndex: currentIndex + 1)
    }


    fileprivate func configureOverlayView() {

        overlayView.bounds.size = UIScreen.main.bounds.insetBy(dx: -UIScreen.main.bounds.width / 2, dy: -UIScreen.main.bounds.height / 2).size
        overlayView.center = CGPoint(x: (UIScreen.main.bounds.width / 2), y: (UIScreen.main.bounds.height / 2))

        self.view.addSubview(overlayView)
        self.view.sendSubview(toBack: overlayView)
    }

    fileprivate func configureFooterView() {
        footerView = CounterView(frame: CGRect(x: 0, y: 0, width: 200, height: 24), currentIndex: currentIndex, count: self.itemsDataSource.itemCount())
        footerView?.alpha = 0
        self.view.addSubview(footerView!)
    }

    fileprivate func configureCloseButton() {
        closeButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50, height: 50)))
        closeButton!.setTitle("关闭", for: .normal)
        closeButton!.setTitleColor(UIColor.white, for: .normal)
        //closeBtn?.setImage(CAShapeLayer.closeShape(edgeLength: 15).toImage(), for: .normal)

        closeButton!.addTarget(self, action: #selector(GalleryViewController.closeInteractively), for: .touchUpInside)
        closeButton!.alpha = 0
        self.view.addSubview(closeButton!)
    }
    
    fileprivate func configureSaveButton() {
        saveButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50, height: 50)))
        saveButton!.setTitle("保存", for: .normal)
        saveButton!.setTitleColor(UIColor.white, for: .normal)
        
        saveButton!.addTarget(self, action: #selector(GalleryViewController.saveInteractively), for: .touchUpInside)
        saveButton!.alpha = 0
        self.view.addSubview(saveButton!)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            if (statusBarHidden) {
                additionalSafeAreaInsets = UIEdgeInsets(top: -20, left: 0, bottom: 0, right: 0)
            }
        }

        configureFooterView()
        configureCloseButton()
        configureSaveButton()
        
        self.view.clipsToBounds = false
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard initialPresentationDone == false else {
            return
        }

        ///We have to call this here (not sooner), because it adds the overlay view to the presenting controller and the presentingController property is set only at this moment in the VC lifecycle.
        configureOverlayView()

        ///The initial presentation animations and transitions
        presentInitially()

        initialPresentationDone = true
    }

    fileprivate func presentInitially() {

        isAnimating = true

        ///Animates decoration views to the initial state if they are set to be visible on launch. We do not need to do anything if they are set to be hidden because they are already set up as hidden by default. Unhiding them for the launch is part of chosen UX.
        initialItemController?.presentItem(alongsideAnimation: { [weak self] in

            self?.overlayView.present()

        }, completion: { [weak self] in

            if let strongSelf = self {

                if strongSelf.decorationViewsHidden == false {
                    strongSelf.animateDecorationViews(visible: true)
                }

                strongSelf.isAnimating = false
                strongSelf.launchedCompletion?()
            }
        })
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if rotationMode == .always && isPortraitOnly() {
            let transform = windowRotationTransform()
            let bounds = rotationAdjustedBounds()

            self.view.transform = transform
            self.view.bounds = bounds
        }

        overlayView.frame = view.bounds.insetBy(dx: -UIScreen.main.bounds.width * 2, dy: -UIScreen.main.bounds.height * 2)
        layoutButtons()
        layoutFooterView()
    }

    private var defaultInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return view.safeAreaInsets
        } else {
            return UIEdgeInsets(top: statusBarHidden ? 0.0 : 20.0, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }

    fileprivate func layoutButtons() {
        if let btn = closeButton {
            btn.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
            btn.frame.origin.x = self.view.bounds.size.width - 16 - btn.bounds.size.width
            btn.frame.origin.y = defaultInsets.top + 8
        }
        
        if let btn2 = saveButton {
            btn2.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin]
            btn2.frame.origin.x = self.view.bounds.size.width - 16 - btn2.bounds.size.width
            btn2.frame.origin.y = self.view.bounds.height - btn2.bounds.height - 14 - defaultInsets.bottom
        }
    }

    fileprivate func layoutFooterView() {
        guard let footer = footerView else {
            return
        }
        footer.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
        footer.center = self.view.boundsCenter
        footer.frame.origin.y = self.view.bounds.height - footer.bounds.height - 25 - defaultInsets.bottom
    }


    open func page(toIndex index: Int) {
        guard currentIndex != index && index >= 0 && index < self.itemsDataSource.itemCount() else {
            return
        }
        let imageViewController = self.pagingDataSource.createItemController(index)
        self.currentImageViewController = imageViewController
        let direction: UIPageViewControllerNavigationDirection = index > currentIndex ? .forward : .reverse

        // workaround to make UIPageViewController happy
        if direction == .forward {
            let previousVC = self.pagingDataSource.createItemController(index - 1)
            setViewControllers([previousVC], direction: direction, animated: true, completion: { finished in
                DispatchQueue.main.async(execute: { [weak self] in
                    self?.setViewControllers([imageViewController], direction: direction, animated: false, completion: nil)
                })
            })
        } else {
            let nextVC = self.pagingDataSource.createItemController(index + 1)
            setViewControllers([nextVC], direction: direction, animated: true, completion: { finished in
                DispatchQueue.main.async(execute: { [weak self] in
                    self?.setViewControllers([imageViewController], direction: direction, animated: false, completion: nil)
                })
            })
        }
    }

    open func reload(atIndex index: Int) {

        guard index >= 0 && index < self.itemsDataSource.itemCount() else {
            return
        }

        guard let firstVC = viewControllers?.first, let itemController = firstVC as? ItemController else {
            return
        }

        itemController.fetchImage()
    }

    // MARK: - Animations

    @objc fileprivate func rotate() {
        /// If the app supports rotation on global level, we don't need to rotate here manually because the rotation
        /// of key Window will rotate all app's content with it via affine transform and from the perspective of the
        /// gallery it is just a simple relayout. Allowing access to remaining code only makes sense if the app is
        /// portrait only but we still want to support rotation inside the gallery.
        guard isPortraitOnly() else {
            return
        }

        guard UIDevice.current.orientation.isFlat == false &&
                      isAnimating == false else {
            return
        }

        isAnimating = true

        UIView.animate(withDuration: rotationDuration, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: { [weak self] () -> Void in

            self?.view.transform = windowRotationTransform()
            self?.view.bounds = rotationAdjustedBounds()
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()

        }) { [weak self] finished in

            self?.isAnimating = false
        }
    }

    /// Invoked when closed programmatically
    open func close() {
        closeDecorationViews(programmaticallyClosedCompletion)
    }

    /// Invoked when closed via close button
    @objc fileprivate func closeInteractively() {
        closeDecorationViews(closedCompletion)
    }
    
    /// Invoked when save image via save button
    @objc fileprivate func saveInteractively() {
        if let vc = currentImageViewController as? ImageViewController, let image = vc.itemView.image {
            saveButton?.isEnabled = false
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.saveImageResult(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            let ac = UIAlertController(title: "提示", message: "获取不到图片无法保存!", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "好", style: .default))
            present(ac, animated: true)
        }
    }
    
    
    //MARK: - Add image to Library
    @objc func saveImageResult(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        saveButton?.isEnabled = true
        if let error = error {
            let ac = UIAlertController(title: "保存失败", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "好", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "保存成功", message: "图片成功保存到你的图库!", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "好", style: .default))
            present(ac, animated: true)
        }
    }

    fileprivate func closeDecorationViews(_ completion: (() -> Void)?) {

        guard isAnimating == false else {
            return
        }
        isAnimating = true

        if let itemController = self.viewControllers?.first as? ItemController {

            itemController.closeDecorationViews(decorationViewsFadeDuration)
        }

        UIView.animate(withDuration: decorationViewsFadeDuration, animations: { [weak self] in
            self?.footerView?.alpha = 0.0
            self?.closeButton?.alpha = 0.0
            self?.saveButton?.alpha = 0.0
            
        }, completion: { [weak self] done in

            if let strongSelf = self,
               let itemController = strongSelf.viewControllers?.first as? ItemController {

                itemController.dismissItem(alongsideAnimation: {

                    strongSelf.overlayView.dismiss()

                }, completion: { [weak self] in

                    self?.isAnimating = true
                    self?.closeGallery(false, completion: completion)
                })
            }
        })
    }

    func closeGallery(_ animated: Bool, completion: (() -> Void)?) {

        self.overlayView.removeFromSuperview()

        self.modalTransitionStyle = .crossDissolve

        self.dismiss(animated: animated) {
            applicationWindow().windowLevel = UIWindowLevelNormal
            completion?()
        }
    }

    fileprivate func animateDecorationViews(visible: Bool) {
        let targetAlpha: CGFloat = (visible) ? 1 : 0
        UIView.animate(withDuration: decorationViewsFadeDuration, animations: { [weak self] in
            self?.footerView?.alpha = targetAlpha
            self?.closeButton?.alpha = targetAlpha
            self?.saveButton?.alpha = targetAlpha
        })
    }


    public func itemControllerDidAppear(_ controller: ItemController) {
        self.currentIndex = controller.index
        self.landedPageAtIndexCompletion?(self.currentIndex)
        footerView?.count = self.itemsDataSource.itemCount()
        footerView?.currentIndex = self.currentIndex
        self.footerView?.sizeToFit()
    }

    open func itemControllerDidSingleTap(_ controller: ItemController) {
        self.decorationViewsHidden = !self.decorationViewsHidden
        animateDecorationViews(visible: !self.decorationViewsHidden)
    }

    open func itemControllerDidLongPress(_ controller: ItemController, in item: ItemView) {
        switch (controller, item) {
        case (_ as ImageViewController, let item as UIImageView):
            guard let image = item.image else {
                return
            }
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            self.present(activityVC, animated: true)

        default:  return
        }
    }

    public func itemController(_ controller: ItemController, didSwipeToDismissWithDistanceToEdge distance: CGFloat) {
        if decorationViewsHidden == false {
            let alpha = 1 - distance * swipeToDismissFadeOutAccelerationFactor
            closeButton?.alpha = alpha
            saveButton?.alpha = alpha
            footerView?.alpha = alpha
        }

        self.overlayView.blurringView.alpha = 1 - distance
        self.overlayView.colorView.alpha = 1 - distance
    }

    public func itemControllerDidFinishSwipeToDismissSuccessfully() {
        self.overlayView.removeFromSuperview()
        self.dismiss(animated: false, completion: nil)
    }

    public func itemControllerWillAppear(_ controller: ItemController) {

    }

    public func itemControllerWillDisappear(_ controller: ItemController) {

    }
}
