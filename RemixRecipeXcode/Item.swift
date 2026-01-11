//
//  Item.swift
//  RemixRecipeXcode
//
//  Created by Yves de Lafontaine on 07/01/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
