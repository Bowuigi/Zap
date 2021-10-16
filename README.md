# Zap

A lightning fast AUR searcher (might evolve into a helper)

Now rewritten!

Dependencies
------------

+ Lua (anything above 5.1 should work, even LuaJIT, just change the shebang)
+ curl

Installation
------------

Place the `zap` program somewhere on your **PATH**, I reccomend **/usr/local/bin**.

Run `zap`, it should give an error with a bunch of paths, choose one of those paths and put the rxi-json.lua file there, for example, place it on **/usr/share/lua/5.3/**

Usage
-----


```sh
zap search [package]
```

```sh
zap search
```

The second one asks for a package too, but on **stdin** instead of **arg**

There is also a package info command, to use it do

```sh
zap info [package]
```

or, to read from **stdin**

```sh
zap info
```


To provide basic usage commands, use

```sh
zap help
```
