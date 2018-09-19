# FWTNotifiable Sample app

This sample shows how to integrate the `FWTNotifiable` iOS SDK into your app. With it, you can see how you can use the SDK to register, update, unregister and list devices from a  [Notifiable-Rails](https://github.com/FutureWorkshops/Notifiable-Rails) server.

## Requirements

This sample uses [Cocoapods](https://cocoapods.org) and [Cocoapods Keys](https://github.com/orta/cocoapods-keys). If you don't have this installed on your machine, you can install it by running:

```
$ gem install cocopods
$ gem install cocoapods-keys
```

Another option is to run `bundle install` in the root folder of this sample. We provide a `Gemfile` with all the dependencies.

## Setup

Before running the sample, you need to install the required pods and set the proper key values. To do so, just run the command:

```
$ pod install
```

You can install or change the value of the keys by running:

```
$ pod keys set KEY VALUE
```

After the next `pod install` or `pod update` keys will add a new Keys pod to your Pods project, supporting both static libraries and frameworks.

You will need to provide two keys from the `Notfiable-Rails User API`:

```
'FWTAccessID' <- The Access id of the service
'FWTSecretKey' <- Secret key of the service
```

On the sample `AppDelegate.swift` file, replace the URL `http://fw-notifiable-staging2.herokuapp.com/` for the URL of your Notifiable-Rails server.

```swift
self.notifiableManager = FWTNotifiableManager(URL: <<SERVER_URL>>, accessId: keys.fWTAccessID(), andSecretKey: keys.fWTSecretKey())
```