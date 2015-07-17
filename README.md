#AppRater
AppRater is library for iOS for prompting users to rate your app on iTunes. It won't prompt until 3 days AND 7 launches by default. 

It supports iOS 5 and later.;

![Example Image ios6][1] ![Example Image ios7][2]

##Usage
Simply drag AppRater.h, .m files into your project and add this line to your appDelegate:
```objective-c
[[AppRater sharedInstance] appLaunched];
```

AppRater doesn't require configuration. Automatically checks your application's iTunes id with using application's bundle id. For more examples see sample application.

##Configuration
AppRater have several properties that can alter the AppRater's behaviour.
```objective-c
@property (nonatomic) NSInteger daysUntilPrompt;
```
Number of days the user have had the application before they are prompted. The default value is 3 days.

```objective-c
@property (nonatomic) NSInteger launchesUntilPrompt;
```
Minimum launch count the user must launch the application before they are prompted. Calling from background increases this number. The default value is 7 launches.

```objective-c
@property (nonatomic) NSInteger remindMeDaysUntilPrompt;
```
If user select "Remind me later" option this property will be using like  `daysUntilPrompt`. The default value is 3 days.

```objective-c
@property (nonatomic) NSInteger remindMeLaunchesUntilPrompt;
```
If user select "Remind me later" option this property will be using like  `launchesUntilPrompt`. The default value is 7 launches.

```objective-c
@property (nonatomic) BOOL versionCheckEnabled;
```
Set this to YES if you want to re-run your prompt scenario after a new version of your application. The default value is NO;

```objective-c
@property (nonatomic) BOOL hideNoButton;
```
Set this to YES if you want to force user to rate your application now or later. The default value is NO.

```objective-c
@property (nonatomic, strong) NSString *preferredLanguage;
```
Set preferred language on your prompt window. English and Turkish supported. Uses default locale, default value is "en".

 [1]: https://raw.github.com/Turkcell/AppRater_iOS/master/ScreenShots/ios6.png
 [2]: https://raw.github.com/Turkcell/AppRater_iOS/master/ScreenShots/ios7.png
