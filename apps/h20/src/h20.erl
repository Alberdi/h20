-module(h20).

-behaviour(application).
-export([start/0, start/2, stop/1]).
-export([game_action/2, game_state/1, list_scores/0]).


%% Application start/stop exports
start() ->
  application:start(h20).


start(_StartType, _StartArgs) ->
  h20_sup:start_link().


stop(_State) ->
  ok.

%% External exports
game_action(Name, Body) ->
  case h20_json:decode_game_action(Body) of
    #{<<"action">> := <<"buy">>, <<"accessory">> := A, <<"child">> := C} ->
      h20_game:buy(Name, A, C);
    #{<<"action">> := <<"next_step">>} ->
      h20_game:next_step(Name);
    #{<<"action">> := <<"visit">>, <<"child">> := C, <<"house">> := H} ->
      h20_game:visit(Name, C, H)
  end.


game_state(Name) ->
  St = h20_game:state(Name),
  h20_json:encode_game_state(St).


list_scores() ->
  Scores = h20_scores:list_scores(),
  h20_json:encode_scores(Scores).
