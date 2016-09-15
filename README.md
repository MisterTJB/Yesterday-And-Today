# Yesterday and Today

## README

### Overview

Yesterday and Today is an app that aids in creating (very basic!) 'past and present' photographs (e.g. [/r/pastandpresentpics](https://www.reddit.com/r/PastAndPresentPics/)). The user is presented with a split screen, wherein the top half contains a 'past' image, and the bottom half shows the input to the camera, enabling them to direct the 'present' scene such that it matches the pose, perspective, etc. of the past image.

Users are able to source an image from their photo library, or find a nearby photo on Flickr. (To clue the user in to how to progress, the relevant buttons are animated.)

Selecting a 'past' photo from the user's library is handled by a UIImagePicker, and thus replicates the typical iOS user experience for selecting one's own content.

If a user chooses to search Flickr, they are presented with a view controller to manage the search process. Here, they are able to use a UIPicker to narrow the date range of their search, and a UISlider to limit the radius of the search. Results are shown in a collection view, and the map is updated with a pin to show the location of a given image on the map so that they can hunt down the location at which the image was taken.

![Search Flickr for nearby images](/Images/seach_flickr.PNG)

When a user is satisfied with their choice of image, they return to the initial view. Now the camera shutter button appears and they can take a photo. If they are satisfied with their photo, they press the check button and are taken to their library; if not, they can retake the photo.

![Accepting or rejecting an image](/Images/accept_reject.PNG)

The user transitions to their library whenever they save a captured image, or when they press the library button (the frame with a heart, which appears whenever they are not required to evaluate a captured image). The library view displays a grid of 'past and present' photos that the user can scroll through, ordered from most recent to least recent.

![The library view](/Images/library.PNG)

Tapping on an image displays that image in fullscreen, with options to delete the image, share it, or return to the library.

![View/Share/Delete view](/Images/delete_share_view_photo.PNG)

### Building

The app can be built by cloning this GitHub repository and opening `Yesterday and Today.xcodeworkspace`, then running it as per usual via the Xcode `Run` command.

Naturally, the app must be run on a device with a rear-facing camera (though it will function in the simulator, which will only render a black camera 'input').

### Suggested Walkthrough

1. Note the wobbling buttons -- one (the top one) will take you to the photo library on your device, the other (the one with the Flickr logo) will take you to the Flickr search view
2. Try loading a photo from your device -- hit the top wobbly button, choose an image, and note that it appears in the top half of the screen
3. The shutter button appeared! Point at something and take a photo...
4. Now reject that photo by hitting the X button and try again
5. This time, press the tick button and segue to the library view -- your past/present photo awaits you
6. Tap that image to view it in fullscreen, share it, or delete it -- for now, hit Done
7. Now go back to the very first screen and hit the Flickr button
8. Choose a reasonable date range (pretty sure there won't be any photos near your from 1825, but Flickr allows it), and a suitable radius, then press search
9. Some images should load (or you may be warned that there were no results, or you might be alerted to the fact that your network connection was unavailable, depending on the circumstances). Look through the images and note that a pin appears on the map to show you the approximate location at which a given image was taken
10. Choose a Flickr result by tapping on the image; you will segue back to the main screen
11. Create a few more images
12. Go in to the library view and tap an image to open it in full screen
13. Now flick left and right to navigate between images; try and delete one; or try to share one
14. That's all folks!

## Rubric Notes

The following section draws attention to implementation aspects that are relevant to the rubric but may be non-obvious

### README file

_The app contains a README that fully describes the intended user experience. After reading the document, a user can easily use the app._ / _The README provides all necessary information to enable the reviewer to build, run, and access the app._

You're reading it!

### User Interface

_The app contains multiple pages of interface in a navigation controller or tab controller, or a single view controller with a view that shows and hides significant new content._

Yes! The initial view and the library form a navigation stack; all other views are presented modally by the relevant view controller

_The user interface includes more than one type of control._

Yes! Aside from the usual UIButtons, there is a UIPicker and a UISlider. (In earlier versions there were UISegmentedButtons, UISwitches, etc. but these impeded the user experience)

Additionally, some UIButtons are animated.

### Networking

_The app includes data from a networked source._

Yes! Data is downloaded from Flickr


_The networking code is encapsulated in its own classes._

Yes! All of the networking code is encapsulated in FlickrDownloadManager.

_The app clearly indicates network activity, displaying activity indicators and/or progress bars when appropriate._

Yes! Activity is displayed in a handful of places. During the initial fetch from Flickr, this is indicated with a UILabel; when individual images are being downloaded, their cells in the collection view contain a UIActivityIndicator.

_The app displays an alert view if the network connection fails._

Yes! If the network connection fails prior to the hitting 'search', a alert view will tell the user to check their network connection and try again. If the network connection fails while images are being downloaded, an alert will tell the user that some of the images couldn't be downloaded and that they might like to search again.

### Persistent State

_The app has a persistent state that is stored using Core Data or a service with local persistence capabilities (e.g. Firebase or Realm)._

Yes! Both Flickr results (with their dates, coordinates, image data, etc.) and the images that a user creates are persisted using Realm.

Flickr results are persisted between invocations so that a user can continue to access them should they lose their network connection.

Also, search parameters are stored in NSUserDefaults.

### App Functionality

_The app functions as described in the README, without crashes or other runtime errors_

I hope so!
