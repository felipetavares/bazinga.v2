Bazinga Engine v2
=================
Completely written in Lua with the Löve framework.

Version 0.2.2b Bazinga Editor

About this release
------------------

TODO: Change references in editor.lua->objectCopy to level.lua->Level:copyObject
TODO: Allow images in buttons

* Grid based editing (done)
    - Bug when moving selection, it aligns some objects to the grid in the wrong way
    - Configurable grid size & offset (done)
* Ordered drawing (done)
    - Heap Sort (done)
* Undo/Redo (done)
    - Bug when undo and then do something. The history becames messed up (fixed)
* Layer up/down movement (done)