# Tapster iOS Tutorial

### Requirements

- [PredictionIO 0.12.0+](https://predictionio.apache.org/install/)
- Xcode 9.0+ and iOS 9.0+

## PredictionIO Setup

### Create a new app

* After installing PredictionIO, we need to start HBase and Elasticsearch.

```bash
$ pio-start-all
```

**_Note:_** If your computer went into sleep mode, you might need to restart HBase and Elasticsearch.

* Then create a new app.

```bash
$ pio app new tapster
```

Take note of the app name and the access key.

**_Note:_** 

- You can always view all your application's credentials using
```bash
$ pio app list
```

### Setup a Similar Product engine

**Step 1:** Clone the Similar Product Template. This guide uses the template version *v0.12.0*. 

```bash
$ git clone https://github.com/apache/incubator-predictionio-template-similar-product.git tapster-similar-product
$ cd tapster-similar-product
```

**Step 2:** Add our app name `tapster` to the `appName` field in the `engine.json` file.

**Step 3:** Modify our Engine!

* By the default, the template accepts `view` events. So we need to change it to `like` event.

In `DataSource.scala`, modify `viewEventsRDD` in the `readTraining` method.

```scala
override
def readTraining(sc: SparkContext): TrainingData = {
  ...

  // get all "user" "like" "item" events
  val viewEventsRDD: RDD[ViewEvent] = PEventStore.find(
    appName = dsp.appName,
    entityType = Some("user"),
    eventNames = Some(List("like")),  // MODIFIED
    // targetEntityType is optional field of an event.
    targetEntityType = Some(Some("item")))(sc)
    // eventsDb.find() returns RDD[Event]
    .map { event =>
      val viewEvent = try {
        event.event match {
          case "like" => ViewEvent(  // MODIFIED
            user = event.entityId,
            item = event.targetEntityId.get,
            t = event.eventTime.getMillis)
          case _ => throw new Exception(s"Unexpected event ${event} is read.")
        }
      } catch {
        ...
        }
      }
      viewEvent
    }.cache()
  ...
}
```

* By default, the Event Server only accepts the comic's categories. We also need to send in the comic's title and image URLs so that we can return them in the recommendation response.

In `DataSource.scala`, modify `itemsRDD` in the `readTraining` method and also the `Item` class.

```scala
class DataSource(val dsp: DataSourceParams) extends PDataSource[TrainingData,
      EmptyEvaluationInfo, Query, EmptyActualResult] {
  ...
  override
  def readTraining(sc: SparkContext): TrainingData = {
    ...

    // create a RDD of (entityID, Item)
    val itemsRDD: RDD[(String, Item)] = PEventStore.aggregateProperties(
      appName = dsp.appName,
      entityType = "item"
    )(sc).map { case (entityId, properties) =>
      val item = try {
        // Assume categories is optional property of item.
        Item(
          title = properties.get[String]("title"),  // ADDED
          categories = properties.getOpt[List[String]]("categories"),
          imageURLs = properties.get[List[String]]("imageURLs"))  // ADDED
      } catch {
        ...
      }
      (entityId, item)
    }.cache()
    ...
  }
  ...
}

...
case class Item(
  title: String,  // ADDED
  categories: Option[List[String]],
  imageURLs: List[String]  // ADDED
)
...
```

* Initially, the recommendation response only returns the comic ID. We need to also include the comic's other properties: title and imageURLs in the recommendation result.

In `Engine.scala`, modify the `ItemScore` class.

```scala
case class ItemScore(
  itemID: String,  // MODIFIED
  title: String,  // ADDED    
  imageURLs: List[String], // ADDED
  score: Double
) extends Serializable
```

In `ALSAlgorithm.scala`, modify `itemScores` in the `predict` method.

```scala
class ALSAlgorithm(val ap: ALSAlgorithmParams)
  ...

  def predict(model: ALSModel, query: Query): PredictedResult = {
    ...

    val itemScores = topScores.map { case (i, s) =>
      new ItemScore(
        itemID = model.itemIntStringMap(i),  // MODIFIED
        title = model.items(i).title,  // ADDED
        imageURLs = model.items(i).imageURLs,  // ADDED
        score = s
      )
    }

    new PredictedResult(itemScores)
  }
  ...
}
```

In `CooccurrenceAlgorithm.scala`, modify `itemScores` in the `predict` method.

```scala
class CooccurrenceAlgorithm(val ap: CooccurrenceAlgorithmParams)
  extends P2LAlgorithm[PreparedData, CooccurrenceModel, Query, PredictedResult] {
  ...

  def predict(model: CooccurrenceModel, query: Query): PredictedResult = {
    ...

    val itemScores = counts
      .filter { case (i, v) =>
        isCandidateItem(
          i = i,
          items = model.items,
          categories = query.categories,
          queryList = queryList,
          whiteList = whiteList,
          blackList = blackList
        )
      }
      .sortBy(_._2)(Ordering.Int.reverse)
      .take(query.num)
      .map { case (index, count) =>
        ItemScore(
          itemID = model.itemIntStringMap(index),  // MODIFIED
          title = model.items(index).title,  // ADDED
          imageURLs = model.items(index).imageURLs,  // ADDED
          score = count
        )
      }
    ...
  }
}
```

**Step 4:** Build the engine. Simply run,

```Bash
$ cd tapster-similar-product 
$ pio build
```

If you modified the code correctly, you should see the message that your engine is ready for training.

**_Note:_** The final code for the engine can be found at [this repository](https://github.com/minhtule/Tapster-iOS-Similar-Product-Engine). You can check the step-by-step changes in its commit history.

## Setting up the iOS app

To install dependencies for the iOS project, make sure you have installed [CocoaPods](https://guides.cocoapods.org/using/getting-started.html). Then at the Xcode project root directory, run

```bash
$ pod install
```

Open the project workspace `Tapster iOS Demo.xcworkspace` (created by CocoaPods) and you should be able to run the app by selecting `Start Reading` in the home screen. You can swipe right or left to like or dislike a comic just like in Tinder! However, there is no recommendation for now. New comics are randomly generated.

## Import data

Before we can do any prediction, we need some data! First, we need to start the event server.

```bash
# Switch back to the engine directory
$ cd ../tapster-similar-product
$ pio eventserver
```

The import process has been included in  `DataViewController.swift`. However, you need to add the app ID of the PredictionIO app that you created earlier so that the `eventClient` knows where to send the data to.

```swift
let eventClient = EventClient(accessKey: "<Your App's access key here>")
```

The import process consists of 3 steps:

* Send comic data using the `setItem` method.
* Send user data using the `setUser` method.
* Send likes data using the `recordAction` method.

Now, run the application again. In the home screen, tap on `Import Data` and then `Run Import` button. The whole import will take a while. Check Xcode's debug console to see the progress.

## Train and deploy the engine

First, you need to switch back to the engine root directory if you're currently at the iOS app directory. Then to train and deploy the engine, run

```bash
# At the engine directory
$ pio train
$ pio deploy
```

In your production server, you might want to set up a cron job to retrain the engine with the latest dataset.

## Connect the iOS app with PredictionIO

Here is the exciting part: adding the recommendation to your iOS app!

In `ComicViewController.swift`, `ComicViewController` is the controller that is responsible for managing and displaying the comics. We will add the recommendation logic there.

* Import the PredictionIO Swift SDK at the top of the `ComicViewController.swift` file.

```swift
import PredictionIO
```

* Create a `engineClient` as a stored property of `ComicViewController`.

```swift
...
let engineClient = EngineClient()
var directionComicDeleted: Direction = .right
...
```

* Delete the following code that randomly selects a comic in the `updateComics` method.

```swift
// Add a random new comic
let comic = randomizeComics(numberOfComics: 1)[0]
addAndAnimateNewComic(comic)
```

* Then replace by the following code at the same place at the end of the `updateComics` method.

```swift
// We can't query PredictionIO with no likes,
// so we just add a new random comic
if likedComicIDs.isEmpty {
    let comic = randomizeComics(numberOfComics: 1)[0]
    addAndAnimateNewComic(comic)
    
    return
}

let query: [String: Any] = [
    "num": 1,
    "items": likedComicIDs,
    "blackList": displayedComicIDs
]

engineClient.sendQuery(query, responseType: RecommendationResponse.self) { response, error in
    guard let response = response, response.comics.count > 0 else { return }

    self.addAndAnimateNewComic(response.comics[0])
}
```

That's it! Rerun the app, swipe right on a comic you like and you will notice that similar comics will be displayed.

## Conclusion

Congratulation! I hope the tutorial has helped you understand how to integrate a Prediction IO engine to an iOS application via the PredictionIO Swift SDK. You should now be able to utilize the power of machine learning and make your mobile app more interesting.
