//
//  HTZSplitViewController.swift
//  Hotelzzz
//
//  Created by John Wells on 4/26/17.
//  Copyright © 2017 Hipmunk, Inc. All rights reserved.
//

import UIKit

class HTZSplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.preferredDisplayMode = .allVisible
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }

}
