# Dealing With Flakiness in Tests

### 1. We Feel Your Pain

Flakiness is the greatest challenge in E2E. The good news is that detox was designed with this mission in mind: dealing with flakiness head on.

Assume you have a suite of 100 tests and each test is flaky in 0.5% of executions (failing without an actual bug in your app). The total flakiness of your entire suite is about 40% (the exact formula is `1 - (1 - 0.005)^100`). This means that there's 40% chance your suite will fail without an actual bug! This makes your entire suite useless.

### 2. Sources of Flakiness

It's important to identify the various sources of flakiness in detox tests.

* Control of the device / simulator - in order to run your tests, detox must communicate with a simulator and instruct it to install the app, restart it, etc. Simulators don't always behave and controlling them might occasionally fail. <br> Detox's underlying simulator control is [`fbsimctl`](https://github.com/facebook/FBSimulatorControl/tree/master/fbsimctl), it is a tool that supports both basic and advanced simulator and device interaction options, it uses some core simulator features which are not always stable and may need time to "warm up" (booting, shutting down, etc.). Detox is set to have a few retries on any of these actions before failing. It will also print all the `fbsimctl` commands when using verbose log level.


### 3. Get More Data About the Problem

In order to identify the source of flakiness you're suffering from you need more data. If you catch a failing test that should be passing, you need to record as much information as possible in order to investigate.

* Enable verbose mode in detox. This will output a lot of information about what happening during the test.<br>
	1. `fbsimctl` commands
	2. All communication going over the websocket, both from tester and testee

To enable verbose mode run your tests in verbose log mode:

```sh
detox test --loglevel verbose
```