/*******************************************************************************
 *
 *  Copyright (C) 2014 Turkcell
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 *******************************************************************************/


#import "AppRater.h"

/**
 *  Defines for NSUserDefaults keys
 */
#define VERSION_CHECK_KEY @"isVersionCheckEnabled"
#define DAYS_UNTIL_CHECK_KEY @"daysUntilCheck"
#define LAUNCHES_UNTIL_CHECK_KEY @"launchesUntilCheck"
#define LAUNCH_COUNT_KEY @"launchCount"
#define FIRST_LAUNCH_KEY @"firstLaunchKey"
#define DONT_SHOW_AGAIN_KEY @"dontShowAgain"
#define REMIND_ME_KEY @"remindMeLater"
#define APP_VERSION_KEY @"appVersion"
#define ITUNES_IDENTIFIER_KEY @"itunesAppID"

/**
 *  Defines for application's page on itunes
 *  @see http://stackoverflow.com/questions/3654144/direct-rate-in-itunes-link-in-my-app
 */
#define iOS7AppStoreURL @"itms-apps://itunes.apple.com/app/id%@"
#define AboveiOS7AppstoreURL @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@"
#define AppStoreLookUpURL @"http://itunes.apple.com/tr/lookup?bundleId=%@"

#define IS_IOS7 (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1)

@implementation AppRater

@synthesize daysUntilPrompt, launchesUntilPrompt,
            versionCheckEnabled, remindMeDaysUntilPrompt,
            remindMeLaunchesUntilPrompt, hideNoButton, preferredLanguage;

/**
 *  Creates static AppRater object and sets default values
 *
 *  @return sharedIntance
 */
+(AppRater *)sharedInstance {
    static dispatch_once_t pred;
    static AppRater *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[AppRater alloc] init];
        sharedInstance.daysUntilPrompt = 3;
        sharedInstance.launchesUntilPrompt = 7;
        sharedInstance.remindMeDaysUntilPrompt = 3;
        sharedInstance.remindMeLaunchesUntilPrompt = 7;
        sharedInstance.versionCheckEnabled = NO;
        sharedInstance.hideNoButton = NO;
        sharedInstance.preferredLanguage = nil;
    });
    return sharedInstance;
}

/**
 *  init method override. Registers a ApplicationWillEnterForeground notification
 *  for catch app launch from background.
 *
 *  @return self
 */
-(AppRater *)init {
    
    if (&UIApplicationWillEnterForegroundNotification) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    
    return self;
}

/**
 *  Public method checks rating prompt with given parameters version checking and remind me
 */
-(void)appLaunched {
    
    if (versionCheckEnabled) {
        if (![[self getCurrentVersion] isEqualToString:[self getStringFromDefaultsWithKey:APP_VERSION_KEY]]) {
            [self resetUserDefaultValues];
            [self setObjectToDefaultsWithKey:APP_VERSION_KEY andValue:[self getCurrentVersion]];
        }
    }
    
    if ([[self getObjectFromDefaultsWithKey:REMIND_ME_KEY] boolValue]) {
        [self appLaunchedWithDaysUntilCheck:remindMeDaysUntilPrompt andLaunchesUntilCheck:remindMeLaunchesUntilPrompt];
    }else {
        [self appLaunchedWithDaysUntilCheck:daysUntilPrompt andLaunchesUntilCheck:launchesUntilPrompt];
    }
}

/**
 *  Checks the 'dont show again' and given days parameters.
 *
 *  @param days     daysUntilPrompt or remindMeDaysUntilPrompt
 *  @param launches launchesUntilPrompt or remindMeLaunchesUntilPrompt
 */
-(void)appLaunchedWithDaysUntilCheck:(NSInteger)days andLaunchesUntilCheck:(NSInteger)launches {
    if ([[self getObjectFromDefaultsWithKey:DONT_SHOW_AGAIN_KEY] boolValue]) {
        return;
    }
    NSInteger launchCount = [self getIntFromDefaultsWithKey:LAUNCH_COUNT_KEY]+1;
    [self setIntToDefaultsWithKey:LAUNCH_COUNT_KEY andValue:launchCount];
    
    if (launchCount >= launches && [self isDateExpired:days]) {
        [self getApplicationID];
    }

}

/**
 *  Catch the application will enter foreground notification
 */
- (void)applicationWillEnterForeground {
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        [self appLaunched];
    }
}

#pragma mark - User Defaults

/**
 *  Sets the key/value parameters to NSUserDefaults
 *
 *  @param key   given object key
 *  @param value given object
 */
