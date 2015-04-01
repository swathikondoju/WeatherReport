//
//  ViewController.h
//  WeatherReport
//
//  Created by Swathi Kondoju on 3/23/15.
//  Copyright (c) 2015 Swathi Kondoju. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

typedef enum
{
    MIST = 0,
    RAIN,
    CLEAR,
    SNOW
} weatherType;

@interface ViewController : UIViewController<CLLocationManagerDelegate, UISearchBarDelegate>
{
    CLLocationManager *locationManager;
    UITapGestureRecognizer *tapGesture;
    float currentLatitude;
    float currentLongitude;
}

@property (nonatomic, weak) IBOutlet UILabel *placeLabel;
@property (nonatomic, weak) IBOutlet UILabel *minMaxTemp;
@property (nonatomic, weak) IBOutlet UILabel *currentTempLabel;
@property (nonatomic, weak) IBOutlet UILabel *weatherStatus;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIView *circleView;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, assign) BOOL queryInProgress;

@end

