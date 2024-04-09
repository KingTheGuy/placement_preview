![sample-gif](./repo-assets/crunchy.gif)

----
Shows an in world placement preview of the item held in hand

_Hold `sneak` for more orientations_

player commands/settings: _/placement_preview_ **help**
settings include:
* smooth movement
* only preview stairs and slabs
* disable/enable preview

Originally this mod was intended to only preview stairs/slab placement

_1.0.5 CHANGELOG:_
  * by default only slabs and stairs will preview (can be toggled with command)
  * removed mtg dependency
  * bug fixes (setting: _only_stairs_slabs_, was causing a crash)

_1.0.4 CHANGELOG:_
  * new animation after placing node/block (great for when placing "blocks" quickly)
  * fixed crafting table placement (mcl)
  * actually fixed door placement (80% sure)
  * slightly changed slab placing (still need a bit more work)

_1.0.3 CHANGELOG:_
  * fixed doors and workbench placement

_1.0.2 CHANGELOG:_
  * per player settings (using commands)
  * support for placement of inner and outer stairs
  * bug fixes

_1.0.1 CHANGELOG:_
  * double slab preview
  * better node orientation
  * preview on buildable_to
  * added more compatibility 

_note for devs_: if you want a node to preview like stairs, add "stairs" somewhere in the node's name or description (i may create an api for this at some point)

