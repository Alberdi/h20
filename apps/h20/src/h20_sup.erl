-module(h20_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
  supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
  Players = [laurie],
  ChildSpecs = [#{id => Player, start => {h20_game, start_link, [Player]}} || Player <- Players],
  {ok, {#{}, ChildSpecs}}.

