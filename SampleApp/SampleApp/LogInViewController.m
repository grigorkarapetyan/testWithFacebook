//
//  LogInViewController.m
//  SampleApp
// https://samplefacebook-eac44.firebaseapp.com/__/auth/handler
//  Created by Grigor Karapetyan on 11/26/16.
//  Copyright © 2016 Grigor Karapetyan. All rights reserved.
//

#import "LogInViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@import Firebase;


@interface LogInViewController ()<FBSDKLoginButtonDelegate>
@property (nonatomic) FIRDatabaseHandle databaseHandle;

@end

@implementation LogInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[FIRAuth auth] addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
        if (user!=nil) {
            //move the user to the home screen
            [self performSegueWithIdentifier:@"presentUsers" sender:nil];
        }
        else {
            // FACEBOOK button
            FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
            [loginButton setFrame:CGRectMake(0, 0, 220, 40)];
            loginButton.center = self.view.center;
            loginButton.readPermissions = @[@"public_profile",@"email"];
            loginButton.delegate = self;
            [self.view addSubview:loginButton];
        }
    }];
}
// FACEBOOK login button methods
- (void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error {
    NSLog(@"User logged in");
//-----------------------------------------
    if (error != nil) {
        //handle error
    } else if (result.isCancelled) {
        //handle canceletion
    } else {
//----------------------------------------
    FIRAuthCredential *credential = [FIRFacebookAuthProvider
                                     credentialWithAccessToken:[FBSDKAccessToken currentAccessToken]
                                     .tokenString];
    [[FIRAuth auth] signInWithCredential:credential
                              completion:^(FIRUser *user, NSError *error) {
                                  NSLog(@"User logged in to APP");
                                  if (error) {
                                      // ...
                                      return;
                                  } else {
                                      //after first time log in
                                      FIRStorage *storage = [FIRStorage storage];
                                      
                                      FIRStorageReference *storageRef = [storage referenceForURL:@"gs://samplefacebook-eac44.appspot.com"];
                                      NSString *pictureFolderName = [NSString stringWithFormat:@"%@/profile_pic_small.jpg",user.uid];
                                      
                                      FIRStorageReference *profilePictureRef = [storageRef child:pictureFolderName];
                                      NSString *userId = user.uid;
                                      FIRDatabaseReference *ref = [[FIRDatabase database] reference];
                                      [[[[ref child:@"user_profile"] child:userId] child:@"profile_pic_small"]observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
                                          
                                          NSString *profilePic = snapshot.value;
                                          if (profilePic == (id)[NSNull null]) {
                                              NSData *imageData = [NSData dataWithContentsOfURL:user.photoURL];
                                              if (imageData) {
                                                   FIRStorageUploadTask *uploadTask = [profilePictureRef putData:imageData metadata:nil completion:^(FIRStorageMetadata *metadata, NSError *error) {
                                                      if (error != nil) {
                                                          NSLog(@"error in downloading image");
                                                      } else {
                                                          NSURL *downloadURL = metadata.downloadURL;
                                                          [[[[ref child:@"user_profile"] child:userId] child:@"profile_pic_small"] setValue:[downloadURL absoluteString]];
                                                      }
                                                  }];
                                              }
                                              // storing data for user page
                                              [[[[ref child:@"user_profile"] child:userId] child:@"name"] setValue:user.displayName];
                                          } else {
                                              NSLog(@"existing user");
                                          }
                                      } withCancelBlock:^(NSError * _Nonnull error) {
                                          NSLog(@"%@", error.localizedDescription);
                                      }];                           
                                  }
                              }];
    }
}
- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    
}
@end
