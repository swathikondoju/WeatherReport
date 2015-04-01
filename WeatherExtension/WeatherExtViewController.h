//
//  WeatherExtViewController.h
//  WeatherExtension
//
//  Created by Swathi Kondoju on 3/29/15.
//  Copyright (c) 2015 Swathi Kondoju. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface WeatherExtViewController : UIViewController<CLLocationManagerDelegate>
{
    float latitude;
    float longitude;
    CLLocationManager *locationManager;
    UITapGestureRecognizer *gestureRecognizer;
}
@property (nonatomic, weak) IBOutlet UILabel *placeLabel;
@property (nonatomic, weak) IBOutlet UILabel *currentTempLabel;
@property (nonatomic, weak) IBOutlet UILabel *minMaxTempLabel;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;

@end
