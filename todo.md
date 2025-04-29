# TODO:
- [ ] add toggle for pulse animation
- [ ] connected stairs, do not override if inner/outer variant does not exist
- [x] (turns out there are no inner/outer variant for this) add support for more outer stair preview (example: pine wood does not work)
- [ ] when a player starts to dig or punch remove the preview for a sec
- (this may be of use) core.rotate_and_place(itemstack, placer, pointed_thing[, infinitestacks, orient_flags, prevent_after_place])
- [ ] just rewrite the entire mod... _I need to get rid of GO-TO_
- [ ] (forcing a snap maybe not the best way) corner should snap...
    ? may be a bit more complicated
    - if looking at the side of another stair it should for a corner.(snap)
    - should take into account if top or bottom
- [ ] #bug not connecting when there is a node within it
- [ ] do something with the preview when when the player has not placed anything for a while
    - maybe hide it if looking at an entity
    - shrink it?
    - _its a bit odd to have the preview all the time_
- [x] in-between stairs, add support to preview it
- [x] #bug when looking at a slab.. it should not set corner to inner

# NOTS SURE IF THIS APPLIES
- [.] #bug (fixed?) MCL chest kinda break when placed with this mod (maybe just disable the "preview" of them)
- [ ] change the "calculcations".. their may be some helper functions that can make this better
- [ ] (what?) take into account the player's hand
- [.] figure out how to do placement for inner/outer corner stairs
    - [x] inner stairs

- [ ] setup some type of api for mod devs
- [ ] add ingame cmd for players to edit what orientation behavior a node should have()

- [ ] NOTE Why is it by default only work for stairs and slabs? well, because constantly seeing a preview is kinda annoying specially when this games lets you have building items in your hotbar
- [x] the oneplace should only function when its stairs or slabs
- [ ] example its rotating torches
- [x] made the visual possibly animate
- [x] remove object when the world end
- [x] set for multiplayer
- [x] maybe make it so slabs can become walls.. hold shift?
- [ ] (what?) hold sneak to place as wall
- [x] on place, is not respecting the preview position!!
- [x] player has unlimited full nodes
- [x] (made it glow instead) figure out if i can make it slightly transparent
- [x] add command to enable and disable the feature
- [x] (getting there, logs not being placed right) get correct placement preview depending on paramtyp2
- [ ] use the same horizontal rotatoin that ive been using.. if if point under Y level [x,z] are equal then place facing up/down..
- [ ] otherwise point to sides
- [ ] can use that same logic for wallmounted
- [x] upside down stair are not the right texture orientation
- [x] ignore nodes with buildable tag
- [x] add support for type wallmounted
- [ ] (kinda just works with voxelibre..) combine slabs?? to full node, if the placed node is the same type show a preview in the same location but with the preview being flipped
- [ ] export function to enable and disable feature
- [ ] add an option to enable and disable preview of non- stairs/slab nodes (default=disabled)
- [ ] add support for doors
- [ ] (done with facedir) instead of checking a nodes names check for facedir and 4dir

- [ ] (smooth toggle) options to snap to pos node or glide [set_pos or move_to]

- [ ] (maybe?) (mcl lily pads, should show preview on top of water)
- [ ] (yea no thanks) mcl lantern not in correct orientation
- [x] (mcl may cause problems) let all nodes be able to do full rotations onless specified.. (reason mcl dispenser.. etc.)
- [x] (YES to this) a good amount of node's orientation should be similar to chests/invs types
- [ ] DOTHIS(bro i did it though, trust) facedir will act like logs or nodes with invs. for orientation difference check if the node includes "stair" in name
- [ ] add arch also be stair support
- [x] upper slab, when holding shift it goes to the wrong orientation, it shows up on the bottom, when it should be at the same level as the top
- [x] (currently they can only do 90)
- [ ] stair corners need to be able to do a full 180. add support for stairs to do a full 180
- [ ] could also manage converting normal stairs to conrer stairs depending on when is around
- [ ] do something like how im doing with the slabs(holding sneak)
- [ ] ok if looking above a certain amount and also holding shift.. do a 180
- [x] pretty sure pp broke door placement
- [x] workbench rotations
- [x] (making slabs that much better to place) slabs should only show the full preview only if pointed at the face within the node's position
- [x] holding shift while points at an upper set of slabs.. it will visually show the right placement, but on place it will place lower
- [.] (is it fixed?) pumpkin placement is not correct
- [x] preview doors
- [x] (default_cobble.png) remove mtg dependency
- [x] stairs/slabs only setting causes crash

- [ ] #bug mcl daylight-sensor,and carpets looking goofy
- [ ] #bug need to ignore the player's own hitbox. gets in the way when trying to "preview" placement below the player.
- [ ] #bug look position is not alawys where it should be.. if they intersection is too close it will miss the node git the next.
- [ ] #bug (ill just get an api going) mcl whatever the player head node is.. it needs to preview to the players rotatoin
- [ ] #bug running /clearobjects causes crash
- [ ] actually save the player's settings
- [ ] maybe holding shift should "lock" the rotation to normal
- [ ] maybe switch placement orientation to depend on what block face they its being placed on

- [ ] IDEA option "sneak to preview"
- [ ] distance should be up to the player's reach
