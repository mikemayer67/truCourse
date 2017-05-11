//
//  ListViewCells.swift
//  truCourse
//
//  Created by Mike Mayer on 5/11/17.
//  Copyright © 2017 VMWishes. All rights reserved.
//

import UIKit

class ListViewPostCell: UITableViewCell
{
  @IBOutlet weak var menuButton: UIButton!
  @IBOutlet weak var postImage: UIImageView!
  @IBOutlet weak var postText: UILabel!

  override func awakeFromNib()
  {
    super.awakeFromNib()
    // Initialization code
  }
  
  //    override func setSelected(_ selected: Bool, animated: Bool)
  //    {
  //        super.setSelected(selected, animated: animated)
  //
  //        // Configure the view for the selected state
  //    }
  
}

class ListViewForkCell: UITableViewCell
{
  @IBOutlet weak var menuButton: UIButton!
  @IBOutlet weak var postImage: UIImageView!
  @IBOutlet weak var postText: UILabel!
  @IBOutlet weak var candText: UILabel!
  
  override func awakeFromNib()
  {
    super.awakeFromNib()
    // Initialization code
  }
  
  //    override func setSelected(_ selected: Bool, animated: Bool)
  //    {
  //        super.setSelected(selected, animated: animated)
  //
  //        // Configure the view for the selected state
  //    }
  
}

class ListViewCandCell: UITableViewCell
{
  @IBOutlet weak var candText: UILabel!
  
  override func awakeFromNib()
  {
    super.awakeFromNib()
    // Initialization code
  }
  
  //    override func setSelected(_ selected: Bool, animated: Bool)
  //    {
  //        super.setSelected(selected, animated: animated)
  //
  //        // Configure the view for the selected state
  //    }
  
}
