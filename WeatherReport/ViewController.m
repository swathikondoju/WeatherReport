//
//  ViewController.m
//  WeatherReport
//
//  Created by Swathi Kondoju on 3/23/15.
//  Copyright (c) 2015 Swathi Kondoju. All rights reserved.
//

#import "ViewController.h"
#import "WeatherReportLib.h"

UIImage *rainImage;
UIImage *mistImage;
UIImage *clearImage;
UIImage *snowImage;

BOOL monitoringCurrentLocation = NO;
BOOL showCurrentLocationFailure = YES;
BOOL showCurrentLocation = YES;

@implementation ViewController

@synthesize placeLabel, minMaxTemp, currentTempLabel, weatherStatus, imageView, circleView, searchBar;
@synthesize backgroundImageView, activityIndicator, queryInProgress;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    queryInProgress = NO;
    searchBar.delegate = self;
    
    //Initialize circle view
    [circleView.layer setBorderWidth:1.0f];
    [circleView.layer setBorderColor:[UIColor whiteColor].CGColor];
    [circleView.layer setCornerRadius:(circleView.frame.size.width)/2];
    [circleView setClipsToBounds:YES];
    [circleView setBackgroundColor:[UIColor clearColor]];
    [self.view sendSubviewToBack:circleView];
    [self hideCircleView];

    //Add background image view
    backgroundImageView = [[UIImageView alloc] init];
    [backgroundImageView setFrame:self.view.frame];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    
    mistImage = [UIImage imageNamed:@"Mist.jpeg"];
    rainImage = [UIImage imageNamed:@"Rain.jpg"];
    clearImage = [UIImage imageNamed:@"Clear.jpeg"];
    snowImage = [UIImage imageNamed:@"Snow.jpeg"];
    
    //Add tap gesture recognizer
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignKeyboard:)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    //Initialize activity indicator
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin |UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:activityIndicator];
    activityIndicator.hidesWhenStopped = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppActiveNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
    
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
    
    //Thread to monitor weather at current location
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self monitorCurrentLocation];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewDidLayoutSubviews
{
    activityIndicator.center  = self.view.center;
}

/*
 For now we just support portrait orientation
 */
-(NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(BOOL) shouldAutorotate
{
    return NO;
}

#pragma mark - CLLocationManagerDelegate methods
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *lastLocation = [locations lastObject];
    
    currentLatitude = lastLocation.coordinate.latitude;
    currentLongitude = lastLocation.coordinate.longitude;
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

#pragma mark - Actions
-(void) resignKeyboard:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self.view];
    CGRect textFieldBounds = [searchBar bounds];
    
    if(!CGRectContainsPoint(textFieldBounds, location))
    {
        //Close the keyboard if user taps outside the search bar
        [searchBar resignFirstResponder];
    }
}

/*
 Query weather api with location coordinates
 */
-(void) getWeatherReportForLongitude:(CLLocationDegrees)longitude Latitude:(CLLocationDegrees)latitude
{
    if(queryInProgress || !showCurrentLocation)
        return;
    
    NSString *urlQuery = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f", latitude, longitude];

    [activityIndicator startAnimating];

    queryInProgress = YES;
    UrlConnection *urlconnection = [[UrlConnection alloc] initWithQuery:urlQuery withCompletionBlock:^(BOOL success, NSError *error, NSDictionary *responseDict) {
        if(success)
        {
            [self showCircleView];
            [self updateCurrentWeather:responseDict];
            showCurrentLocationFailure = YES;
        }
        else
        {
            if(showCurrentLocationFailure)
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:[NSString stringWithFormat:@"Failed to get weather information for current location."] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alertView show];
                showCurrentLocationFailure = NO;
            }
        }
        
        if([activityIndicator isAnimating])
            [activityIndicator stopAnimating];
        
        queryInProgress = NO;
    }];

    [urlconnection executeQuery];
}

/*
 Update weather information in the view
 */
