extends Node
## Shared game state between scenes.
## FallingGame records which items the player must find; the market
## platformer reads this list to know what to place in the supermarket.

# The items the player must find (written by FallingGame).
var required_items: Array[String] = ["Apple", "Milk", "Eggs"]
# Items already picked up in the market platformer.
var picked_up_in_market: Array[String] = []
# Total money (in cents) the player must collect in the market (written by
# FallingGame as the combined price of every product they caught).
var money_target: int = 0

# Full details of everything the player caught in the falling game, one entry
# per product type. Each entry is:
#   { "name": String, "price_cents": int, "texture": String, "count": int }
# The checkout scene uses this to build the correct shopping cart (the products
# and the price the player has to pay).
var required_items_detail: Array[Dictionary] = []