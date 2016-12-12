//
//  UsersTableViewCell.h
//  SampleApp
//
//  Created by Grigor Karapetyan on 12/10/16.
//  Copyright © 2016 Grigor Karapetyan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UsersTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *followButton;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;

@end
