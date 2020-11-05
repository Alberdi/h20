-module(h20_scores).
-export([list_scores/0, save_score/2]).

-define(SCORE_FILE, "scores.txt").


list_scores() ->
  {ok, RawScores} = file:read_file(?SCORE_FILE),
  Scores = binary:split(RawScores, <<"\n">>, [global, trim]),
  ScoreList = [list_to_tuple(binary:split(S, <<",">>, [global])) || S <- Scores],
  lists:sort(fun({N1,S1,T1},{N2,S2,T2}) -> {S1,T2,N2} > {S2,T1,N1} end, ScoreList).


save_score(Name, Score) ->
  BinScore = integer_to_binary(Score),
  BinTime = integer_to_binary(os:system_time()),
  file:write_file(?SCORE_FILE, <<Name/binary, ",", BinScore/binary, ",", BinTime/binary, "\n">>, [append]).
