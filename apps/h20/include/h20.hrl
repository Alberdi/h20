-record(accessory, {name :: binary(),
                    quality :: non_neg_integer(),
                    trick :: non_neg_integer(),
                    price :: non_neg_integer()}).


-record(child, {name :: binary(),
                accessories = [] :: [#accessory{}],
                candies = 0 :: non_neg_integer(),
                visited = false :: boolean()}).


-record(house, {name :: binary(),
                req_quality :: non_neg_integer(),
                req_trick :: non_neg_integer(),
                candies :: non_neg_integer(),
                child :: undefined | #child{}}).


-record(store, {name :: binary(),
                accessories = [] :: [#accessory{}],
                visited = false :: boolean()}).


-record(game, {name :: atom(),
               candies = 100 :: non_neg_integer(),
               round = 1 :: pos_integer(),
               children = [] :: [#child{}],
               houses = [] :: [#house{}],
               stores = [] :: [#store{}]
              }).

