# Tapster iOS Demo

[![Build Status](https://travis-ci.org/minhtule/Tapster-iOS-Demo.svg?branch=master)](https://travis-ci.org/minhtule/Tapster-iOS-Demo)


This demo demonstrates how to use the [PredictionIO Swift SDK](https://github.com/minhtule/PredictionIO-Swift-SDK) to integrate an iOS app with a [PredictionIO](https://github.com/apache/predictionio) engine to make your mobile app more interesting.

### Requirements

- [PredictionIO 0.14.0+](https://predictionio.apache.org/install/)
- Xcode 11.0+ and iOS 10.0+
- Swift 5+

### Demo

[![thumbnail](http://img.youtube.com/vi/4kde72NhQ0o/0.jpg)](http://youtu.be/4kde72NhQ0o)

## Quick Setup

### Set up the PredictionIO Engine

* Clone the similar product engine for Tapster iOS

```bash
$ git clone https://github.com/minhtule/Tapster-iOS-Demo-Similar-Product-Engine.git tapster-similar-product
```

* Create a new PredictionIO app and build the engine.

```bash
# Need to start HBase and Elasticsearch first
$ pio-start-all
$ pio app new tapster
$ cd tapster-similar-product
$ pio build
```

**Note:** If your PredictionIO app is not `tapster`, you need to update the `appName` field in the `engine.json` file with the new app name.

### Set up the iOS app

* Install Gemfile
```bash
bundle install
```

* Install CocoaPods dependencies

```bash
$ cd ..
# Clone this iOS repo if you haven't done so
$ git clone https://github.com/minhtule/Tapster-iOS-Demo
# Switch to the Xcode project directory
$ cd Tapster-iOS-Demo
$ pod install
```

### Import data and train the engine

* Start the PredictionIO event server.

```bash
# Switch back to the engine directory
$ cd ../tapster-similar-product
$ pio eventserver
```

* Open the iOS project workspace `Tapster iOS Demo.xcworkspace` (created by CocoaPods) in Xcode. We need to add the PredictionIO app's access key to the iOS app's `EventClient`. In `DataViewController.swift`,

```swift
let eventClient = EventClient(accessKey: "<Your app's access key here>")
```

Run the simulator. In the home screen, tap `Import Data` and then `Run Import` button. The whole import will take a while. Check Xcode's debug console to see the progress.

* Now we can train and deploy our engine. In the engine directory, run

```bash
# At the engine directory
$ pio train
$ pio deploy
```

Now the recommendation engine is ready and you can start reading comics! In the app home screen, tap the `Start Reading` button. You can then swipe right to like a comic and swipe left to dislike just like in Tinder!

## Tutorial
For step-by-step instructions, check out the detailed [tutorial](https://github.com/minhtule/Tapster-iOS-Demo/blob/master/TUTORIAL.md).

## License
Tapster iOS Demo is released under the MIT license. See
[LICENSE](https://github.com/minhtule/Tapster-iOS-Demo/blob/master/LICENSE) for
details
