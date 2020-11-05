-module(h20_game).

-behaviour(gen_statem).
-export([callback_mode/0, init/1]).
-export([buying/3, computing/3, visiting/3]).
-export([start_link/1, buy/3, next_step/1, state/1, visit/3]).

-include("h20.hrl").

%% External exports
start_link(Name) ->
  gen_statem:start_link({local, Name}, ?MODULE, Name, []).


buy(Name, Accessory, Child) ->
  gen_statem:call(Name, {buy, Accessory, Child}).


next_step(Name) ->
  gen_statem:call(Name, next_step).


state(Name) ->
  sys:get_state(Name).


visit(Name, Child, House) ->
  gen_statem:call(Name, {visit, Child, House}).

%% gen_statem common exports
callback_mode() ->
  [state_functions].


init(Name) ->
  {ok, buying, init_round(1, #game{name = Name})}.

%% gen_statem states
buying({call, From}, {buy, AccessoryName, ChildName}, Game) when is_binary(AccessoryName) andalso is_binary(ChildName) ->
  try
    {value, Child} = lists:keysearch(ChildName, #child.name, Game#game.children),
    {value, Store} = lists:search(fun(S) -> S#store.visited =:= false end, Game#game.stores),
    {value, Accessory} = lists:keysearch(AccessoryName, #accessory.name, Store#store.accessories),
    buying({call, From}, {buy, Accessory, Child}, Game)
  catch _:_ ->
          {keep_state_and_data, {reply, From, ko}}
  end;
buying({call, From}, {buy, #accessory{price = Price}, _}, #game{candies = Candies}) when Price > Candies ->
  {keep_state_and_data, {reply, From, ko}};
buying({call, From}, {buy, Accessory, Child}, #game{stores = Stores, children = Children} = Game) ->
  try
    {value, Store} = lists:search(fun(S) -> S#store.visited =:= false end, Stores),
    true = lists:member(Accessory, Store#store.accessories) andalso lists:member(Child, Children),
    NewCandies = Game#game.candies - Accessory#accessory.price, 
    NewChild = Child#child{accessories = [Accessory|Child#child.accessories]},
    NewChildren = lists:keyreplace(Child#child.name, #child.name, Children, NewChild),
    NewStore = Store#store{accessories = lists:delete(Accessory, Store#store.accessories)},
    NewStores = lists:keyreplace(Store#store.name, #store.name, Stores, NewStore),
    NewGame = Game#game{candies = NewCandies, children = NewChildren, stores = NewStores},
    case NewStore#store.accessories of
      [] -> buying({call, From}, next_step, NewGame);
      _ -> {keep_state, NewGame, {reply, From, ok}}
    end
  catch _:_ ->
          {keep_state_and_data, {reply, From, ko}}
  end;
buying({call, From}, next_step, #game{stores = Stores} = Game) ->
  case lists:search(fun(S) -> S#store.visited =:= false end, Stores) of
    {value, Store} ->
      NewStore = Store#store{visited = true},
      NewStores = lists:keyreplace(Store#store.name, #store.name, Stores, NewStore),
      NewGame = Game#game{stores = NewStores},
      case lists:any(fun(S) -> S#store.visited =:= false end, NewStores) of
        true -> {keep_state, NewGame, {reply, From, ok}};
        false -> {next_state, visiting, NewGame, {reply, From, ok}}
      end;
    false ->
      {keep_state_and_data, {reply, From, ko}}
  end;
buying({call, From}, _, _) ->
  {keep_state_and_data, {reply, From, ko}}.


computing({call, From}, next_step, #game{name = Name, candies = Candies, round = 3}) ->
  h20_scores:save_score(atom_to_binary(Name, utf8), Candies),
  {stop_and_reply, normal, {reply, From, finished}};
computing({call, From}, next_step, Game) ->
  {next_state, buying, init_round(Game#game.round + 1, Game), {reply, From, ok}};
computing({call, From}, _, _) ->
  {keep_state_and_data, {reply, From, ko}}.


visiting({call, From}, {visit, ChildName, HouseName}, Game) when is_binary(ChildName) andalso is_binary(HouseName) ->
  try
    {value, Child} = lists:keysearch(ChildName, #child.name, Game#game.children),
    {value, House} = lists:keysearch(HouseName, #house.name, Game#game.houses),
    visiting({call, From}, {visit, Child, House}, Game)
  catch _:_ ->
          {keep_state_and_data, {reply, From, ko}}
  end;
visiting({call, From}, {visit, Child, House},
         #game{candies = Candies, children = Children, houses = Houses} = Game) ->
  IsHouseEmpty = House#house.child =:= undefined,
  case IsHouseEmpty andalso lists:member(Child, Children) andalso lists:member(House, Houses) of
    true ->
      {ChildQ, ChildT} = lists:foldl(fun(Accessory, {Q,T}) ->
                                         {Q + Accessory#accessory.quality,
                                          T + Accessory#accessory.trick}
                                     end, {0,0}, Child#child.accessories),
      CandiesWon = case ChildQ >= House#house.req_quality andalso ChildT >= House#house.req_trick of
                     true -> House#house.candies;
                     false -> 0
                   end,
      NewCandies = Candies + CandiesWon,
      NewChild = Child#child{visited = true, candies = CandiesWon}, 
      NewChildren = lists:keyreplace(Child#child.name, #child.name, Children, NewChild),
      NewHouse = House#house{child = NewChild},
      NewHouses = lists:keyreplace(House#house.name, #house.name, Houses, NewHouse),
      NewGame = Game#game{candies = NewCandies,
                          children = NewChildren,
                          houses = NewHouses},
      case lists:any(fun(H) -> H#house.child =:= undefined end, NewHouses) of
        true ->  {keep_state, NewGame, {reply, From, ok}};
        false -> {next_state, computing, NewGame, {reply, From, ok}}
      end;
    false ->
      {keep_state_and_data, {reply, From, ko}}
  end;
visiting({call, From}, _, _) ->
  {keep_state_and_data, {reply, From, ko}}.


%% Internal functions
init_accessory(Name) ->
  Quality = rand:uniform(10),
  Trick = rand:uniform(10),
  Price = (Quality + Trick + rand:uniform(5)) div 2,
  #accessory{name = Name,
             quality = Quality,
             trick = Trick,
             price = Price}.


init_children(Round) ->
  {ok, EnvChildren} = application:get_env(h20, children),
  Names = proplists:get_value(Round, EnvChildren),
  [#child{name = Name} || Name <- Names].


init_house(Name) ->
  Quality = 10 + rand:uniform(10),
  Trick = 10 + rand:uniform(10),
  Candies = Quality + Trick + rand:uniform(10),
  #house{name = Name,
         req_quality = Quality,
         req_trick = Trick,
         candies = Candies}.


init_houses(Round) ->
  {ok, EnvHouses} = application:get_env(h20, houses),
  Names = proplists:get_value(Round, EnvHouses),
  [init_house(Name) || Name <- Names].


init_round(Round, Game) ->
  Game#game{round = Round,
            children = init_children(Round),
            houses = init_houses(Round),
            stores = init_stores(Round)}.


init_store({Name, AccessoryNames}) ->
  #store{name = Name, accessories = [init_accessory(A) || A <- AccessoryNames]}.


init_stores(Round) ->
  {ok, EnvStores} = application:get_env(h20, stores),
  StoresData = proplists:get_value(Round, EnvStores),
  [init_store(StoreData) || StoreData <- StoresData].

