//
//  WeatherExtViewController.m
//  WeatherExtension
//
//  Created by Swathi Kondoju on 3/29/15.
//  Copyright (c) 2015 Swathi Kondoju. All rights reserved.
//

#import "WeatherExtViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "WeatherReportLib.h"

#define WeatherUrl @"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f"

@implementation WeatherExtViewController

@synthesize currentTempLabel, placeLabel, minMaxTempLabel, statusLabel;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Add gesture recognizer to the view
    gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gotoWeatherApp:)];
    gestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:gestureRecognizer];
    
    self.preferredContentSize = CGSizeMake(0, 70);
    
    //TODO: Read user defaults to get the location to monitor
   // userDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.sample.weatherreport"];
    
    //Initialize location manager
    locationManager = [[CLLocationManager alloc] init];
    
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        if([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
            [locationManager requestWhenInUseAuthorization];
    }
    else
        [locationManager startUpdatingLocation];

    
   __block BOOL queryInProgress = NO;
    
    //Spawn a thread to get current temperature at current location every 20sec
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (YES) {
            if(queryInProgress)
            {
                sleep(10);
                continue;
            }
            
            queryInProgress = YES;
            NSString *urlQuery = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f", latitude, longitude];

            dispatch_async(dispatch_get_main_queue(), ^{
                UrlConnection *urlconnection = [[UrlConnection alloc] initWithQuery:urlQuery withCompletionBlock:^(BOOL success, NSError *error, NSDictionary *responseDict) {
                    if(success)
                    {
                        [self updateCurrentWeather:responseDict];
                    }
                    queryInProgress = NO;
                }];
                
                [urlconnection executeQuery];
            });
            sleep(10);
        }
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsMake(0, 10, 0, 10);
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}

/*
 Update weather info in extension view
 */
-(void) updateCurrentWeather:(NSDictionary *)responseDict
{
    NSString *placeName = [responseDict objectForKey:@"name"];
    if(placeName && [placeName isEqualToString:@""])
        placeName = nil;
    
    NSDictionary *sys = [responseDict objectForKey:@"sys"];
    NSString *country = [sys objectForKey:@"country"];
    if(country && [country isEqualToString:@""])
        country = nil;
    
    NSDictionary *mainDict = [responseDict objectForKey:@"main"];
    
    double maxTemperature = [[mainDict objectForKey:@"temp_max"] doubleValue] - 273.15;
    double minTemperature = [[mainDict objectForKey:@"temp_min"] doubleValue] - 273.15;
    double currentTemp = [[mainDict objectForKey:@"temp"] doubleValue] - 273.15;

    NSArray *weatherArray = [responseDict objectForKey:@"weather"];
    NSDictionary *weatherDict = [weatherArray objectAtIndex:0];
    NSString *mainWeather = [weatherDict objectForKey:@"main"];

    [currentTempLabel setText:[NSString stringWithFormat:@"%.1lf%@", currentTemp, @"\u00B0"]];
    
    if(placeName && country)
        [placeLabel setText:[NSString stringWithFormat:@"%@, %@", placeName, country]];
    else if(placeName)
        [placeLabel setText:placeName];
    else
        [placeLabel setText:country];
    
    [minMaxTempLabel setText:[NSString stringWithFormat:@"%.1lf%@/%.1lf%@", minTemperature, @"\u00B0", maxTemperature, @"\u00B0"]];
    [statusLabel setText:mainWeather];

}

/*
 Open weather report app on tapping the extension
 */
-(IBAction)gotoWeatherApp:(id)sender
{
    NSURL *appUrl = [NSURL URLWithString:@"WeatherReportUrl://home"];
    [self.extensionContext openURL:appUrl completionHandler:nil];
}

#pragma mark - CLLocationManagerDelegate methods
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *lastLocation = [locations lastObject];
    longitude = lastLocation.coordinate.longitude;
    latitude = lastLocation.coordinate.latitude;
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch(status) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            [locationManager startUpdatingLocation];
            break;
        }
            
        default:
            break;
    }
}

@end
