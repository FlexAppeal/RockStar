//
//  ViewController.swift
//  Rockstar
//
//  Created by joannis on 06/09/2018.
//  Copyright (c) 2018 joannis. All rights reserved.
//

import UIKit
import Rockstar

final class RootNavigator: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        UIKitAppState.default.currentNavigator = self
    }
}

