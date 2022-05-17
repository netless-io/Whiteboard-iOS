//
//  ControlCell.swift
//  Fastboard_Example
//
//  Created by xuyunshi on 2022/2/22.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit

class ControlCell: UICollectionViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        clipsToBounds = true
        layer.cornerRadius = 4
    }
    
    @IBOutlet weak var controlStatusLabel: UILabel!
    @IBOutlet weak var controlTitleLabel: UILabel!
}
