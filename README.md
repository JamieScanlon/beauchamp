# Beauchamp
A behavior prediction engine

Pre-release

## What is Beauchamp?

TLDR; - You tell Beauchamp how a user is using your app. Beauchamp tells you how that user is likely to use it next time.

Having an app with good UX is table stakes for todays app market. Understanding how easy it is for your users to navigate around and find the information they need is essential in building an app where users are likely to return. Methods like A/B testing are commonplace now in order to refine UX and eliminate pain points for users. But the next step in making an app easy to use is recognizing that people are different.

Rarely do users engage with all of the features in your app. Most will only use a subset but that subset might be different on a user-by-user basis. Instead of simply appealing to the majority, great apps will observe what features an individual is using most often and anticipate those needs by surfacing them more prominently, or making them easier to get to.

Take the example of a group messaging app. Most users will probably want to land in the general chat room when they open the app. For first-time users this is a great place to put them so they have a general sense of the conversation that's going on. But as a user gets more advanced, a user might find more value in spending most of their time in a room that is more specific to their interests. It would be a constant source of frustration if every time a user opened the app, they landed in the general discussion room and then had to navigate to their favorite room, especially if there are many rooms available and navigating to the room that they want involves several clicks or a search.

Beauchamp's goal is to solve this problem. In this example, you could record which room the user navigates to. Every time they visit the app and navigate to a particular room, Beauchamp is able to use the choices the user has made in the past to predict the choices they are likely to make in the future. So the next time they open the app, you can immediately drop them into their favorite room.

## Project Goals

Beauchamp aims to provide a general framework for predicting user behavior based on past behavior. All behavior recording and prediction is done locally so the users privacy is intact. Beauchamp can be used on a session-by-session basis or behavior data can be persisted across sessions.

## Requirements

- iOS 9.0+
- Swift 3+

## Installing Beauchamp

### Carthage

