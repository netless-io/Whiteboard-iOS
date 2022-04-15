//
//  ExampleControlView.swift
//  Fastboard_Example
//
//  Created by xuyunshi on 2022/2/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

let controlHeight = CGFloat(44)
let controlWidth = CGFloat(166)
let margin = CGFloat(3)

@objc
public class ExampleItem: NSObject {
    @objc
    public init(title: String, status: String? = nil, enable: Bool = true, clickBlock: ((ExampleItem) -> Void)? = nil) {
        self.title = title
        self.status = status
        self.clickBlock = clickBlock
        self.enable = enable
    }
    
    @objc
    public let title: String
    
    @objc
    public var status: String?
    
    @objc
    public var clickBlock: ((ExampleItem) ->Void)?
    
    @objc
    public var enable: Bool
}

@objc
public class ExampleControlView: UICollectionView {
    @objc
    public var items: [ExampleItem] {
        didSet {
            reloadData()
        }
    }
    let layout: UICollectionViewFlowLayout
    
    public override var intrinsicContentSize: CGSize {
        return .init(width: 0, height: controlHeight)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let count: CGFloat
        if bounds.width > bounds.height {
            count = 5
        } else {
            count = 3
        }
        let m = (count - 1) * margin
        let width = (bounds.width - m) / count
        layout.minimumLineSpacing = margin
        layout.minimumInteritemSpacing = margin
        if width > controlWidth {
            layout.itemSize = CGSize(width: width, height: controlHeight)
        } else {
            layout.itemSize = CGSize(width: controlWidth, height: controlHeight)
        }
        
        layout.scrollDirection = bounds.height <= controlHeight ? .horizontal : .vertical
    }
    
    @objc
    public init(items: [ExampleItem]) {
        self.items = items
        
        layout = UICollectionViewFlowLayout()
        super.init(frame: .zero, collectionViewLayout: layout)
        register(UINib(nibName: .init(describing: ControlCell.self), bundle: nil), forCellWithReuseIdentifier: .init(describing: ControlCell.self))
        showsHorizontalScrollIndicator = false
        dataSource = self
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ExampleControlView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = items[indexPath.row]
        let cell = dequeueReusableCell(withReuseIdentifier: .init(describing: ControlCell.self), for: indexPath) as! ControlCell
        cell.controlTitleLabel.text = item.title
        cell.controlStatusLabel.text = item.status
        cell.controlStatusLabel.isHidden = item.status == nil
        cell.alpha = item.enable ? 1 : 0.5
        return cell
    }
}

extension ExampleControlView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        item.clickBlock?(item)
        collectionView.reloadData()
    }
}
