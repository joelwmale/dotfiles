---
name: blender-character-animation
description: Rig fixes and game-ready animation for a character in the user's live Blender through the Blender MCP - rest pose and stance, idle and combat clips, gravity-driven cloth chains, verification, handoff to Studio. WIP. Use when asked to animate, fix, retarget or reuse a character rig in Blender.
---

WIP: written from the first full run on the Riftborn humanoid (October 2026). Sections marked TODO are not yet proven. Do not treat the numbers as universal; they are the game's limits and the values that worked on that asset.

## Ground rules

- Work through the Blender MCP (`get_scene_info`, `execute_blender_code`, `look`). The scene is the user's live file: never save, never export, never delete an object or action, never touch objects outside the character. Exporting and saving are the owner's call.
- **Back up before any change to the model** (rest pose, weights, new bones): copy the rig and mesh into a hidden collection named `backup_before_<change>`, check the copy deforms identically (max vertex difference 0.0 at 3 frames, 0 weight mismatches), keep every older backup. Every edit goes into a new action name with a version suffix (`idle_v2`, `idle_v3`); earlier ones stay for comparison.
- **Look before you report.** Numbers (bone distances, clearances, stretch ratios) did not catch a sleeve wrapped across the torso and an arm pose that read as folded arms. Before calling anything done, view it at max_size 1024 or more: front, side, three-quarter at 30 degrees up, back, and a close-up of the part you changed, and a frames strip across the loop. State what you actually see; do not report success unless it visibly reads right. If you can only judge a motion from stills, say so.
- Quote the user's words in `user_prompt` on every Blender call.

## Game limits (Riftborn client)

30 fps clips; at most 72 bones; 4 skin weights per vertex; embedded textures only; clip names idle, attack, skill_1, skill_2, ultimate, hit, death, victory, summon_turn, move (plus entrance). Studio maps clips to those actions and stores markers (`hit`, `release`, `settle`) as frame numbers at 30 fps; report them per clip. Loops (idle, move): last frame must continue into frame 1 in pose and velocity, never duplicate the end frame.

## Steps

1. **Inventory.** Armature, mesh, actions (names, ranges, keyed channels, interpolation), bone list, existing rest pose width, mesh height, feet on z=0. Note whether every key is linear and baked per frame (imported clips often are).
2. **Rest pose first.** Measure ankle gap versus hip width, knee gap, wrist-to-hip distance. A splayed rest pose makes every clip look wrong (a waddle). Fix by posing, baking the deformed vertices into the mesh, applying the pose as rest pose, restoring identity. Do the legs, then the arms, as separate steps with separate backups. Afterwards every existing clip inherits the new rest, so re-measure them; clips authored to compensate (a narrowing added on top) are now double-adjusted and must be renamed `_old`, not deleted.
3. **Clean-up of what the bake breaks.** Hard-surface shards and cloth sheets that share vertex groups with the bones you moved tear or shear. Re-derive the affected vertices from the backup through skin weights, relax only the cloth vertices (symmetric, order-independent smoothing anchored to the leg-weighted vertices); measure edge stretch per leg, left versus right, and view close-ups from three angles. Aggressive neighbour smoothing mangled armour plates once.
4. **Author the clips.** Pose-to-pose with real principles: anticipation, overshoot and settle, overlapping action (arms and hands trail the torso, cloth trails the hips), arcs, slow-in slow-out (Bezier, never linear), holds that keep breathing. Key sparse poses, sample with a spline, simulate secondary motion with a spring (damped, world-space), cap cloth swing. Keep feet planted without sliding. Idle for a battler is a **ready stance**, not a relaxed pose: a clear boxing stance (rear leg back 0.5 to 0.6 m, narrow lateral gap, body bladed 40 to 45 degrees, rear foot turned out, knees bent, hips lowered, fists up at chin height with elbows tucked) plus a visible sway.
5. **Sleeves and cloth under gravity.** A rigid sleeve shell on one bone sticks out like a blade when the forearm is raised. Add a chain of drape bones (up to 6 segments, 8 to 10 cm each) from the rim of the rigid armour, weight the cloth along its rest hang direction with a wide smooth blend, keep rigid armour (bracers, plates) 100% on the forearm (separate armour from cloth by sampling the base-colour texture at each vertex's UV, then a neighbour majority vote, and check the classification visually), and drive the chain as a damped pendulum aimed at world-down with an inertial term from the attachment's world acceleration plus a small flutter. Gates: segments 2 to 4 within 25 degrees of world-down, hem at least 0.35 m below the rim, cloth never crossing the centre plane, a real nearest-point test against the body (not bone distances), at most 5% of edges stretched past 1.6x or squashed past 0.6x. The drape bones must be keyed in every action that uses the rig, or the cloth stays wherever it was last evaluated: run the same solve per action (loops warmed up over several cycles, non-loops settled first).
6. **Hands.** The rig may have a single hand bone. Bake a fist into the hand mesh for combat clips (own backup), or add finger bones (watch the 72-bone budget).
7. **Blend the set.** Non-loop clips start and end on the ready-stance pose; re-base or blend the first and last frames so transitions do not pop. Re-measure foot slide, loop seam, largest per-frame step and marker frames per clip.
8. **Report.** Per clip: length, marker frames, largest steps (and which frames exceed 6 degrees on purpose), foot slide, loop seam, weak spots, what to play and look at, how to revert. Say what was judged from stills only.

## Quality gates (copy into every brief)

Largest per-frame rotation step 6 degrees except marked impact frames; loop seam 0 in pose and velocity; foot slide under 10 mm on planted feet; no arm or sleeve crossing the centre plane in a guard; weights outside the changed region 0 mismatches against the backup; bones under 72, influences 4.

## TODO

- Reusable scripts (measurement helpers, spring solver, per-action cloth routine) saved under `scripts/` once the full pass is done.
- Export checklist (glb settings, bone and clip naming, Studio mapping and markers, the loader limits) after the first real export.
- Retargeting the clips onto another humanoid; what changes for a different skeleton (quadrupeds need their own rig and clips).
- Fingers: a repeatable finger-bone setup if open hands are needed.
- Time and cost notes per clip once measured.
