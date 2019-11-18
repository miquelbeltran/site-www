---
title: "Asynchronous programming with Streams"
description: Learn about and practice using streams in DartPad!
js: [{defer: true, url: https://dartpad.dev/experimental/inject_embed.dart.js}]
---

<style>
        .dartpad-embed > * {
            width: 100%;
        }

        iframe {
            border-width: 0;
            width: 100%;
            height: 600px;
            margin-bottom: 40px;
            margin-top: 10px;
        }
</style>

This codelab teaches you how to do asynchronous programming using streams,
including capturing, transforming and emitting events in an asynchronous way.
Using the embedded DartPad editors, you can test your
knowledge by running example code and completing exercises.

To get the most out of this codelab, you should have the following:
 
* Knowledge of [basic Dart syntax](/samples).
* Knowledge about [iterables][iterable class].
* Knowledge about [asynchronous programing with async-await](/codelabs/async-await).

This codelab covers the following material:

* How to receive stream events.
* How to filter and transform stream events.
* How to handle errors with streams.
* How to create your own streams.

Estimated time to complete this codelab: 60 minutes.

{{site.alert.note}}
  This page uses embedded DartPads to display examples and exercises.
  {% include dartpads-embedded-troubleshooting.md %}
{{site.alert.end}}

## Why do you need streams

Asynchronous operations let your program complete work 
while waiting for another operation to finish. 
Common asynchronous operations include fetching data over the network
or writing to a database.

In Dart, these operations are represented by the [Future][future class]
class, which will eventually return a single result in an asynchronous way.

While futures represent a single operation, streams represent a
sequence of asynchronous events.

Common use cases for streams are:

* Listening to updates from a database.
* Reading sensor data.
* [Reactive Programming](https://pub.dev/packages/rxdart).
* Event-based business logic like the 
[BLoC design pattern](https://pub.dev/packages/flutter_bloc).

## What is a stream?

A stream is a sequence of asynchronous data events.

Each event can be a data event, also know as element of the stream, or an error event,
which is a notification that something has failed. When all events have been emitted, 
a completion event notifies all listeners that that
the sequence is finished.

Streams can emit multiple, one or even no event before completion. And as well,
streams can remain open, continuously emitting events without end, for
example when reading sensor data. 

The following code creates a stream that emits a single value:

{% prettify dart %}
  var stream = Stream.value(42);
{% endprettify %}

While the following code creates an empty stream that just ends:

{% prettify dart %}
  var stream = Stream.empty();
{% endprettify %}

Streams have a lot of similarities with [iterables][iterable class]:

Streams and iterables contain a sequence of elements that can be accessed in an iterable way.
As well, they share some methods, like `take`, `where` or `map`.
Iterables can be converted to streams too:

{% prettify dart %}
  var stream = Stream.fromIterable([1, 2, 3]);
{% endprettify %}

However, iterables don't work asynchronously, which is where streams help.

### Single subscription streams

There are two kinds of streams. Single subscription streams and broadcast streams.

Single subscription streams are the most commonly used, they start emitting
values once they get a subscriber and they stop when the subscription is 
canceled. Single subscription streams are commonly used for network or other types
of I/O operations.

Listening twice to a single subscription stream is not allowed, and it does
not matter if the original stream has finished or not.

### Broadcast streams

Broadcast streams support multiple listeners who can subscribe and unsubscribe at will.

Broadcast streams emit events continuously, without considering if there's an active
subscription or not.

Common use cases for broadcast streams are reading sensor data or continuously 
getting updates from a database.

### Example: Single and broadcast streams

You can use the method `isBroadcast` to check if a stream is a single subscription stream
or a broadcast stream. 

Run this example to check if the following streams are broadcast or not.
Which ones do you think that will be broadcast streams?

```run-dartpad:theme-light:mode-dart:run-false:split-50:height-400px
import 'dart:async';

Stream<int> countStream(int to) async* {
  for (int i = 1; i <= to; i++) {
    yield i;
  }
}

void main() {
  var streamController = StreamController.broadcast();
  var fromIterable = Stream.fromIterable([1, 2, 3]);
  var emptyStream = Stream.empty();
  var yieldStream = countStream(10);

  print('StreamController.broadcast is broadcast: ${streamController.stream.isBroadcast}');
  print('Stream.fromIterable is broadcast: ${fromIterable.isBroadcast}');
  print('Stream.empty is broadcast: ${emptyStream.isBroadcast}');
  print('Yield Stream is broadcast: ${yieldStream.isBroadcast}');
}
```

In this example, both the stream created with `StreamController.broadcast` and the one
created with `Stream.empty` are broadcast streams.

The `Stream.empty` will do nothing except to send a done event once it is subscribed.

`StreamController.broadcast` creates a [StreamController][streamcontroller class] that
behaves like a broadcast stream. When a new event is added to this controller, the
stream emits it immediately without considering if there's any subscription or not.

Both `Stream.fromIterable` and the custom stream created in `countStream` are
single subscription streams, meaning that they cannot have a second subscription.

{{site.alert.secondary}}
  **Key terms:**
* **Stream**: A sequence of events that is emitted asynchronously.
* **Subscription**: The action of listening to events emitted from a stream.
* **Single subscription stream**: A stream that can only be subscribed once.
* **Broadcast stream**: A stream that can be subscribed multiple times.
{{site.alert.end}}

## Receiving stream events

You can access the elements of a stream in different ways.

The most common are the `async for` and the `listen()` method.

### Example: listen method

The `listen()` method allows you to start listening on a stream.

This method returns a [StreamSubscription][streamsubscription class] 
that represents the subscription.

Run the following example to see `listen()` in action. What do you think the output
will be?

```run-dartpad:theme-light:mode-dart:run-false:split-50:height-200px
import 'dart:async';

void main() {
  var stream = Stream.fromIterable([1, 2, 3]);
  stream.listen((event) => print(event));
}
```

As you saw in the example, the `listen()` method was called from a non-asynchronous
`main()` method.

When a new event is received, the function callback `onData` will be called.

{% prettify dart %}
  var subscription = stream.listen((event) {
    // onData
    print(event);
  })
{% endprettify %}

In case an error is emitted, the function callback `onError` is going to be
called. However, if you didn't provide it, a new exception will be thrown.
You will learn more about error handling later.

With the `StreamSubscription`, you can pause the stream or you can
cancel it if you don't need it anymore.

{{site.alert.note}}
  When using streams, is important to cancel all stream subscriptions
  when you are done with them. If not, they will continue to emit values.
{{site.alert.end}}

### Example: async for loop

Similarly to the `Iterable`, you can use a `for loop` to iterate over
the elements of a stream.

The following example shows how to use an asynchronous `for loop`, also know as `async for`,
to iterate over the elements of a stream.
Before you run the example, do you notice any important differences with `listen()`?

```run-dartpad:theme-light:mode-dart:run-false:split-50:height-200px
import 'dart:async';

void main() async {
  var stream = Stream.fromIterable([1, 2, 3]);
  await for (var value in stream) {
    print(value);
  }
}
```

As you may have noticed, `async for` needs to be called inside `async` methods.

### Exercise: Listening to events

The following exercise is a failing unit test that contains partially
completed code snippets. Your task is to complete the exercise by 
writing code to make the tests pass. You don’t need to implement main().

An empty method `listenToStream` is provided. 
This method passes a stream of type `String` as parameter.
You need to implement this method.

Also, the method `processValue` is provided. It is a dummy method that
processes events.

|------------------+--------------------------------+-------------|
| Function         | Type signature                 | Description |
|------------------|--------------------------------|-------------|
| processValue     | `void processValue(String)`    | Processes the input event |
{:.table .table-striped}

Your goal is:

* **Implement `listenToStream`**
  * Add code to listen to events from the stream.
  * Note: Use the `listen()` method.
* Call to the method `processValue` with the received event inside `listen()`.

```run-dartpad:theme-dark:mode-dart:run-false:split-50:height-200px
{$ begin main.dart $}
import 'dart:async';

void listenToStream(Stream<String> stream) {
  // implement this method
}
{$ end main.dart $}

{$ begin solution.dart $}
void listenToStream(Stream<String> stream) {
  stream.listen((event) => processValue(event));
}
{$ end solution.dart $}

{$ begin test.dart $}
var processWasCalled = false;

void processValue(String value) {
  print(value);
  processWasCalled = value == "event";
}

void main() {
  // ignore: close_sinks
  final controller = StreamController<String>(sync: true);
  final stream = controller.stream;

  listenToStream(stream);

  // Check if student used `listen`
  if (!controller.hasListener) {
    _result(false, ['Something went wrong! Stream has no listeners. Did you call to `stream.listen()`?']);
    return;
  }

  controller.add("event");

  // Check if student called to processValue inside listen
  if (processWasCalled) {
    _result(true);
  } else {
    _result(false, ['Something whent wrong! `processValue()` was not called when emitting a value']);
  }
}
{$ end test.dart $}
```

{{site.alert.secondary}}
  **Key terms:**
* **Cancelling a subscription**: Closing the subscription to stop listening to events.
* **onData**: Callback of `listen()` that will be called when a new data event is emitted.
* **onError**: Callback of `listen()` that will be called when a new error event is emitted.
{{site.alert.end}}


## Error handling

As streams emit events until they are completed, they can also emit errors.

The following code creates a stream that emits a single error before ending:

{% prettify dart %}
  var stream = Stream.error(myError);
{% endprettify %}

Generally, errors will interrupt the stream and complete it, but that's not
the case for all streams.

Unhandled stream errors can crash your code, and it is important that you
handle them.

The following code shows how to handle errors when subscribing with the `listen()` method:

{% prettify dart %}
  var subscription = stream.listen((event) {
    print('Got event $event');
  }, onError: (error) {
    print('Got error $error'); 
  });
{% endprettify %}

When using `async for`, you have to wrap the `async for` with a `try catch`:

{% prettify dart %}
  try {
    await for (var event in stream) {
      print('Got event $event');
    }
  } catch (error) {
    print('Got error $error');
  }
{% endprettify %}

### Example: Handling errors

Run the following example to see how error handling happens in both cases.

```run-dartpad:theme-light:mode-dart:run-false:split-50:height-400px
import 'dart:async';

void main() async {
  var stream = Stream.error('Error One!');
  stream.listen((event) {
    print('Got event $event');
  }, onError: (error) {
    print('Got error $error'); 
  });

  stream = Stream.error('Error Two!');
  try {
    await for (var event in stream) {
      print('Got event $event');
    }
  } catch (error) {
    print('Got error $error'); 
  }
}
```

What do you think that will happen if you remove the `onError` parameter from `listen()`?
And what do you think that will happen if you remove the `try catch`?
Modify the example and run it again to check it out.

### Exercise: Practice handling errors

The following exercise provides practice handling errors with streams,
using the approach described in the previous section. 

The method `streamWithError` is subscribed to a stream of `String`,
but the `onError` parameter is missing.

Complete the following exercise by adding the `onError` parameter
to the `listen()` method.

```run-dartpad:theme-dark:mode-dart:run-false:split-50:height-200px
{$ begin main.dart $}
import 'dart:async';

StreamSubscription streamWithError(Stream<String> stream) {
  return stream.listen((_) {} /* finish this method */);
}
{$ end main.dart $}

{$ begin solution.dart $}
StreamSubscription streamWithError(Stream<String> stream) {
  return stream.listen((_) {}, onError: (error) {});
}
{$ end solution.dart $}

{$ begin test.dart $}
void main() async {
  var hadError = false;
  
  // catch unhandled onError
  runZoned(() {
    // ignore: close_sinks
    final streamController = StreamController<String>(sync: true);
    // ignore: cancel_subscriptions
    final subscription = streamWithError(streamController.stream);
    if (subscription == null) {
      _result(
          false, ['Something went wrong! The stream subscription is missing.']);
      hadError = true;
      return;
    }

    streamController.addError("ERROR!");
  }, onError: (e, stackTrace) {
    _result(false,
        ['Something went wrong! Looks like the error was not processed.']);
    hadError = true;
  });

  if (!hadError) {
    _result(true);
  }
}
{$ end test.dart $}
```

## Future operations with streams

Streams and futures share similarities. 
Both allow to do asynchronous operations in Dart and they have
interoperability between each other.

Streams can be converted to futures. And the same is possible the
other way around: futures can be converted to streams.

### Example: Capture the first event

One common use case for converting a stream to a future is
by awaiting the first event that the stream emits.

This is possible with `first`, which returns a future that completes
when an event is received. If the stream never emits an event,
then the future will not complete.

Run this example to see how `first` works.

```run-dartpad:theme-light:mode-dart:run-false:split-50:height-200px
import 'dart:async';

void main() async {
  var stream = Stream.fromIterable([1, 2, 3]);
  var value = await stream.first;
  print(value);
}
```

As `first` returns a future, is it necessary to `await` it to obtain the value,
just like any other kind of future.

{{site.alert.note}}
  Using `first` is equivalent to subscribing to the stream.
  
  In single subscription streams it means that subscribing again won't be possible.
{{site.alert.end}}

### Example: Converting a future to a stream

It is also possible to convert futures to streams, for example
calling the method `asStream()`, which creates a stream containing
a single event with the result of the future.

Run the following example to see `asStream()` in action. 

```run-dartpad:theme-light:mode-dart:run-false:split-50:height-300px
import 'dart:async';

void main() {
  var future = Future.value(42);
  var stream = future.asStream();
  stream.listen((event) {
    print('Got event $event');
  }, onError: (error) {
    print('Got error $error'); 
  });
}
```

The future created by `Future.value()` is converted to a stream that
emits a single value.

If you go back to the example and change `Future.value` to `Future.error`
and run the example again, you will see that the `onError` callback is going to be called when
the stream is subscribed with `listen()`.

### Exercise: Await the first event and convert to stream

The following exercise provides practice converting between futures and
streams, using the approaches described in the previous section. 

#### Part 1: `topUser()`

The function `topUser()` takes a stream of usernames as strings
and returns a string containing the username on the first stream event.
The returning string must have this format: `"Top User is: <username>"`

Add code to the `topUser()` function so that it does the following:
* Returns a future that completes with the following
string: `"Top User is: <username>"`
  * Note: Read the first  of the username stream.
  * Example return value: `"Top User is: tester"`.
* Get the first value as future using the `first` method.

#### Part 2: `usernameAsStream()`

The function `usernameAsStream()` takes a future containing a username
and returns a stream with that username.

Add code to the `usernameAsStream()` function so that it does the following:
* Returns a stream containing the username.
  * Note: Remember how to convert a future into a stream.

```run-dartpad:theme-dark:mode-dart:run-false:split-80:height-400px
{$ begin main.dart $}
Future<String> topUser(Stream<String> stream) async {
  // implement this method
}

Stream<String> usernameAsStream(Future<String> username) {
  // implement this method
}
{$ end main.dart $}

{$ begin solution.dart $}
Future<String> topUser(Stream<String> stream) async {
  var user = await stream.first;
  return 'Top User is: $user';
}

Stream<String> usernameAsStream(Future<String> username) {
  return username.asStream();
}
{$ end solution.dart $}

{$ begin test.dart $}
void main() async {
  try {
    final stream = Stream.fromIterable(['First', 'Second']);
    final value = await topUser(stream);
    if (value != 'Top User is: First') {
      _result(false,
          ['Something went wrong! The result of `topUser` is incorrect.']);
      return;
    }
  } catch (error) {
    _result(false, [
      'Something went wrong! Tried calling `firstEvent` but got exception: $error'
    ]);
    return;
  }

  try {
    final value = await usernameAsStream(Future.value('First')).single;
    if (value != 'First') {
      _result(false, [
        'Something went wrong! The result of `usernameAsStream` is incorrect.'
      ]);
      return;
    }
  } catch (error) {
    _result(false, [
      'Something went wrong! Tried calling `usernameAsStream` but got exception: $error'
    ]);
    return;
  }

  _result(true);
}
{$ end test.dart $}
```

## Stream operations

Streams and iterables have a lot in common. These two classes represent a sequence of
elements that can be filtered or transformed into a different one.

Most methods that exist for `Iterable`, like `take`, also exist for `Stream`.

{% prettify dart %}
  // take with Iterable
  var iterable = [1, 2, 3].take(2);
{% endprettify %}
  
{% prettify dart %}
  // take with Stream
  var stream = Stream.fromIterable([1, 2, 3]).take(2);
{% endprettify %}

This section contains examples for `take`, `where` and `map`, which are
methods that also exist in the `Iterable` class.

### Example: Limit events with take

`take` returns a new stream that will emit up to a fixed amount of events,
or finish, depending on what happens first.

For example, the following stream will emit two values (`1` and `2`):

{% prettify dart %}
  var stream = Stream.fromIterable([1, 2, 3]).take(2);
{% endprettify %}

However, the following stream will only emit one value (`1`):

{% prettify dart %}
  var stream = Stream.fromIterable([1]).take(2);
{% endprettify %}

Run the following example to see `take` in action.

```run-dartpad:theme-light:mode-dart:run-false:split-70:height-250px
import 'dart:async';

void main() {
  var stream = Stream.fromIterable([1, 2, 3, 4]).take(3);
  stream.listen((event) {
    print('Got event $event');
  });
}
```

To demonstrate that `take` will also work then the stream finishes
earlier, change `take(3)` to `take(42)` and run the code again.
Is the result the one you expected?

### Example: Filter events with where

`where` returns a new stream that contains only the elements that
match the given predicate.

For example, the following stream will emit `2` and `4`:

{% prettify dart %}
  var stream = Stream.fromIterable([1, 2, 3, 4]).where((elem) => elem.isEven);
{% endprettify %}

Run the following example to see `where` in action.
Which values do you expect to see?

```run-dartpad:theme-light:mode-dart:run-false:split-70:height-250px
import 'dart:async';

main() {
  var stream = Stream.fromIterable([1, 2, 3, 4]).where((elem) => elem.isEven);
  stream.listen((event) {
    print('Got event $event');
  });
}
```

What will happen if you change `isEven` by something that always evaluates
to false? Replace the line 4 with a `where` predicate that is always false
and run the code again.

{% prettify dart %}
  var stream = Stream.fromIterable([1, 2, 3, 4]).where((_) => false);
{% endprettify %}

As you can see, nothing is printed, because the stream is empty.

### Example: Transform events with map

`map` transforms events of a stream, or in other words, applies
a function over those events.

Similarly to the `map` method in `Iterable`, it can be used to
modify or to return a different object for each one of the
elements.

In the following example, each emitted element is multiplied
by two:

{% prettify dart %}
  var stream = Stream.fromIterable([1, 2, 3]).map((elem) => elem * 2);
{% endprettify %}

Run the following example to see `map` in action.

```run-dartpad:theme-light:mode-dart:run-false:split-70:height-250px
import 'dart:async';

main() {
  var stream = Stream.fromIterable([1, 2, 3, 4]).map((elem) => elem * 2);
  stream.listen((event) {
    print('Got event $event');
  });
}
```

Would it be possible to convert each element from `int` to `String`?
Replace the line 5 with a `map` that applies `toString` to each element.

{% prettify dart %}
  var stream = Stream.fromIterable([1, 2, 3, 4]).map((elem) => elem.toString());
{% endprettify %}

This `map` converts the `Stream<int>` into a `Stream<String>`.
The completion event as well as error events are not transformed by the `map`.

### Exercise: Practice stream operations

The following exercise provides practice with stream operations
using the approaches described in the previous section. 

The exercise provides an empty method `processStream`, which
takes a stream of `String` as input and must return a stream
of `String` as well.

This method needs to perform two tasks:

* Filter out all elements that are shorter than three characters with `where()`.
  * For example, `hi` would be filtered out, but `yes` would pass.
* Convert the resulting `Strings` to uppercase with `map()`.
  * Note: Use `.toUpperCase()`


```run-dartpad:theme-dark:mode-dart:run-false:split-80:height-400px
{$ begin main.dart $}
import 'dart:async';

Stream<String> processStream(Stream<String> stream) {
  // implement this method
}
{$ end main.dart $}

{$ begin solution.dart $}
Stream<String> processStream(Stream<String> stream) {
  return stream
      .where((elem) => elem.length > 2)
      .map((elem) => elem.toUpperCase());
}
{$ end solution.dart $}

{$ begin test.dart $}
void main() async {
  try {
    final stream = Stream.fromIterable(["hi", "no", "YES", "lowercase", ""]);
    final output = processStream(stream);
    final list = await output.toList();
    final expected = ["YES", "LOWERCASE"];
    if (!_listEquals(list, expected)) {
      _result(false, [
        'Something went wrong! The output stream was $list but expected $expected.'
      ]);
      return;
    }
    _result(true);
  } catch (error) {
    _result(false, [
      'Something went wrong! Tried calling `processStream` but got the exception: $error.'
    ]);
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
{$ end test.dart $}
```

## Creating streams

So far you have seen how to use and modify streams in Dart code, in this section
you are going to learn how streams can be created.

There's many different ways to create streams, and the most common are there:

* Create a simple stream with one of the `Stream` constructors.
* Create a stream using an `async*` function generator.
* Create a stream using a `StreamController`.

### Example: Creating a stream from Iterable

The `Stream` class provides different constructors that will create simple
streams. You have already seen them in this codelab, for example `Stream.value()`.

{% prettify dart %}
  var stream = Stream.value(42);
{% endprettify %}

`Stream.value()` creates a new single subscription stream that will emit
a single value when subscribed.

The `Stream` class also provides other useful constructors:

* `Stream.empty()` which creates a stream that only emits the completion event.
* `Stream.error()` which creates a stream that only emits an error.
* `Stream.fromIterable()` which creates a stream that emits the elements of an `Iterable`.
* `Stream.fromFuture()` which creates a stream that emits the value emitted by a `Future`.

The following example contains a generator function named `genInt()`. This function
generates new numbers starting from `0` and it is presented as an `Iterable<int>`.

Run the following example to see how a stream is created from the `genInt()` iterable.
Why `take()` is used here?

```run-dartpad:theme-light:mode-dart:run-false:split-50:height-400px
import 'dart:async';

Iterable<int> genInt() sync* {
  var i = 0;
  while (true) {
    yield i;
    i++;
  }
}

main() {
  var stream = Stream.fromIterable(genInt()).take(3);
  stream.listen((event) {
    print('Got event $event');
  });
}
```

`genInt()` generates numbers without an end, and when used as iterable for
generating a stream, this also generates a continuous stream that does not end.

By calling `take()`, you can force the end the of the stream after a
certain number of events. In this case, `take(3)` limits the stream
to three events before finishing.

### Example: Creating an async generator

The keyword `yield` can be used to lazily produce a sequence of values.

In the previous example, `genInt()` generated a sequence of numbers
starting from 0 as an iterable, and it was converted to a stream
using `Stream.fromIterable()`.

However, the same can be accomplished using `yield` with `async*`.

{% prettify dart %}
  Stream<int> genIntStream() async* {
    var i = 0;
    while (true) { 
      yield i;
      i++;
    }
  }
{% endprettify %}

In this example, `genIntStream()` generates an infinite stream
of numbers starting from `0`.

Because `genIntStream()` is an asynchronous function, other
asynchronous operations can happen inside it, for example,
adding a one second delay to each event or requesting data
from a service.

{% prettify dart %}
Stream<int> genIntStreamDelayed() async* {
  var i = 0;
  while (true) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
    i++;
  }
}
{% endprettify %}

Run the following example to see the `async*` generator in action.

```run-dartpad:theme-light:mode-dart:run-false:split-50:height-400px
import 'dart:async';

Stream<int> genIntStreamDelayed() async* {
  var i = 0;
  while (true) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
    i++;
  }
}

main() {
  var stream = genIntStreamDelayed().take(3);
  stream.listen((event) {
    print('Got event $event');
  });
}
```

When running this example, the three events are received with a delay of a second
between them. Re-run the example again and experiment changing the delay `Duration`
and the value in `take()`.

### Example: Using StreamController

When needing more control over the stream creation, both the `Stream` constructors
and the `async*` generator can be limited in functionality, that's where the 
`StreamController` class can help.

The `StreamController` contains a stream it controls. The `StreamController` allows
sending new events, errors and completion events to this stream.

In the following example, a new `StreamController` is created, the event `42` is
added to the stream and then it is closed.

{% prettify dart %}
  var controller = StreamController<int>();
  controller.add(42);
  controller.close();
  var stream = controller.stream;
{% endprettify %}

Notice that here the event is emitted before the stream has a subscription, which
is not recommended since it can lead to a memory leak if the stream is never
subscribed.

Run this example to see how `StreamController` is used to create a new stream.
Notice how the `add` and the `close` methods are called after the stream
is subscribed.

```run-dartpad:theme-light:mode-dart:run-false:split-50:height-400px
import 'dart:async';

void main() {
  var controller = StreamController<int>();
  
  controller.stream.listen((event) {
    print('Got event $event');
  });

  controller.add(42);
  controller.close();
}
```

What would happen if you remove the `close()` call? In this case, 
although the output will be the same, the subscription will remain open,
and you will see a warning telling you to "Close instances of `dart.core.Sink`".

### Exercise: Creating your own stream

The following exercise provides practice with stream creation 
using the approaches described in the previous section. 

The exercise provides an empty method `temperatureStream`, which
should return a stream of `int` and you will have to implement.

The exercise also provides the method `temperature()` which returns
a temperature reading from a weather station in `int` format.

|------------------+--------------------------------+-------------|
| Function         | Type signature                 | Description |
|------------------|--------------------------------|-------------|
| temperature      | `Future<int> temperature()`    | Reads a temperature value from a weather station, returns it as `int` asynchronously. |
{:.table .table-striped}

Your goal is to create a stream using the `async*` generator:

* Create a stream using the `async*` generator method.
  * Use a infinite loop with `while (true)`.
* Yield values obtained from `temperature()`.
  * Use the `yield` keyword.
  * Use the `await` keyword when calling to `temperature()`.

```run-dartpad:theme-dark:mode-dart:run-false:split-80:height-400px
{$ begin main.dart $}
import 'dart:async';

Stream<int> temperatureStream() async* {
  // implement this method
}
{$ end main.dart $}

{$ begin solution.dart $}
Stream<int> temperatureStream() async* {
  while (true) {
    yield await temperature();
  }
}
{$ end solution.dart $}

{$ begin test.dart $}
final temperatures = [19, 18, 19, 17, 16, 16, 15];
final it = temperatures.iterator;

Future<int> temperature() async {
  it.moveNext();
  return Future.value(it.current);
}

void main() async {
  try {
    final output = await temperatureStream().take(7).toList();
    if (!_listEquals(output, temperatures)) {
      _result(false, [
        'Something went wrong! The `temperatureStream` output is not correct.'
            'Expected $temperatures but got $output.'
      ]);
      return;
    }
    _result(true);
  } catch (error) {
    _result(false, [
      'Something went wrong! Tried calling `processStream` but got the exception: $error.'
    ]);
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
{$ end test.dart $}
```

## Exercise: Putting it all together

It’s time to practice what you’ve learned in one final exercise.

**Part 1** `tempStreamFahrenheit()`

Similar to the exercise in the previous section, create a new stream
using an `async*` generator. This time, the temperatures need to be 
converted to Fahrenheit before being emitted to the stream.

* Create a stream using the `async*` generator method.
  * Use a infinite loop with `while (true)`.
* Obtain temperature values with `tempCelsius()`.
  * Use the `await` keyword when calling to `tempCelsius()`.
* Convert the temperatures to Fahrenheit with `celsiusToFahrenheit()`.
* Yield values obtained.
  * Use the `yield` keyword.
  
**Part 2** `formatTemperature`

The temperature values are provided as `int` and have to be formatted
to `String` adding the unit `°F` at the end. For example: `66 °F`.

* Use `map` to format the stream from `int` to `String`.
  * Add the unit at the end: `°F`.
  * Note: there's a space between the number and `°F`.
  
  
**Part 3** `listenToStream`

The method `listenToStream` is listening to events from the temperature
stream, but currently it is not handling error events.

* Modify the `listenToStream` method so it can handle errors too.
  * You can print the errors calling `print()` or ignore them.

```run-dartpad:theme-dark:mode-dart:run-false:split-80:height-400px
{$ begin main.dart $}
import 'dart:async';

Stream<int> tempStreamFahrenheit() async* {
  // Implement this method
}

Stream<String> formatTemperature(Stream<int> temperature) {
  // Implement this method
}

StreamSubscription listenToStream(Stream<String> temperature) {
  // Fix this method
  return temperature.listen((temp) => print(temp));
}
{$ end main.dart $}

{$ begin solution.dart $}
Stream<int> tempStreamFahrenheit() async* {
  while (true) {
    final temp = await tempCelsius();
    yield celsiusToFahrenheit(temp);
  }
}

Stream<String> formatTemperature(Stream<int> temperature) {
  return temperature.map((temp) => '$temp °F');
}

StreamSubscription listenToStream(Stream<String> temperature) {
  return temperature.listen((temp) => print(temp), onError: (error) => print(error));
}
{$ end solution.dart $}

{$ begin test.dart $}
int celsiusToFahrenheit(int celsius) {
  return ((celsius * 1.8) + 32).round();
}

final tempF = [66, 64, 66, 63, 61, 61];
final tempFS = ['66 °F', '64 °F', '66 °F', '63 °F', '61 °F', '61 °F'];

final temperatures = [19, 18, 19, 17, 16, 16, 15];
var it = temperatures.iterator;

Future<int> tempCelsius() async {
  it.moveNext();
  return Future.value(it.current);
}

void main() async {
  try {
    final output = await tempStreamFahrenheit().take(6).toList();
    if (!_listEquals(output, tempF)) {
      _result(false, [
        'Something went wrong! The `tempStreamFahrenheit` output is not correct.'
            'Expected $tempF but got $output.'
      ]);
      return;
    }
  } catch (error) {
    _result(false, [
      'Something went wrong! Tried calling `tempStreamFahrenheit` but got the exception: $error.'
    ]);
    return;
  }

  try {
    // restart iterator for temperatures
    it = temperatures.iterator;
    final output = await formatTemperature(tempStreamFahrenheit().take(6)).toList();
    if (!_listEquals(output, tempFS)) {
      _result(false, [
        'Something went wrong! The `formatTemperature` output is not correct.'
            'Expected $tempF but got $output.'
      ]);
      return;
    }
  } catch (error) {
    _result(false, [
      'Something went wrong! Tried calling `formatTemperature` but got the exception: $error.'
    ]);
    return;
  }

  var hadError = false;
  runZoned(() {
    // ignore: close_sinks
    final streamController = StreamController<String>(sync: true);
    // ignore: cancel_subscriptions
    final subscription = listenToStream(streamController.stream);
    if (subscription == null) {
      _result(
          false, ['Something went wrong! The stream subscription is missing.']);
      hadError = true;
      return;
    }

    streamController.addError("ERROR!");
  }, onError: (e, stackTrace) {
    _result(false,
        ['Something went wrong! Looks like the error was not processed.']);
    hadError = true;
  });

  if (!hadError) {
    _result(true);
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
{$ end test.dart $}
```

## What's next

Congratulations, you've finished the codelab! If you'd like to learn more, here
are some suggestions for where to go next:

* Play with [DartPad]({{site.dartpad}}).
* Try another [codelab](/codelabs).
* Check the [Stream][stream class] class to learn the methods not covered by this codelab.
* Check the guides [Asynchronous programing: Streams](/tutorials/language/streams)
to learn more about streams.
* Check the guide [Creating streams in Dart](/articles/libraries/creating-streams) 
for more information in detail about creating streams.

[iterable class]: {{site.dart_api}}/stable/dart-core/Iterable-class.html
[stream class]: {{site.dart_api}}/stable/dart-async/Stream-class.html
[streamcontroller class]: {{site.dart_api}}/stable/dart-async/StreamController-class.html
[streamsubscription class]: {{site.dart_api}}/stable/dart-async/StreamSubscription-class.html
[future class]: {{site.dart_api}}/stable/dart-async/Future-class.html



