# interrogate.js
This is a small javascript library that relies on some rather large libraries to
interrogate javascript code. This is useful for evaluating that certain code is correct
where testing the result of the javascript isn't reliable. For example you can test to
make sure a certain variable value is set, regardless of the variable name, etc.

## Usage

```javascript
var i = new Interrogate;
var code = "while(true){console.log('boom!')}";
i.safeEval(code);

// This will console log a 'InfiniteWhileStatementLoopError' and not block the browser
```

another example

```javascript
var i = new Interrogate;
var code = "var b = 'hello everyone!';"+
"var a = 123456;"+
"c = {one: 1, two: 2};"+
"var d = function(){"+
"  return 'hello';"+
"};"+
"arr = [1,2,3,4,5];"+
"for(i in arr){"+
"  console.log(b + ' - ' + arr[i]);"+
"};"

console.log(i.getVars(code))

Object {
  a: 123456
  arr: Array[5]
  b: "hello everyone!"
  c: Object
  d: function () {}
}
```

## Functions

This is a work in progress, more functionality is added when they come up

* safeEval(code, callback, options) - This will eval code and protect against infinite loops. The default behavior of this function will console log the name of the error (ex. InfiniteWhileStatementLoopError). You can optionally pass in a callback when will receive the error so you can do something to it if it happen to be triggered. There is currently only 1 option, `tolerance` can be set to tell the function how long to let a loop run before it's considered infinite, this defaults to 100.

* getVars(code) - This method will pull all variables and their values from a chunk of code. Be aware, an eval is performed during this action.