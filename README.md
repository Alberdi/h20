h20
=====
**h20** is a small game about overstuffing kids with costume parts so they can fetch as many candies as possible in Halloween.

Running
-----
The code runs on [`Erlang/OTP 21`](https://www.erlang.org), using [`rebar3`](http://rebar3.org) for building and [`yaws`](http://yaws.hyber.org) to use as webserver. The following steps assume that all these tools are properly installed.

The code can be built by running the following command:

    $ rebar3 compile

After that the server can be started by running:

    $ yaws -c yaws.conf

This will start a HTTP server on port 8000. You can point your browser to http://localhost:8000 and you'll be asked for an user/password, input `laurie` in both fields and start playing! The UI is in Spanish and includes an extensive tutorial.

Hacking
-----
The game was designed to be played by a small number of participants, each with their own user and password; these values can be set in the `yaws.conf` file. In addition, the names of the players must also be hardcoded in the `apps/h20/src/h20_sup.erl` file, in the `Players` variable.

The names of the houses, stores and items can be personalized by editing the `apps/h20/src/h20.app.src` file.

License
-----
All content is under Apache License Version 2.0, except the javascript libraries placed at `www/js`.
