//
//  Feed.swift
//  Chatter
//
//  Created by Ryan Daulton on 12/14/15.
//  Copyright © 2015 Fade LLC All rights reserved.
//

import Foundation
import CoreData

@objc(Feed)
class Feed: NSManagedObject {
    @NSManaged var messages: String
}