-(void)setObjectToDefaultsWithKey:(NSString *)key andValue:(id)value {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 *  Sets the key/value parameters to NSUserDefaults as Integer
 *
 *  @param key   given Integer key
 *  @param value given Integer
 */
-(void)setIntToDefaultsWithKey:(NSString *)key andValue:(NSInteger)value {
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 *  Sets the key/value parameters to NSUserDefaults as Boolean
 *
 *  @param key   given Boolean key
 *  @param value given Boolean
 */
-(void)setBoolToDefaultsWithKey:(NSString *)key andValue:(BOOL)value {
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 *  Retuns the key's value from NSUserDefaults as String
 *  if given key's value is nil, retuns an empty string for string compare
 *
 *  @param key  key of desired string
 *
 *  @return value of given key. if nil returns an empty string
 */
-(NSString *)getStringFromDefaultsWithKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] objectForKey:key] == nil ? @"":[[NSUserDefaults standardUserDefaults] stringForKey:key];
}

/**
 *  Retuns the key's value from NSUserDefaults as Integer
 *
 *  @param key key of desired integer
 *
 *  @return values of given key
 */
-(NSInteger)getIntFromDefaultsWithKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] integerForKey:key];
}

/**
 *  Retuns the key's value from NSUserDefaults as id
 *
 *  @param key key of desired object
 *
 *  @return value of given key
 */
-(id)getObjectFromDefaultsWithKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

/**
 *  Reset the user defined parameters. Such as remind me etc.
 */
-(void)resetUserDefaultValues {
    [self setBoolToDefaultsWithKey:DONT_SHOW_AGAIN_KEY andValue:NO];
    [self setBoolToDefaultsWithKey:REMIND_ME_KEY andValue:NO];
    [self setIntToDefaultsWithKey:LAUNCH_COUNT_KEY andValue:0];
    [self setObjectToDefaultsWithKey:FIRST_LAUNCH_KEY andValue:[NSDate date]];
}

#pragma mark - Worker methods

/**
 *  Returns the current application version from main bundle.
 *
 *  @return current version of app as string
 */
-(NSString *)getCurrentVersion {
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return versionString;
}

/**
 *  Checks the given application's first launch date is bigger thangiven day parameter
 *
 *  @param days
 *
 *  @return current date is bigger than daysUntilPrompt or remindMeDaysUntilPrompt
 */
-(BOOL)isDateExpired:(NSInteger)days {
    NSDate *firstLaunchDate = [self getObjectFromDefaultsWithKey:FIRST_LAUNCH_KEY];
    
    if (firstLaunchDate == nil || [firstLaunchDate isKindOfClass:[NSNull class]]) {
        firstLaunchDate = [NSDate date];
        [self setObjectToDefaultsWithKey:FIRST_LAUNCH_KEY andValue:firstLaunchDate];
    }
    
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:firstLaunchDate];
    
    return (interval >= days*24*60*60);
}

#pragma mark - AppRater Dialog

/**
 *  Shows the dialog if prompted. Checks the hideNoButton parameter.
 */
-(void)showRater {
    UIAlertView *rateDialog = nil;
    NSString *noButtonTitle = nil;
    if (!hideNoButton) {
        noButtonTitle = [self getLocalisedStringForKey:@"NoButtonTitle"];
    }
    
    rateDialog = [[UIAlertView alloc] initWithTitle:[self getLocalisedStringForKey:@"MessageTitle"] message:[self getLocalisedStringForKey:@"Message"] delegate:self cancelButtonTitle:noButtonTitle otherButtonTitles:[self getLocalisedStringForKey:@"NowButtonTitle"], [self getLocalisedStringForKey:@"LaterButtonTitle"], nil];
    [rateDialog show];
    
}

