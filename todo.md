## TODO ##

-> Refactor CableModel.dataMultiId. You are currently using this to draw a relationship between child DMX cables and their Sneak Parents, but this is incorrect
    this property should only be used to draw a relationship between a Sneak Cable and it's DataMultiModel. Instead we should use a multiParentId property on CableModel
    to draw a relationship to the Sneak.

-> Cable Upstream attachment system, we probably need a way to explicitly attach downstream cables to Upstream cables.. in other words 'plug' them in. This will allow for more complicated loom setups, like a Sneak breaking out to DMX for a dropdown, or breaking out to DMX to more then 1 location.

-> Spliting and combining sneaks in Feeders and their extensions causes strange behaviour, often incorrectly renumbering the other Sneak. It's likely due
    to the sneak being numbered based off the total number of sneaks assigned to a location, where as if you create a sneak in an extension, it should be able to
    be tied to it's feeder side equivalent.
-> Fix Selection system in Looms Table, can't multi select, cant touchpad scroll etc.
-> Improve Fixture Table selection system.
-> Looms Overview screen with Flowcharty style.
-> Fix Green as incorrect Color Assumption.