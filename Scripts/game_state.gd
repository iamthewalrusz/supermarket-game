extends Node
## Shared game state between scenes.
## FallingGame records which items the player must find; the market
## platformer reads this list to know what to place in the supermarket.

# The items the player must find (written by FallingGame).
var required_items: Array[String] = ["Apple", "Milk", "Eggs"]
# Items already picked up in the market platformer.
var picked_up_in_market: Array[String] = []