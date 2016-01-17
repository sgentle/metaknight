Metaknight
==========

Metaknight is a little library for meta-trickery with javascript functions. It uses esprima and escodegen to take your existing javascript functions, tear them apart and rebuild them, better and stronger than before<sup>*</sup>

<sub>* use only as directed, functions may not be better or stronger, does not work on arrow functions or functions expecting closure context, this is probably not a very useful library</sub>

Let's get started
```javascript
> var meta = require('metaknight')
```

Have you ever wished a function's arguments were in a different order?
```javascript
> function minus(a, b) { return b - a; }
> minus(1, 3)
2
> var betterminus = meta(minus).reorder([1,0])()
> betterminus(1, 3)
-2
> betterminus.toString() //toString output cleaned up slightly
'function anonymous(b,a) {return b - a;}'
```

Or that some arguments were optional?
```javascript
> function add(a, b) { return a + b; }
> add(5, 7)
12
> var add5 = meta(add).assign({b: 1})()
> add5(10)
15
> add5.toString()
'function anonymous(b) {return 5 + b;}'
```

Or you could partially apply a function like a functional programmer?
```javascript
> var add4 = meta(add).curry(4)()
> var add4 = meta(add)(4) // this is a shortcut
> add4(10)
14
> add4.toString()
'function anonymous(b) {return 5 + b;}'
```


Or that you could rename arguments?
```javascript
> var funadd = meta(add).rename({a: "hello", b: "world"})()
> funadd(1, 2)
-2
> add5.toString()
'function anonymous(hello,world) {return hello + world;}'
```

Or even take two totally separate functions and smoosh them together?
```javascript
> function hello() { console.log("hello"); }
> function world() { console.log("world"); }
> var helloworld = meta(hello).concat(meta(world))()
> helloworld()
hello
world
> helloworld.toString()
'function anonymous(\n) {console.log(\'hello\'); console.log(\'world\')}'
```

Well, whether you wished for these things or not, now you have them!