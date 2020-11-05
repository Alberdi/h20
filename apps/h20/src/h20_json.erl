-module(h20_json).

-export([decode_game_action/1, encode_game_state/1, encode_scores/1]).

-include("h20.hrl").

%% External exports
decode_game_action(Body) ->
  jsone:decode(Body).


encode_game_state({State, Game}) ->
  {GameProplist} = zip_record(record_info(game), Game),
  jsone:encode({[{state, State} | GameProplist]}, [native_utf8]).


encode_scores(Scores) ->
  jsone:encode([[{name, N}, {score, S}, {time, T}] || {N,S,T} <- Scores]).

%% Internal functions
record_info(accessories) ->
  [record_info(accessory)];
record_info(accessory) ->
  record_info(fields, accessory);
record_info(children) ->
  [record_info(child)];
record_info(child) ->
  record_info(fields, child);
record_info(game) ->
  record_info(fields, game);
record_info(houses) ->
  [record_info(house)];
record_info(house) ->
  record_info(fields, house);
record_info(stores) ->
  [record_info(store)];
record_info(store) ->
  record_info(fields, store);
record_info(_) ->
  undefined.


zip([], []) ->
  [];
zip([_|T], [undefined|T2]) ->
  zip(T, T2);
zip([H|T], [H2|T2]) ->
  case record_info(H) of
    undefined -> [{H, H2} | zip(T, T2)];
    [RecordInfo] -> [zip_record_list(RecordInfo, H, H2) | zip(T, T2)];
    RecordInfo -> [{H, zip_record(RecordInfo, H2)} | zip(T, T2)]
  end.


zip_record(RecordInfo, Value) ->
  {zip(RecordInfo, tl(tuple_to_list(Value)))}.


zip_record_list(RecordInfo, Name, List) ->
  {Name, [zip(RecordInfo, tl(tuple_to_list(V))) || V <- List]}.
