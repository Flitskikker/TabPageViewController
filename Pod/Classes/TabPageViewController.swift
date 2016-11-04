//
//  TabPageViewController.swift
//  TabPageViewController
//
//  Created by EndouMari on 2016/02/24.
//  Copyright © 2016年 EndouMari. All rights reserved.
//

import UIKit

open class TabPageViewController: UIPageViewController {
    open var isInfinity: Bool = false
    open var option: TabPageOption = TabPageOption()
    open var tabItems: [(viewController: UIViewController, title: String)] = [] {
        didSet {
            tabItemsCount = tabItems.count
        }
    }

    var currentIndex: Int? {
        guard let viewController = viewControllers?.first else {
            return nil
        }
        return tabItems.map{ $0.viewController }.index(of: viewController)
    }
    fileprivate var beforeIndex: Int = 0
    fileprivate var tabItemsCount = 0
    fileprivate var defaultContentOffsetX: CGFloat {
        return self.view.bounds.width
    }
    fileprivate var shouldScrollCurrentBar: Bool = true
    lazy fileprivate var tabView: TabView = self.configuredTabView()
    
    public var customTabView: TabView?
    
    var previousOffset: CGFloat = 0
    var isDragging = false

    open static func create() -> TabPageViewController {
        let sb = UIStoryboard(name: "TabPageViewController", bundle: Bundle(for: TabPageViewController.self))
        return sb.instantiateInitialViewController() as! TabPageViewController
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        setupPageViewController()
        setupScrollView()
        updateNavigationBar()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if tabView.superview == nil {
            tabView = configuredTabView()
        }

        if let currentIndex = currentIndex , isInfinity {
            tabView.updateCurrentIndex(currentIndex, shouldScroll: true)
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateNavigationBar()
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
    }
}


// MARK: - Public Interface

public extension TabPageViewController {

    public func displayControllerWithIndex(_ index: Int, direction: UIPageViewControllerNavigationDirection, animated: Bool) {

        beforeIndex = index
        shouldScrollCurrentBar = false
        let nextViewControllers: [UIViewController] = [tabItems[index].viewController]

        let completion: ((Bool) -> Void) = { [weak self] _ in
            self?.shouldScrollCurrentBar = true
            self?.beforeIndex = index
        }

        setViewControllers(
            nextViewControllers,
            direction: direction,
            animated: animated,
            completion: completion)
    }
}


// MARK: - View

extension TabPageViewController {

    fileprivate func setupPageViewController() {
        dataSource = self
        delegate = self
        automaticallyAdjustsScrollViewInsets = false

        setViewControllers([tabItems[beforeIndex].viewController],
            direction: .forward,
            animated: false,
            completion: nil)
    }

    fileprivate func setupScrollView() {
        // Disable PageViewController's ScrollView bounce
        let scrollView = view.subviews.flatMap { $0 as? UIScrollView }.first
        scrollView?.scrollsToTop = false
        scrollView?.delegate = self
        scrollView?.backgroundColor = option.pageBackgoundColor
    }

    /**
     Update NavigationBar
     */

    fileprivate func updateNavigationBar() {
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.shadowImage = UIImage()
            navigationBar.setBackgroundImage(option.tabBackgroundImage, for: .default)
        }
    }

    fileprivate func configuredTabView() -> TabView {
        let tabView = self.customTabView ?? TabView(isInfinity: isInfinity, option: option)
        
        if self.customTabView == nil {
            tabView.translatesAutoresizingMaskIntoConstraints = false
            
            let height = NSLayoutConstraint(item: tabView,
                                            attribute: .height,
                                            relatedBy: .equal,
                                            toItem: nil,
                                            attribute: .height,
                                            multiplier: 1.0,
                                            constant: option.tabHeight)
            tabView.addConstraint(height)
            view.addSubview(tabView)
            
            let top = NSLayoutConstraint(item: tabView,
                                         attribute: .top,
                                         relatedBy: .equal,
                                         toItem: topLayoutGuide,
                                         attribute: .bottom,
                                         multiplier:1.0,
                                         constant: 0.0)
            
            let left = NSLayoutConstraint(item: tabView,
                                          attribute: .leading,
                                          relatedBy: .equal,
                                          toItem: view,
                                          attribute: .leading,
                                          multiplier: 1.0,
                                          constant: 0.0)
            
            let right = NSLayoutConstraint(item: view,
                                           attribute: .trailing,
                                           relatedBy: .equal,
                                           toItem: tabView,
                                           attribute: .trailing,
                                           multiplier: 1.0,
                                           constant: 0.0)
            
            view.addConstraints([top, left, right])
        }

        tabView.pageTabItems = tabItems.map({ $0.title})
        tabView.updateCurrentIndex(beforeIndex, shouldScroll: true)

        tabView.pageItemPressedBlock = { [weak self] (index: Int, direction: UIPageViewControllerNavigationDirection) in
            self?.displayControllerWithIndex(index, direction: direction, animated: true)
        }

        return tabView
    }
}


