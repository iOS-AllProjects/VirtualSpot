//
//  GCD.swift
//  VirtualSpot
//
//  Created by Etjen Ymeraj on 3/15/17.
//  Copyright © 2017 Etjen Ymeraj. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
