# Troubleshooting a Test That Keeps Failing

* [Enable verbose mode]()
* [Syntax Error: Unxpected Token]()
* [Can't find my component even though I added testID to its props]()
* [detox build or detox test are failing to run]()
* [Debug view hierarchy]()
* [Compare to a working setup]()
* [Take a look at past issues]()
* [How to open a new issue]()

<br>

### Enable verbose mode

It's a good idea to get as much information as possible about what's going on. We can enable verbose mode during tests by running our tests with:

```
detox test --loglevel verbose
```

<br>

### Syntax Error: Unxpected Token

**Issue:** Running tests immediately throws the following error:

```
beforeEach(async () => {
                   ^
SyntaxError: Unexpected token (
    at Object.exports.runInThisContext (vm.js:76:16)
    at Module._compile (module.js:545:28)
    at loader (/Users/builduser/buildAgent/work/34eee2d16ef6c34b/node_modules/babel-register/lib/node.js:144:5)
    at Object.require.extensions.(anonymous function) [as .js] (/Users/builduser/buildAgent/work/34eee2d16ef6c34b/node_modules/babel-register/lib/node.js:154:7)
    at Module.load (module.js:490:32)
    at tryModuleLoad (module.js:449:12)
    at Function.Module._load (module.js:441:3)
    at Module.require (module.js:500:17)
    at require (internal/module.js:20:19)
    at /Users/builduser/buildAgent/work/34eee2d16ef6c34b/node_modules/mocha/lib/mocha.js:230:27
    at Array.forEach (native)
    at Mocha.loadFiles (/Users/builduser/buildAgent/work/34eee2d16ef6c34b/node_modules/mocha/lib/mocha.js:227:14)
    at Mocha.run (/Users/builduser/buildAgent/work/34eee2d16ef6c34b/node_modules/mocha/lib/mocha.js:495:10)
    at Object.<anonymous> (/Users/builduser/buildAgent/work/34eee2d16ef6c34b/node_modules/mocha/bin/_mocha:460:18)
    at Module._compile (module.js:573:32)
    at Object.Module._extensions..js (module.js:582:10)
    at Module.load (module.js:490:32)
    at tryModuleLoad (module.js:449:12)
    at Function.Module._load (module.js:441:3)
    at Module.runMain (module.js:607:10)
    at run (bootstrap_node.js:382:7)
    at startup (bootstrap_node.js:137:9)
    at bootstrap_node.js:497:3
child_process.js:531
    throw err;
```
**Solution:**

This error means that your version of Node does not support `async-await` syntax. You should do one of the two:

1. Update Node to a version **higher than 7.6.0**, this versions will provide native support for async-await, and will spare the need to babel the test code (**recommended**, as it will save babel setup boilerplate, and make it easier to debug you tests).

2. If you can't use a newer version of Node, you'll need to babel your test code, read more about it [here](https://babeljs.io/)

<br>

### Can't find my component even though I added testID to its props

**Issue:** Detox fails to match a component even though it has a `testID`. Detox will throw the following error:

```
Error: Cannot find UI Element.
Exception with Assertion: {
  "Assertion Criteria" : "assertWithMatcher: matcherForSufficientlyVisible(>=0.750000)",
  "Element Matcher" : "(((respondsToSelector(accessibilityIdentifier) && accessibilityID('Welcome')) && !kindOfClass('RCTScrollView')) || (kindOfClass('UIScrollView') && ((kindOfClass('UIView') || respondsToSelector(accessibilityContainer)) && ancestorThatMatches(((respondsToSelector(accessibilityIdentifier) && accessibilityID('Welcome')) && kindOfClass('RCTScrollView'))))))",
  "Recovery Suggestion" : "Check if element exists in the UI, modify assert criteria, or adjust the matcher"
}

Error Trace: [
  {
    "Description" : "Interaction cannot continue because the desired element was not found.",
    "Domain" : "com.google.earlgrey.ElementInteractionErrorDomain",
    "Code" : "0",
    "File Name" : "GREYElementInteraction.m",
    "Function Name" : "-[GREYElementInteraction matchedElementsWithTimeout:error:]",
    "Line" : "119"
  }
]
```

**Solution:**: React Native only supports the `testID` prop on the native built-in components. If you've created a custom composite component, you will have to support this prop yourself. You should probably propagate the `testID` prop to one of your rendered children (a built-in component):

```jsx
export class MyCompositeComponent extends Component {
  render() {
    return (
      <TouchableOpacity testID={this.props.testID}>
        <View>
          <Text>Something something</Text>
        </View>
      </TouchableOpacity>
    );
  }
}
```

Now, adding `testID` to your composite component should work:

```jsx
render() {
  return <MyCompositeComponent testID='MyUniqueId123' />;
}
```

<br>

### detox build or detox test are failing to run

**Issue:** Trying to run `detox build` or `detox test` throws the following error:

```
Error: Cannot determine which configuration to use. use --configuration to choose one of the following:
                  ios.sim.release,ios.sim.debug
  at Detox.initConfiguration (/Users/rotemm/git/github/detox/detox/src/Detox.js:73:13)
  at Detox.init (/Users/rotemm/git/github/detox/detox/src/Detox.js:49:16)
  at process._tickCallback (internal/process/next_tick.js:103:7)
```

**Solution:** You have configured more than one configuration in your package.json and detox cannot understand which one of them you want to run. The error will print a list of available configurations, choose one by using `--configuration` option.

Run your commands with one of these configrations, for example:

`detox build --configration ios.sim.debug`<br>
`detox test --configration ios.sim.debug`

<br>

### Debug view hierarchy

**Issue:** I added the `testID` prop but I still can't find the view by id in my tests.

**Solution:** You can investigate the app's native view hierarchy, this might shed some light on how the app's view hierarchy is laid out.

Do the following: 

1. Start a debuggable app (not a release build) in your simulator

2. Open Xcode

3. Attach you Xcode you your app's process
<img src="img/attach-to-process.jpg">

4. Press the `Debug View Hierarchy` button
<img src="img/debug-view-hierarchy.jpg">

5. This will open the hierarchy viewer, and will show a breakdown of your app's native view hierarchy. Here you can browse through the views

6. React Native testIDs are manifested as *accessibility indentifiers* in the native view hierarchy 

Let's see an example. We will find the following view in the native hierarchy:

```jsx
<TouchableOpacity onPress={this.onButtonPress.bind(this, 'ID Working')}>
  <Text testID='UniqueId345' style={{color: 'blue', marginBottom: 20}}>ID</Text>
</TouchableOpacity>
```

This is the hierarchy viewer, pointing to the native view just mentioned:

<img src="img/hierarchy-viewer.jpg">

<br>

### Compare to a working setup

If you feel lost, try starting from a working example for sanity.

There are multiple working examples included in this repo, such as [demo-react-native](/examples/demo-react-native).

First, install, build and make sure the tests are indeed passing. If they are, try comparing this setup with what you have.

<br>

### Take a look at past issues

Before opening a new issue, search the [list of issues](https://github.com/wix/detox/issues?utf8=%E2%9C%93&q=is%3Aissue) on GitHub. There's a good chance somebody faced the same problem you are.

<br>

### How to open a new issue

Before opening a new issue, please follow the entire troubleshooting guide and go over past issues.

Include the following information in your issue to increase the chances of resolving it:

1. Versions of all dependencies - iOS version you're working on, simulator model, React Native version, Detox version, etc

2. The verbose log of the test (see above)

3. Source code of your test scenario

4. If possible, try to extract a reproducable example of your issue in a git repo that you can share