// MARK: - UIPageViewControllerDataSource

extension TabPageViewController: UIPageViewControllerDataSource {
    
    fileprivate func nextViewController(_ viewController: UIViewController, isAfter: Bool) -> UIViewController? {

        guard var index = tabItems.map({$0.viewController}).index(of: viewController) else {
            return nil
        }

        if isAfter {
            index += 1
        } else {
            index -= 1
        }

        if isInfinity {
            if index < 0 {
                index = tabItems.count - 1
            } else if index == tabItems.count {
                index = 0
            }
        }

        if index >= 0 && index < tabItems.count {
            return tabItems[index].viewController
        }
        return nil
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return nextViewController(viewController, isAfter: true)
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nextViewController(viewController, isAfter: false)
    }
}


// MARK: - UIPageViewControllerDelegate

extension TabPageViewController: UIPageViewControllerDelegate {

    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        shouldScrollCurrentBar = true
        tabView.scrollToHorizontalCenter()

        // Order to prevent the the hit repeatedly during animation
        tabView.updateCollectionViewUserInteractionEnabled(false)
        
        // Update background color to mask white background when bouncing (on fast fling)
        let scrollView = view.subviews.flatMap { $0 as? UIScrollView }.first
        scrollView?.backgroundColor = option.pageBackgoundColor ?? pendingViewControllers.first?.view.backgroundColor ?? UIColor.white
    }

    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        // Stop dragging
        self.isDragging = false
        
        if let currentIndex = currentIndex , currentIndex < tabItemsCount {
            tabView.updateCurrentIndex(currentIndex, shouldScroll: false)
            beforeIndex = currentIndex
        }

        tabView.updateCollectionViewUserInteractionEnabled(true)
    }
}


// MARK: - UIScrollViewDelegate

extension TabPageViewController: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Check if offset was reset while moving right (which means next page)
        if self.previousOffset - scrollView.contentOffset.x >= defaultContentOffsetX && self.isDragging {
            // Calculate new index
            var newIndex = (currentIndex ?? 0) + 1
            
            if newIndex == tabItemsCount {
                newIndex = 0
            }
            
            // Update index
            tabView.updateCurrentIndex(newIndex, shouldScroll: false)
            
            // Display controller to keep data source index in sync (http://stackoverflow.com/a/15000910/4489859)
            displayControllerWithIndex(newIndex, direction: .forward, animated: false)
            
            // Save this offset
            self.previousOffset = scrollView.contentOffset.x
            
            // Stop here
            return
        }
        
        // Check if offset was reset while moving left (which means previous page)
        if self.previousOffset - scrollView.contentOffset.x <= -defaultContentOffsetX && self.isDragging {
            // Calculate new index
            var newIndex = (currentIndex ?? 0) - 1
            
            if newIndex < 0 {
                newIndex = tabItemsCount - 1
            }
            
            // Update index
            tabView.updateCurrentIndex(newIndex, shouldScroll: false)
            
            // Display controller to keep data source index in sync (http://stackoverflow.com/a/15000910/4489859)
            displayControllerWithIndex(newIndex, direction: .reverse, animated: false)
            
            // Save this offset
            self.previousOffset = scrollView.contentOffset.x
            
            // Stop here
            return
        }
        
        // Save this offset
        self.previousOffset = scrollView.contentOffset.x
        
        // Continue with original code...
        
        if scrollView.contentOffset.x == defaultContentOffsetX || !shouldScrollCurrentBar {
            return
        }

        // (0..<tabItemsCount)
        var index: Int
        if scrollView.contentOffset.x > defaultContentOffsetX {
            index = beforeIndex + 1
        } else {
            index = beforeIndex - 1
        }

        if index == tabItemsCount {
            index = 0
        } else if index < 0 {
            index = tabItemsCount - 1
        }

        let scrollOffsetX = scrollView.contentOffset.x - view.frame.width
        tabView.scrollCurrentBarView(index, contentOffsetX: scrollOffsetX)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Set initial offset
        self.previousOffset = scrollView.contentOffset.x
        
        // Start dragging
        self.isDragging = true
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        tabView.updateCurrentIndex(beforeIndex, shouldScroll: true)
    }
}
