//
//  ListView.swift
//  truCourse
//
//  Created by Mike Mayer on 5/11/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

enum ListViewType
{
  case latlon
  case bearing
}

class ListView: UITableView
{
  var type : ListViewType!
}
