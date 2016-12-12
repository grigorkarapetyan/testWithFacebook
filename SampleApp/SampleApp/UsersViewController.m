//
//  UsersViewController.m
//  SampleApp
//
//  Created by Grigor Karapetyan on 11/26/16.
//  Copyright © 2016 Grigor Karapetyan. All rights reserved.
//

#import "UsersViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "UsersTableViewCell.h"

@import Firebase;

@interface UsersViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic) FIRDatabaseHandle databaseHandle;
@property (weak, nonatomic) IBOutlet UIButton *logOutButton;
@property (strong, nonatomic) FIRDatabaseReference *ref;
@property (nonatomic) NSMutableDictionary *allUsers;
@property (weak, nonatomic) IBOutlet UIImageView *userProfileImage;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UITableView *allUsersTableView;
@property (nonatomic) NSMutableArray *namesArray;
@property (nonatomic) NSMutableArray *imagesArray;
//
@property (nonatomic) NSMutableArray *userIdsArray;

@end

@implementation UsersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.namesArray = [[NSMutableArray alloc] init];
    self.imagesArray = [[NSMutableArray alloc] init];
   //
    self.userIdsArray = [[NSMutableArray alloc] init];

    // Do any additional setup after loading the view.
    self.ref = [[FIRDatabase database] reference];
    self.databaseHandle = [[self.ref child:@"user_profile"] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {

        self.allUsers = snapshot.value;
        NSArray *usersAllDetails = [self.allUsers allValues];
        for (NSDictionary *details in usersAllDetails) {
            if (details) {
                NSString *name = [details objectForKey:@"name"];
                NSString *img = [details objectForKey:@"profile_pic_small"];
                if (name && img) {
                    if (![self.imagesArray containsObject:img]) {
                    [self.namesArray addObject:name];
                    [self.imagesArray addObject:img];
                    //
                    [self.userIdsArray addObject:[[self.allUsers allKeysForObject:details] objectAtIndex:0]];
                        
                    [self reloadData];
                    }
                }
            }
        }
        //
        NSLog(@"users UID %@",self.userIdsArray);
    }];

    if ([FIRAuth auth].currentUser) {
        // User is signed in.
        FIRUser *user = [FIRAuth auth].currentUser;
        NSString *name = user.displayName;
        NSString *email = user.email;
        NSString *uid = user.uid;
        NSURL *photoURL = user.photoURL;
        self.userNameLabel.text = name;

        //reference to the storage
        FIRStorage *storage = [FIRStorage storage];
        FIRStorageReference *storageRef = [storage referenceForURL:@"gs://samplefacebook-eac44.appspot.com"];
        NSString *pictureFolderName = [NSString stringWithFormat:@"%@/profile_pic.jpg",user.uid];
        FIRStorageReference *profilePictureRef = [storageRef child:pictureFolderName];
        [profilePictureRef dataWithMaxSize:1 * 1024 * 1024 completion:^(NSData *data, NSError *error){
            if (error != nil) {
                NSLog(@"unable to download image");
            } else {
                if (data != nil) {
                    NSLog(@"no need for download image from facebook");
                    self.userProfileImage.image = [UIImage imageWithData:data];
                }
            }
        }];
        if (self.userProfileImage.image == nil) {
            
        FBSDKGraphRequest *profilePicture = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:@"me/picture"
                                             parameters:@{@"height":@"300",@"width":@"300",@"redirect":@"0"}
                                      HTTPMethod:@"GET"];
        [profilePicture startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError* error) {
            if (error == nil) {
                NSLog(@"result:%@",result);
                NSDictionary *dictoionary = result;
                id data = [dictoionary objectForKey:@"data"];
                NSString *urlPicture = 	[data objectForKey:@"url"];
                NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlPicture]];

                if (imageData) {
                    FIRStorageUploadTask *uploadTask = [profilePictureRef putData:imageData metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error) {
                        if (error != nil) {
                            NSLog(@"error in downloading");
 
                        } else {
                            // Metadata contains file metadata such as size, content-type, and download URL.
                            NSURL *downloadURL = metadata.downloadURL;
                        }
                    }];
                    self.userProfileImage.image = [UIImage imageWithData:imageData];
                }
            }
        }];
        } //end "if needed" downloading
    } else {
        // No user is signed in.
        // ...
    }
}

// CREATING TABLE VIEW

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.namesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        UsersTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userCell" forIndexPath:indexPath];
    NSURL *imageUrl = [NSURL URLWithString:self.imagesArray[indexPath.row]];
    NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
    cell.userImageView.image = [UIImage imageWithData:imageData];
    cell.nameLabel.text = self.namesArray[indexPath.row];
    
    // follow part
    cell.followButton.tag = indexPath.row;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView updateConstraints];
}

- (void) reloadData {
    [self.allUsersTableView reloadData];
}

- (IBAction)logOut:(id)sender {
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logOut];
    NSError *error;
    [[FIRAuth auth] signOut:&error];
    if (!error) {
        // Sign-out succeeded
        [self performSegueWithIdentifier:@"backToLogIn" sender:nil];
    } else {
        NSLog(@"%@", error.localizedDescription);
    }
    [self performSegueWithIdentifier:@"backToLogIn" sender:nil];
}

- (IBAction)selectForFollow:(id)sender {
}

@end