-(void) updateCurrentWeather:(NSDictionary *)responseDict
{
    if(!responseDict)
        return;
    
    NSString *placeName = [responseDict objectForKey:@"name"];
    NSDictionary *sys = [responseDict objectForKey:@"sys"];
    
    NSString *country = [sys objectForKey:@"country"];
    
    NSArray *weatherArray = [responseDict objectForKey:@"weather"];
    
    NSDictionary *weatherDict = [weatherArray objectAtIndex:0];
    
    NSString *mainWeather = [weatherDict objectForKey:@"main"];
    NSString *description = [weatherDict objectForKey:@"description"];
    NSString *icon = [weatherDict objectForKey:@"icon"];
    
    NSDictionary *mainDict = [responseDict objectForKey:@"main"];
    if(!mainDict)
    {
        [backgroundImageView setImage:nil];
        [imageView setImage:nil];
        [currentTempLabel setTextColor:[UIColor whiteColor]];
        [currentTempLabel setText:@"N/A"];
        [placeLabel setText:@""];
        [minMaxTemp setText:@""];
        [weatherStatus setText:@""];
        return;
    }
    
    double currentTemp = [[mainDict objectForKey:@"temp"] doubleValue] - 273.15;
    double maxTemperature = [[mainDict objectForKey:@"temp_max"] doubleValue] - 273.15;
    double minTemperature = [[mainDict objectForKey:@"temp_min"] doubleValue] - 273.15;
    
    weatherType type;
    
    if([icon isEqualToString:@"01d"] || [icon isEqualToString:@"01n"])
    {
        [backgroundImageView setImage:clearImage];
        type = CLEAR;
    }
    else if([icon isEqualToString:@"02d"] || [icon isEqualToString:@"02n"] ||
            [icon isEqualToString:@"03d"] || [icon isEqualToString:@"03n"] ||
            [icon isEqualToString:@"04d"] || [icon isEqualToString:@"04n"] ||
            [icon isEqualToString:@"09d"] || [icon isEqualToString:@"09n"] ||
            [icon isEqualToString:@"10d"] || [icon isEqualToString:@"10n"] ||
            [icon isEqualToString:@"11d"] || [icon isEqualToString:@"11n"] )
    {
        [backgroundImageView setImage:rainImage];
        type = RAIN;
    }
    else if([icon isEqualToString:@"13d"] || [icon isEqualToString:@"13n"])
    {
        [backgroundImageView setImage:snowImage];
        type = SNOW;
    }
    else if([icon isEqualToString:@"50d"] || [icon isEqualToString:@"50n"])
    {
        [backgroundImageView setImage:mistImage];
        type = MIST;
    }
    
    [self updateViewLabels:type];
    
    if(placeName && ![placeName isEqualToString:@""])
        [placeLabel setText:[NSString stringWithFormat:@"%@, %@", placeName, country]];
    else
        [placeLabel setText:country];
    
    [currentTempLabel setText:[NSString stringWithFormat:@"%.1lf%@", currentTemp, @"\u00B0"]];
    [minMaxTemp setText:[NSString stringWithFormat:@"%.1lf%@/%.1lf%@", minTemperature, @"\u00B0", maxTemperature, @"\u00B0"]];
    
    NSString *weatherStatusString = nil;
    
    if(mainWeather && description)
        weatherStatusString = [NSString stringWithFormat:@"%@ (%@)", mainWeather, description];
    else if(mainWeather && !description)
        weatherStatusString = mainWeather;
    else
        weatherStatusString = description;
    
    [weatherStatus setText:weatherStatusString];
    
    NSString *imageUrl = @"http:////openweathermap.org/img/w/";
    NSString *imagePath = [[NSString stringWithFormat:@"%@/%@.png",imageUrl, icon] stringByStandardizingPath];
    
    NSString *string = [imagePath stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSURL *url = [NSURL URLWithString:string];
    
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    UIImage *image = nil;
    
    if(data)
    {
        image = [[UIImage alloc] initWithData:data];
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        [imageView setImage:image];
    }
}

-(void) hideCircleView
{
    [circleView setHidden:YES];
}

-(void) showCircleView
{
    [circleView setHidden:NO];
    [circleView setNeedsDisplay];
}

/*
 Show weather info for current location
 */
-(IBAction)showWeatherForCurrentLocation:(id)sender
{
    showCurrentLocation = YES;
    [searchBar setText:@""];
    showCurrentLocationFailure = YES;
    [self getWeatherReportForLongitude:currentLongitude Latitude:currentLatitude];
}

/*
 Update text colors for labels
 */
-(void) updateViewLabels:(weatherType)type
{
    switch (type) {
        case CLEAR:
        {
            [placeLabel setTextColor:[UIColor whiteColor]];
            [currentTempLabel setTextColor:[UIColor blackColor]];
            [minMaxTemp setTextColor:[UIColor blackColor]];
            [weatherStatus setTextColor:[UIColor blackColor]];
        }
            break;
        case RAIN:
        {
            [placeLabel setTextColor:[UIColor whiteColor]];
            [currentTempLabel setTextColor:[UIColor whiteColor]];
            [minMaxTemp setTextColor:[UIColor whiteColor]];
            [weatherStatus setTextColor:[UIColor whiteColor]];
        }
            break;
            
        case MIST:
        {
            [placeLabel setTextColor:[UIColor blackColor]];
            [currentTempLabel setTextColor:[UIColor blackColor]];
            [minMaxTemp setTextColor:[UIColor blackColor]];
            [weatherStatus setTextColor:[UIColor blackColor]];
            
        }
            break;
            
        case SNOW:
        {
            [placeLabel setTextColor:[UIColor whiteColor]];
            [currentTempLabel setTextColor:[UIColor whiteColor]];
            [minMaxTemp setTextColor:[UIColor whiteColor]];
            [weatherStatus setTextColor:[UIColor whiteColor]];
            
        }
            break;
            
        default:
            break;
    }
}

/*
 Monitor the weather at current location every 10sec
 */
-(void) monitorCurrentLocation
{
    if(monitoringCurrentLocation)
        return;
    
    while(1)
    {
        monitoringCurrentLocation = YES;
        if(currentLatitude != 0 || currentLongitude != 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self getWeatherReportForLongitude:currentLongitude Latitude:currentLatitude];
            });
            sleep(10);
        }
    }
}

/*
 Clear the search bar text
 */
-(void) handleAppActiveNotification
{
    [searchBar setText:@""];
}

#pragma mark - UISearchBarDelegate methods

/*
 Get weather info for the search location
 */
-(void) searchBarSearchButtonClicked:(UISearchBar *)sender
{
    if(queryInProgress)
        return;
    
    showCurrentLocation = NO;
    
    NSString *searchString = [[searchBar text] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

    [sender resignFirstResponder];
    
    [placeLabel setText:@""];
    
    NSString *urlQuery = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?q=%@&type=like", searchString];
    
    [self hideCircleView];
    [activityIndicator startAnimating];
    queryInProgress = YES;
    UrlConnection *urlconnection = [[UrlConnection alloc] initWithQuery:urlQuery withCompletionBlock:^(BOOL success, NSError *error, NSDictionary *responseDict) {
        if(success)
        {
            [self showCircleView];
            [self updateCurrentWeather:responseDict];
        }
        else
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Warning" message:[NSString stringWithFormat:@"Failed to get weather information for location '%@'.", [searchBar text]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alertView show];
        }
        [activityIndicator stopAnimating];
        queryInProgress = NO;
    }];
    
    [urlconnection executeQuery];
}

@end
