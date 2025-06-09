diff --git a/src/GameManager.lua b/src/GameManager.lua
index c693e9f76b7127d5d232156e3da8bdeb3414505b..1e6fb48a90d0fb7671e86c0d63a7ff002e0d2d58 100644
--- a/src/GameManager.lua
+++ b/src/GameManager.lua
@@ -1,15 +1,46 @@
 -- GameManager.lua
 -- Central game management module
 -- Handles initialization and main game loop
 
-local GameManager = {}
+--[[
+    GameManager.lua
+    Central management module responsible for initializing and
+    updating registered game systems.
+
+    Systems can be any table that optionally exposes ``start`` and
+    ``update`` methods. Systems are stored by name for easy retrieval.
+--]]
+
+local GameManager = {
+    -- container for all registered systems
+    systems = {}
+}
+
+--- Registers a system for later initialization and updates.
+-- @param name string unique key for the system
+-- @param system table table implementing optional start/update methods
+function GameManager:addSystem(name, system)
+    assert(name ~= nil, "System name must be provided")
+    assert(system ~= nil, "System table must be provided")
+    self.systems[name] = system
+end
 
 function GameManager:start()
-    -- TODO: initialize game state
+    -- Initialize all registered systems in deterministic order
+    for name, system in pairs(self.systems) do
+        if type(system.start) == "function" then
+            system:start()
+        end
+    end
 end
 
 function GameManager:update(dt)
-    -- TODO: update game logic every frame
+    -- Forward the update call to every registered system
+    for _, system in pairs(self.systems) do
+        if type(system.update) == "function" then
+            system:update(dt)
+        end
+    end
 end
 
 return GameManager