Use the [Carthage](https://github.com/Carthage/Carthage) installation instructions to setup Carthage in your project

Add the following to your `Cartfile`:

```ogdl
github "JamieScanlon/Beauchamp" >= 0.3.0
```

Run `carthage update` to build the framework

### CocoaPods

Use the [CocoaPods](http://cocoapods.org) installation instructions to setup Carthage in your project

Add the following to your `Podfile`:

```ruby
pod 'Beauchamp', '~> 0.3.0'
```

Run `pod install` to build the framework

### Manual

Manual installation is available by cloning this project and copying the source files located in `Beauchamp/Beauchamp` into your project

## Using Beauchamp

Each set of choices the user can make is organized into a `Study` which contains a collection of `Option`'s. A typical `Study` would represent something like a tab navigation and each `Option` in the `Study` would represent a tab. `Option`s store information about the number of time the user has encountered the option and the number of times the user has taken the option. This data is used to predict which options the user is likely to choose in the future. In general, you will be interacting directly with one or more `Study`s which will mannage it's own `Option` objects.

Start off by importing Beauchamp:
```swift
import Beauchamp
```

### Setting up a Study

Set up a new `Study` by providing a description for the `Study` as well as a list of option descriptions. The `Study` will create and manage the `Option` objects and you will reference options by their description therefore every `Option` in a `Study` must have a unique description:

```swift
let description1 = "Photos Tab"
let description2 = "Messages Tab"
let description3 = "Settings Tab"
let tabStudy = Study(description: "Home page tab navigation study", optionDescriptions: [description1, description2, description3])
```

#### Using Options to set an inital state

The example above sets up a `Study` with brand new `Option`s. Most of the time this is what you want but if you want to set up a `Study` that has some prepopulated data you can do so by providing your own `Option` objects when you initialize the `Study`.

```swift
let option1 = Option(description: "Photos Tab", timesTaken: 1, timesEncountered: 10)
let option2 = Option(description: "Messages Tab", timesTaken: 2, timesEncountered: 10)
let option3 = Option(description: "Settings Tab", timesTaken: 3, timesEncountered: 10)
let tabStudy = Study(description: "Home page tab navigation study", options: [option1, option2, option3])
```

In this example the `Study` is initialized with some prepopulated data so if you were to ask the `Study` to predict the most likely option immediately after initialization, it would predict `option3` because it has the highest `timesTaken`. It is important to note that all `Option`s in a `Study` have the same `timesEncountered` value so if you initialize the `Study` this way and do not provide the same `timesEncountered` value for all `Options`, the `Study` will use the highest `timesEncountered` and normalize all of the other `Option`s to this value.

### Recording user behavior

Let's take the example of recording user behavior for a tab navigation where the `Study` contains three options representing three tabs. After setting up the `Study` the only thing you have to do is tell Beauchamp whenever the user chooses a tab. Whenever the user 'takes' or chooses one of the options you have presented you call `recordOptionTaken(withDescription: optionDescription)` with the option that was chosen by the user. For example:

```swift
func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
    let optionDescription: String = getOptionForViewController(viewController)
    tabStudy.recordOptionTaken(withDescription: optionDescription)
}
```

In this example `getOptionForViewController` is a function that maps the UIViewController of a tab with one of the option descriptions in the `Study` i.e. "Photos Tab", "Messages Tab", or "Settings Tab" from above.

### Predicting behavior

A `Prediction` object is returned by a `Study` when you request the most likely option the user will choose. The `Prediciton` objects just contains the `Option` it predicts along with a `confidence` score. `confidence` is a number from 0 to 1 where 0 represents a blind guess and 1 represents absolute certainty. You can use this `confidence` score to determine if the prediction is useful enough to act on. Here's an example:

```swift
override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
	if let prediction = tabStudy.getMostLikelyPrediciton() where prediction.confidence > 0.5 {
		let index = getTabIndexOfOption(prediction.option)
		selectedIndex = index
	}
}
```

In this example, the proper default tab is selected only if the `confifence` is above 0.5. `getTabIndexOfOption` is a function that returns the index of the tab that an `Option` in the `Study` represents.

## BeauchampPersistence

BeauchampPersistence is an optional add-on framework that can be used to save study data locally and reload it on app launch. BeauchampPersistence comes with three standard persistence classes that can save `Study` data in two different ways. `BeauchampFilePersistence` saves `Study` objects as files in a directory that you choose. `BeauchampUserDefaultsPersistence` saves `Study` objects to NSUserDefaults under a key that you choose.`BeauchampCloudKitPersistence` saves `Study` objects in CloudKit's `NSUbiquitousKeyValueStore` under a key that you choose. The persistence classes listen for notifications generated by `Study` objects when changes occur. Using the persistence classes requires only that you instantiate one with the required parameters and it will handle the rest.

Start off by importing Beauchamp:
```swift
import BeauchampPersistence
```

### Persisting Studies

Here's and example of instantiating `BeauchampFilePersistence`:

```swift
let documentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
let archiveURL = documentsDirectory.URLByAppendingPathComponent("beauchamp")
beauchampPersistance = BeauchampFilePersistence.sharedInstance
beauchampPersistance.saveDirectory = archiveURL
```

Here's and example of instantiating `BeauchampUserDefaultsPersistence`:

```swift
let defaults = NSUserDefaults.standardUserDefaults()
let defaultsKey = "com.tenthlettermade.beauchamp"
beauchampPersistance = BeauchampUserDefaultsPersistence.sharedInstance
beauchampPersistance.defaults = defaults
beauchampPersistance.defaultsKey = defaultsKey
```

Here's and example of instantiating `BeauchampCloudKitPersistence`:

```swift
let ubiquitousStoreKey = "com.tenthlettermade.beauchamp"
beauchampPersistance = BeauchampCloudKitPersistence.sharedInstance
beauchampPersistance.ubiquitousStoreKey = ubiquitousStoreKey
```

### Loading persisted Studies

In order to load in `Study` objects that were previously saved by `BeauchampFilePersistence`, `BeauchampUserDefaultsPersistence`, or `BeauchampCloudKitPersistence` you simple call the `reconstituteStudies()` on either which will return an array of `Study` objects or nil if there is not yet any data. For example:

```swift
if let studies = beauchampPersistance.reconstituteStudies() {
	// Start using the saved Studies
} else {
	// No saved studies found, create a new one.
}
```

## Roadmap
1. Add a time weighted prediction where most recent options are weighted more heavily
2. Add an Obj-C wrapper
3. Machine learning.
