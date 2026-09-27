# iOS Physical Device QA Checklist — Cave Ranger

This test plan validates the production build of **Cave Ranger** (`com.vntm.caverangerx`) on physical iPhones and iPads running iOS 16.0+.

---

## 1. Application Launch & Identity
- [ ] **Home Screen Display Name**: Appears as `Cave Ranger`.
- [ ] **App Icon**: `icon.png` (1024×1024) rendered crisply on home screen and App Switcher.
- [ ] **Launch Orientation**: Launches directly into landscape orientation without portrait flash.
- [ ] **Permissions Check**: Does NOT prompt for camera, microphone, location, contacts, or Bluetooth.

---

## 2. Platforming & Movement
- [ ] **Virtual Joystick**:
  - Smooth horizontal acceleration to left and right.
  - Releases cleanly to center with instant deceleration.
  - Deadzone prevents jitter when resting thumb.
- [ ] **Jump**:
  - Crisp upward impulse force.
  - Double jumping is blocked while airborne.
- [ ] **Coyote Time**:
  - Walking off a platform edge allows jump input within ~0.10s.
- [ ] **Jump Buffering**:
  - Pressing Jump ~0.10s before touching ground immediately triggers jump upon landing.
- [ ] **Landing Feedback**:
  - Plays `player_land.wav` and emits small pixel dust puff at feet.
- [ ] **Death Pit Safety**:
  - Falling below cave level (`Y < -100`) resets player position cleanly to spawn point.

---

## 3. Combat Mechanics
- [ ] **Whip (Melee)**:
  - Tapping **WHIP** plays whip swing animation and `whip_attack.wav`.
  - Inflicts 1 damage to snakes within reach (55pt).
  - Anti-multi-hit: Each snake takes damage only once per swing.
  - Plays `whip_impact.wav` and spawns yellow impact spark burst on hit.
- [ ] **Revolver (Ranged)**:
  - Tapping **SHOOT** consumes 1 round, plays `revolver_fire.wav`, shows muzzle flash, and emits screen shake (2.0pt).
  - Bullet travels across screen and hits enemies or cave walls.
  - On enemy contact: deals 1 damage, destroys bullet, plays impact VFX.
  - On wall contact: destroys bullet with spark puff.
- [ ] **Reloading**:
  - Tapping **RELOAD** (or shooting at 0 ammo) triggers 1.0s cylinder reload.
  - HUD displays `RELOAD` indicator.
  - Plays `revolver_reload.wav` upon completion, restoring 6 rounds.

---

## 4. Enemies (Snake AI)
- [ ] **Patrol**: Snakes patrol horizontal territory (±70pt) and turn around at boundaries.
- [ ] **Chase**: Snakes detect player within 160pt and slither towards player.
- [ ] **Telegraphed Attack**: Snake pauses with visual warning (0.12s) before striking.
- [ ] **Damage & Invulnerability**:
  - Contact deals 1 heart of damage.
  - Player flashes red with 0.8s invulnerability and camera shake.
  - Health meter updates: `HP ♥ ♥ ♡`.
- [ ] **Defeat**: Inflicting 3 damage plays `snake_death.wav` and fades snake out.

---

## 5. Collectibles & Progression
- [ ] **Coin Pickups**:
  - 20 coins placed across all 5 mine sections.
  - Player contact triggers spin sparkle animation and `coin_collect.wav`.
  - HUD counter increments in real time: `COINS 1/20` ... `COINS 20/20`.
- [ ] **Mine Exit Portal**:
  - Located in Section 5 (Open Cave area).
  - Player contact activates portal sequence: rising energy wisps, `exit_activate.wav`, `level_complete.wav`.
  - Controls are locked while exit animation plays.

---

## 6. UI, Menus & Safe Area Insets
- [ ] **Camera Binding**: HUD and touch controls remain fixed on screen while cave scrolls.
- [ ] **Safe Area Alignment**:
  - Controls clear notch, Dynamic Island, and Home Indicator on iPhone 13/14/15/16.
- [ ] **Pause Modal**:
  - Tapping **[ II ]** pauses game loop and audio (`ui_pause.wav`).
  - **[ RESUME ]** restores active gameplay.
  - **[ RESTART ]** cleanly recreates level without node leaks.
- [ ] **Level Complete Modal**:
  - Displays **Current Run** (Coins / Time) vs. **Best Record**.
  - Displays **`★ NEW BEST! ★`** banner when new record is set.
- [ ] **Game Over Modal**:
  - Appears on 0 health; tapping **[ RETRY ]** restarts the level.

---

## 7. Persistent Save System (`SaveManager`)
- [ ] **First Completion**: Saves completion for `"mine_01"` with clear time and coin count.
- [ ] **Faster Run**: Completing in faster time replaces best time in `UserDefaults`.
- [ ] **Slower Run**: Completing in slower time preserves existing best time record.
- [ ] **Higher Coins**: Run with higher coins updates best coin record.
- [ ] **Lower Coins**: Run with lower coins keeps existing best coin record.
- [ ] **Death / Restart**: Does NOT overwrite saved best records.
- [ ] **App Relaunch**: Quitting and reopening loads saved progression immediately.

---

## 8. Performance & Lifecycle
- [ ] **Target Frame Rate**: Smooth 60 FPS without stutter or dropped frames.
- [ ] **Background / Interruption**:
  - Locking screen or receiving phone call pauses game via `applicationWillResignActive`.
  - Returning to app shows Pause modal.
- [ ] **Memory**: Repeated restarts/retries do not accumulate memory or lag.