/**
 *  AlertView delegate for
 *
 *  @param alertView   active alertView
 *  @param buttonIndex selected button index
 */
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    //Ouokl
    if (hideNoButton) { //Now->0, Later->1
        switch (buttonIndex) {
            case 0:
                [self openItunes];
                [self setBoolToDefaultsWithKey:DONT_SHOW_AGAIN_KEY andValue:YES];
                break;
            case 1:
                [self setBoolToDefaultsWithKey:DONT_SHOW_AGAIN_KEY andValue:NO];
                [self setBoolToDefaultsWithKey:REMIND_ME_KEY andValue:YES];
                [self setIntToDefaultsWithKey:LAUNCH_COUNT_KEY andValue:0];
                [self setObjectToDefaultsWithKey:FIRST_LAUNCH_KEY andValue:[NSDate date]];
                break;
            default:
                break;
        }
    }else {
        switch (buttonIndex) { //Cancel->0, Now->1, Later->2
            case 0:
                [self setBoolToDefaultsWithKey:DONT_SHOW_AGAIN_KEY andValue:YES];
                [self setBoolToDefaultsWithKey:REMIND_ME_KEY andValue:NO];
                [self setIntToDefaultsWithKey:LAUNCH_COUNT_KEY andValue:0];
                [self setObjectToDefaultsWithKey:FIRST_LAUNCH_KEY andValue:[NSDate date]];
                break;
            case 1:
                [self openItunes];
                [self setBoolToDefaultsWithKey:DONT_SHOW_AGAIN_KEY andValue:YES];
                break;
            case 2:
                [self setBoolToDefaultsWithKey:DONT_SHOW_AGAIN_KEY andValue:NO];
                [self setBoolToDefaultsWithKey:REMIND_ME_KEY andValue:YES];
                [self setIntToDefaultsWithKey:LAUNCH_COUNT_KEY andValue:0];
                [self setObjectToDefaultsWithKey:FIRST_LAUNCH_KEY andValue:[NSDate date]];
                break;
            default:
                break;
        }
    }
}

#pragma mark - AppStore

/**
 *  If user want to rate app open application's itunes page
 */
-(void)openItunes {
    
    NSURL *itunesURL = nil;
    
    if (IS_IOS7) {
        itunesURL = [NSURL URLWithString:[NSString stringWithFormat:iOS7AppStoreURL, [self getStringFromDefaultsWithKey:ITUNES_IDENTIFIER_KEY]]];
    }else {
        itunesURL = [NSURL URLWithString:[NSString stringWithFormat:AboveiOS7AppstoreURL, [self getStringFromDefaultsWithKey:ITUNES_IDENTIFIER_KEY]]];
    }
    
    if ([[UIApplication sharedApplication] canOpenURL:itunesURL]) {
        [[UIApplication sharedApplication] openURL:itunesURL];
    }else {
        NSLog(@"Couldn't open iTunes URL");
    }
}

/**
 *  Gets the application's itunes id. Uses itunes lookup service.
 *  
 *  @see https://www.apple.com/itunes/affiliates/resources/documentation/itunes-store-web-service-search-api.html
 */
-(void)getApplicationID {
    
    if (![[self getStringFromDefaultsWithKey:ITUNES_IDENTIFIER_KEY] isEqualToString:@""]) {
        [self showRater];
        return;
    }
    
    __block NSString *bundleIdentifier = @"com.turkcell.guvenlik";
//    [[NSBundle mainBundle] bundleIdentifier];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:AppStoreLookUpURL, bundleIdentifier]]];
        [request setTimeoutInterval:30.0];
        NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{

            NSError *e = nil;
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error: &e][@"results"];
            
            if (!jsonArray) {
                NSLog(@"Error parsing JSON: %@", e);
            } else {
                
                if (jsonArray.count < 1) {
                    NSLog(@"Application couldn't find on iTunes");
                    return;
                }
                for(NSDictionary *item in jsonArray) {
                    if ([item objectForKey:@"trackId"] == nil || [[item objectForKey:@"trackId"] isKindOfClass:[NSNull class]]) {
                        NSLog(@"Application couldn't find on iTunes");
                    }else {
                        [self setObjectToDefaultsWithKey:ITUNES_IDENTIFIER_KEY andValue:[item objectForKey:@"trackId"]];
                        [self showRater];
                    }
                }
            }
            
        });
    });
}

#pragma mark - Localisation Support

/**
 *  Localisation support. Gets localised string from language bundle.
 *
 *  @param key key of localised string
 *
 *  @return localised string
 */
-(NSString *)getLocalisedStringForKey:(NSString *)key {
    
    static NSBundle *bundle = nil;
    
    if (bundle == nil) {
        bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"AppRater" ofType:@"bundle"]];
    }
    NSString *systemLocale = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    static NSBundle *languageBundle = nil;
    
    if (preferredLanguage) {
        if (![[bundle localizations] containsObject:preferredLanguage]) {
            if (![[bundle localizations] containsObject:systemLocale]) {
                NSLog(@"Preffered language is not avaible.");
                systemLocale = @"en";
            }
        }else {
            systemLocale = preferredLanguage;
        }
    }

    languageBundle = [NSBundle bundleWithPath:[bundle pathForResource:systemLocale ofType:@"lproj"]];
    return [languageBundle localizedStringForKey:key value:@"" table:nil];
}

#pragma mark - Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
