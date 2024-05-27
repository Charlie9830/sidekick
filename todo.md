## TODO ##
-> Implement a Way to modify Fixture Types / Reimport Fixture Types once added.
-> Pressing Enter on the Sequence number TextField should shift focus back to the Fixture Number Field.
-> Pressing Decimal "." or maybe "+" on the Fixture Number Box should shift focus to the SEquence Number Box.
-> Fix Fixture Table Dividers so that a Location header appears at the top.
-> Editing a Loom Prefix should reflect imediately in the data and not require a re-generation / Commit.
-> Power Patch assignments get weird when Stuff has a sequence number of Zero. For Example, if you have two positions, Red, then White. If you seqeuence White and 
    generate a patch, it will get all messed up because Red isnt' sequenced. In fact, White will get patched as Red. Perhaps the Balancer needs to ignore circuits with a Zero as a Sequence number.