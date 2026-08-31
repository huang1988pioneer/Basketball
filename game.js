/*
 * 喵萌籃球大作戰 · tiny, dependency-free 2D game loop
 * The canvas is intentionally self-contained so the prototype can be opened
 * from a file or served by any static web server.
 */

(() => {
  "use strict";

  const canvas = document.getElementById("gameCanvas");
  const ctx = canvas.getContext("2d");
  const W = canvas.width;
  const H = canvas.height;
  const TAU = Math.PI * 2;
  const floor = { horizon: 292, baseline: 575, left: 35, right: 1245 };
  const hoop = { x: 1072, y: 345, rimY: 355 };

  // The Godot build and the browser build share the same generated art.  The
  // canvas still keeps its procedural fallback so the game remains playable
  // when opened offline before the PNGs finish loading.
  const generatedArt = {
    court: new Image(),
    player: new Image(),
    opponent: new Image(),
    storyOpponent: new Image(),
    bossOpponent: new Image(),
    support: new Image(),
    fireDunkVfx: new Image(),
    threePointerVfx: new Image(),
    crossoverVfx: new Image(),
    trophyBadge: new Image(),
    protagonistGroup: new Image(),
    characterShowcase: new Image(),
    skillShowcase: new Image(),
  };
  generatedArt.court.src = "assets/generated-rooftop-court-v3.png";
  generatedArt.player.src = "assets/generated-white-cat.png";
  generatedArt.opponent.src = "assets/generated-calico-cat.png";
  generatedArt.storyOpponent.src = "assets/generated-orange-cat-v2.png";
  generatedArt.bossOpponent.src = "assets/generated-boss-cat-v2.png";
  generatedArt.support.src = "assets/generated-support-cat-v2.png";
  generatedArt.fireDunkVfx.src = "assets/generated-vfx-fire-dunk-v2.png";
  generatedArt.threePointerVfx.src = "assets/generated-vfx-three-pointer-v2.png";
  generatedArt.crossoverVfx.src = "assets/generated-vfx-crossover-v2.png";
  generatedArt.trophyBadge.src = "assets/generated-trophy-badge-v2.png";
  generatedArt.protagonistGroup.src = "assets/generated-protagonist-group-v1.png";
  generatedArt.characterShowcase.src = "assets/generated-character-showcase-v1.png";
  generatedArt.skillShowcase.src = "assets/generated-skill-showcase-v1.png";
  Object.values(generatedArt).forEach((image) => image.addEventListener("load", () => draw()));

  const $ = (id) => document.getElementById(id);
  const scoreEls = { player: $("playerScore"), opponent: $("opponentScore") };
  const ui = {
    timer: $("gameTimer"),
    period: $("periodNumber"),
    status: $("scoreStatus"),
    stateIcon: $("stateIcon"),
    stateTitle: $("stateTitle"),
    stateDescription: $("stateDescription"),
    start: $("startButton"),
    reset: $("resetButton"),
    shotButton: $("shotButton"),
    shotHint: $("shotButtonHint"),
    possession: $("possessionPill"),
    playerAvatar: $("playerAvatar"),
    playerName: $("playerName"),
    playerTeam: $("playerTeam"),
    playerStatusAvatar: $("playerStatusAvatar"),
    statusPlayerName: $("statusPlayerName"),
    statusPlayerRole: $("statusPlayerRole"),
    opponentName: $("opponentName"),
    opponentTeam: $("opponentTeam"),
    opponentAvatar: $("opponentAvatar"),
    energyValue: $("energyValue"),
    energyBar: $("energyBar"),
    energyText: $("energyText"),
    staminaBar: $("staminaBar"),
    staminaText: $("staminaText"),
    toast: $("globalToast"),
    courtToast: $("courtToast"),
    matchLabel: $("matchLabel"),
  };

  const state = {
    running: false,
    gameOver: false,
    elapsed: 0,
    timeLeft: 90,
    period: 1,
    mode: "quick",
    modeName: "快速比賽",
    score: { player: 0, opponent: 0 },
    possession: "player",
    player: { x: 355, y: 542, stamina: 86, facing: 1, bob: 0, dash: 0 },
    opponent: { x: 808, y: 535, stamina: 100, facing: -1, bob: 0, dash: 0 },
    ball: { x: 383, y: 454, r: 16, inFlight: false, loose: false, spin: 0 },
    charging: false,
    chargingShooter: null,
    charge: 0.18,
    chargeDir: 1,
    chargeTime: 0,
    shotCooldown: 0,
    shotShooter: null,
    pendingShot: null,
    opponentThink: 1.25,
    opponentShotCooldown: 0,
    opponentDefenseCooldown: 0,
    energy: 68,
    sprinting: false,
    joystick: { x: 0, y: 0, active: false },
    keys: Object.create(null),
    particles: [],
    floaters: [],
    rings: [],
    screenShake: 0,
    toastTimer: 0,
    lastTime: 0,
    character: "white",
    muted: false,
    skillFlash: null,
    skillFlashTime: 0,
    nextShotBonus: 0,
  };

  const characterData = {
    white: { name: "喵白白", role: "BLUE PAWS · 控球後衛", bio: "靈活的街頭控衛，擅長後撤步和快速變向。", color: "blue", asset: "assets/generated-white-cat.png", number: "23", stats: [76, 82, 68, 58], stars: ["★★★★☆", "★★★★☆", "★★★☆☆", "★★★☆☆"] },
    calico: { name: "喵布布", role: "RED CLAWS · 得分後衛", bio: "自信的進攻箭頭，三分線外就是她的主場。", color: "red", asset: "assets/generated-calico-cat.png", number: "23", stats: [65, 88, 91, 52], stars: ["★★★☆☆", "★★★★☆", "★★★★★", "★★★☆☆"] },
    orange: { name: "喵橘橘", role: "TEAL TIGERS · 敏捷前鋒", bio: "擅長交叉運球與快速切入，能在防守縫隙中找到空間。", color: "teal", asset: "assets/generated-orange-cat-v2.png", number: "7", stats: [92, 74, 70, 64], stars: ["★★★★★", "★★★☆☆", "★★★☆☆", "★★★☆☆"] },
    boss: { name: "喵霸霸", role: "VIOLET BOSS · 全能中鋒", bio: "體格壓迫感十足的街頭巨星，籃下與外線都不能放空。", color: "purple", asset: "assets/generated-boss-cat-v2.png", number: "99", stats: [48, 80, 72, 96], stars: ["★★☆☆☆", "★★★★☆", "★★★☆☆", "★★★★★"] },
  };

  const opponentPresentation = {
    quick: { name: "喵布布", team: "RED CLAWS", asset: "assets/generated-calico-cat.png", color: "#ff6874" },
    story: { name: "喵橘橘", team: "TEAL TIGERS", asset: "assets/generated-orange-cat-v2.png", color: "#24c3bf" },
    challenge: { name: "喵布布", team: "RED CLAWS", asset: "assets/generated-calico-cat.png", color: "#ff6874" },
    boss: { name: "喵霸霸", team: "VIOLET BOSS", asset: "assets/generated-boss-cat-v2.png", color: "#a875ff" },
    duo: { name: "喵布布", team: "RED CLAWS", asset: "assets/generated-calico-cat.png", color: "#ff6874" },
  };

  const modeData = {
    quick: { name: "快速比賽", duration: 90, target: 11, opponentAccuracy: .46, opponentSpeed: 150, label: "快速比賽　•　先得 11 分" },
    story: { name: "故事模式", duration: 105, target: 15, opponentAccuracy: .50, opponentSpeed: 158, label: "故事模式　•　先得 15 分" },
    challenge: { name: "挑戰模式", duration: 60, target: 18, opponentAccuracy: .55, opponentSpeed: 168, label: "挑戰模式　•　60 秒得 18 分" },
    boss: { name: "Boss 挑戰", duration: 120, target: 21, opponentAccuracy: .67, opponentSpeed: 185, label: "Boss 挑戰　•　決戰 21 分" },
    duo: { name: "雙人對戰", duration: 90, target: 11, opponentAccuracy: .46, opponentSpeed: 150, label: "雙人對戰　•　先得 11 分" },
  };

  const skyline = [
    [0, 166, 88], [77, 209, 62], [134, 148, 93], [220, 189, 72], [282, 128, 113], [382, 185, 66],
    [438, 153, 88], [517, 193, 68], [588, 117, 124], [700, 176, 78], [777, 137, 112], [874, 191, 71],
    [945, 151, 94], [1036, 112, 132], [1145, 174, 80], [1221, 139, 104],
  ];

  let audioContext = null;
  let toastTimeout = null;

  function clamp(value, min, max) { return Math.max(min, Math.min(max, value)); }
  function lerp(a, b, t) { return a + (b - a) * t; }
  function distance(a, b) { return Math.hypot(a.x - b.x, a.y - b.y); }
  function formatTime(seconds) {
    const safe = Math.max(0, Math.ceil(seconds));
    return `${String(Math.floor(safe / 60)).padStart(2, "0")}:${String(safe % 60).padStart(2, "0")}`;
  }
  function roundRect(context, x, y, w, h, r) {
    const radius = Math.min(r, Math.abs(w) / 2, Math.abs(h) / 2);
    context.beginPath();
    context.moveTo(x + radius, y);
    context.arcTo(x + w, y, x + w, y + h, radius);
    context.arcTo(x + w, y + h, x, y + h, radius);
    context.arcTo(x, y + h, x, y, radius);
    context.arcTo(x, y, x + w, y, radius);
    context.closePath();
  }
  function rgba(hex, alpha) {
    const clean = hex.replace("#", "");
    const n = Number.parseInt(clean, 16);
    return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${alpha})`;
  }

  function playTone(frequency = 440, duration = 0.08, type = "sine", volume = 0.035) {
    if (state.muted) return;
    try {
      audioContext ||= new (window.AudioContext || window.webkitAudioContext)();
      const oscillator = audioContext.createOscillator();
      const gain = audioContext.createGain();
      oscillator.type = type;
      oscillator.frequency.value = frequency;
      gain.gain.setValueAtTime(volume, audioContext.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.0001, audioContext.currentTime + duration);
      oscillator.connect(gain).connect(audioContext.destination);
      oscillator.start();
      oscillator.stop(audioContext.currentTime + duration);
    } catch (_) { /* audio is an optional flourish */ }
  }

  function showToast(message, duration = 1800, court = true) {
    if (court) {
      ui.courtToast.textContent = message;
      ui.courtToast.classList.add("show");
      window.clearTimeout(showToast.courtTimer);
      showToast.courtTimer = window.setTimeout(() => ui.courtToast.classList.remove("show"), duration);
    }
    ui.toast.textContent = message;
    ui.toast.classList.add("show");
    window.clearTimeout(toastTimeout);
    toastTimeout = window.setTimeout(() => ui.toast.classList.remove("show"), duration);
  }

  function addParticle(x, y, color, options = {}) {
    state.particles.push({ x, y, vx: options.vx ?? (Math.random() - .5) * 110, vy: options.vy ?? (-Math.random() * 100 - 25), life: options.life ?? .7, maxLife: options.life ?? .7, size: options.size ?? (Math.random() * 4 + 2), color, gravity: options.gravity ?? 100, shape: options.shape ?? "dot" });
  }
  function burst(x, y, color, count = 18) {
    for (let i = 0; i < count; i += 1) {
      const angle = Math.random() * TAU;
      const speed = 45 + Math.random() * 155;
      addParticle(x, y, color, { vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed - 45, life: .65 + Math.random() * .5, gravity: 145, size: 2 + Math.random() * 4, shape: i % 3 === 0 ? "star" : "dot" });
    }
  }
  function addFloater(text, x, y, color = "#fff3b1") {
    state.floaters.push({ text, x, y, life: 1.1, maxLife: 1.1, color });
  }

  function resetGame(keepMode = true) {
    const mode = keepMode ? modeData[state.mode] : modeData.quick;
    state.running = false;
    state.gameOver = false;
    state.elapsed = 0;
    state.timeLeft = mode.duration;
    state.period = 1;
    state.score.player = 0;
    state.score.opponent = 0;
    state.possession = "player";
    state.player.x = 355;
    state.player.y = 542;
    state.player.stamina = 86;
    state.player.dash = 0;
    state.opponent.x = 808;
    state.opponent.y = 535;
    state.opponent.stamina = 100;
    state.opponent.dash = 0;
    state.ball = { x: 383, y: 454, r: 16, inFlight: false, loose: false, spin: 0 };
    state.charging = false;
    state.chargingShooter = null;
    state.charge = 0.18;
    state.chargeDir = 1;
    state.chargeTime = 0;
    state.shotCooldown = 0;
    state.shotShooter = null;
    state.pendingShot = null;
    state.opponentThink = 1.2;
    state.opponentShotCooldown = 0;
    state.opponentDefenseCooldown = 0;
    state.energy = 68;
    state.sprinting = false;
    state.particles.length = 0;
    state.floaters.length = 0;
    state.rings.length = 0;
    state.screenShake = 0;
    state.skillFlash = null;
    state.skillFlashTime = 0;
    state.nextShotBonus = 0;
    ui.matchLabel.textContent = mode.label;
    updateControlsUI();
    updateUI(true);
    showToast("球場已準備好，按下開始比賽！", 1900, false);
  }

  function startOrPause() {
    if (state.gameOver) resetGame();
    state.running = !state.running;
    const playerName = (characterData[state.character] || characterData.white).name;
    if (state.running) {
      ui.start.innerHTML = "Ⅱ　暫停比賽";
      ui.start.classList.add("is-running");
      ui.stateIcon.textContent = "🔥";
      ui.stateTitle.textContent = "比賽進行中";
      ui.stateDescription.textContent = "找空檔、抓節奏，讓對手追不上你的腳步。";
      ui.status.textContent = "比賽進行中";
      showToast(`開球！${playerName}，掌握節奏！`, 1400);
      playTone(520, .11, "triangle");
    } else {
      ui.start.innerHTML = "▶　繼續比賽";
      ui.start.classList.remove("is-running");
      ui.stateIcon.textContent = "⏸";
      ui.stateTitle.textContent = "比賽暫停";
      ui.stateDescription.textContent = "休息一下，準備好再回到球場。";
      ui.status.textContent = "已暫停";
    }
    updateUI(true);
  }

  function endGame(reason = "time") {
    state.running = false;
    state.gameOver = true;
    state.charging = false;
    state.chargingShooter = null;
    const playerWon = state.score.player > state.score.opponent;
    const tied = state.score.player === state.score.opponent;
    ui.start.innerHTML = "▶　再來一場";
    ui.start.classList.remove("is-running");
    ui.stateIcon.textContent = playerWon ? "🏆" : tied ? "🤝" : "💪";
    ui.stateTitle.textContent = playerWon ? "漂亮！拿下勝利" : tied ? "平手！再來一場" : "差一點點，再來一次";
    const target = modeData[state.mode].target;
    ui.stateDescription.textContent = reason === "target" ? `先到 ${target} 分的隊伍贏得街頭榮耀。` : "時間到！調整出手節奏，再挑戰一次。";
    ui.status.textContent = "比賽結束";
    const playerName = (characterData[state.character] || characterData.white).name;
    showToast(playerWon ? `🏆 勝利！${playerName}稱霸球場！` : tied ? "🤝 平手！下一場決勝負。" : "終場！下一球一定更準。", 2800);
    burst(hoop.x, hoop.rimY - 9, playerWon ? "#ffd46b" : "#77bcff", 34);
    playTone(playerWon ? 740 : tied ? 420 : 230, .25, playerWon || tied ? "triangle" : "sawtooth", .045);
    updateUI(true);
  }

  function update(dt) {
    if (!state.running) return;
    state.elapsed += dt;
    state.timeLeft -= dt;
    state.shotCooldown = Math.max(0, state.shotCooldown - dt);
    state.opponentShotCooldown = Math.max(0, state.opponentShotCooldown - dt);
    state.opponentDefenseCooldown = Math.max(0, state.opponentDefenseCooldown - dt);
    state.player.dash = Math.max(0, state.player.dash - dt);
    state.opponent.dash = Math.max(0, state.opponent.dash - dt);
    state.screenShake = Math.max(0, state.screenShake - dt);
    state.skillFlashTime = Math.max(0, state.skillFlashTime - dt);

    updatePlayer(dt);
    updateOpponent(dt);
    updateShotCharge(dt);
    updateBall(dt);
    updateLooseBall(dt);
    updateEffects(dt);
    updateOpponentAI(dt);

    if (state.timeLeft <= 0) endGame("time");
    const target = modeData[state.mode].target;
    if (state.score.player >= target || state.score.opponent >= target) endGame("target");
    updateUI();
  }

  function updatePlayer(dt) {
    const duoMode = state.mode === "duo";
    const keyX = duoMode
      ? (state.keys.d ? 1 : 0) - (state.keys.a ? 1 : 0)
      : (state.keys.ArrowRight || state.keys.d ? 1 : 0) - (state.keys.ArrowLeft || state.keys.a ? 1 : 0);
    const keyY = duoMode
      ? (state.keys.s ? 1 : 0) - (state.keys.w ? 1 : 0)
      : (state.keys.ArrowDown || state.keys.s ? 1 : 0) - (state.keys.ArrowUp || state.keys.w ? 1 : 0);
    let moveX = keyX + state.joystick.x;
    let moveY = keyY + state.joystick.y;
    const magnitude = Math.hypot(moveX, moveY);
    if (magnitude > 1) { moveX /= magnitude; moveY /= magnitude; }

    const sprintKey = Boolean(state.keys.Shift);
    state.sprinting = sprintKey || state.sprinting;
    const wantsSprint = state.sprinting && magnitude > .05 && state.player.stamina > 0;
    const speedStat = characterData[state.character]?.stats?.[0] ?? 76;
    const speedFactor = clamp(.88 + speedStat / 500, .92, 1.12);
    const speed = (wantsSprint ? 390 : 245) * speedFactor;
    if (wantsSprint) state.player.stamina = Math.max(0, state.player.stamina - dt * 20);
    else state.player.stamina = Math.min(100, state.player.stamina + dt * 8);
    state.player.x = clamp(state.player.x + moveX * speed * dt, 110, 1015);
    state.player.y = clamp(state.player.y + moveY * speed * .38 * dt, 445, 569);
    if (Math.abs(moveX) > .02) state.player.facing = moveX > 0 ? 1 : -1;
    state.player.bob += dt * (magnitude > .05 ? (wantsSprint ? 15 : 10) : 3);
    if (state.player.dash > 0) {
      state.player.x = clamp(state.player.x + state.player.facing * 180 * dt, 110, 1015);
    }
    if (state.possession === "player" && !state.ball.inFlight) {
      state.ball.x = state.player.x + state.player.facing * 28;
      state.ball.y = state.player.y - 76 + Math.sin(state.elapsed * 11) * 7;
      state.ball.loose = false;
    }
  }

  function updateOpponent(dt) {
    if (state.mode === "duo") {
      updateHumanOpponent(dt);
      return;
    }
    const o = state.opponent;
    const p = state.player;
    let targetX = state.possession === "opponent" ? hoop.x - 120 : p.x + 108;
    let targetY = state.possession === "opponent" ? 505 : p.y - 5;
    if (state.ball.loose) { targetX = state.ball.x; targetY = state.ball.y + 70; }
    const dx = targetX - o.x;
    const dy = targetY - o.y;
    const dist = Math.hypot(dx, dy) || 1;
    const speed = modeData[state.mode].opponentSpeed;
    o.x = clamp(o.x + dx / dist * speed * dt, 170, 1120);
    o.y = clamp(o.y + dy / dist * speed * .38 * dt, 445, 569);
    if (Math.abs(dx) > 2) o.facing = dx > 0 ? 1 : -1;
    o.bob += dt * (dist > 30 ? 9 : 3);
    if (state.possession === "opponent" && !state.ball.inFlight) {
      state.ball.x = o.x + o.facing * -27;
      state.ball.y = o.y - 75 + Math.sin(state.elapsed * 10 + 1) * 6;
      state.ball.loose = false;
    }
  }

  function updateHumanOpponent(dt) {
    const o = state.opponent;
    const keyX = (state.keys.ArrowRight ? 1 : 0) - (state.keys.ArrowLeft ? 1 : 0);
    const keyY = (state.keys.ArrowDown ? 1 : 0) - (state.keys.ArrowUp ? 1 : 0);
    let moveX = keyX;
    let moveY = keyY;
    const magnitude = Math.hypot(moveX, moveY);
    if (magnitude > 1) { moveX /= magnitude; moveY /= magnitude; }
    const speedStat = characterData.calico?.stats?.[0] ?? 65;
    const speed = 245 * clamp(.88 + speedStat / 500, .92, 1.12);
    o.x = clamp(o.x + moveX * speed * dt, 110, 1120);
    o.y = clamp(o.y + moveY * speed * .38 * dt, 445, 569);
    if (Math.abs(moveX) > .02) o.facing = moveX > 0 ? 1 : -1;
    o.bob += dt * (magnitude > .05 ? 10 : 3);
    if (o.dash > 0) o.x = clamp(o.x + o.facing * 180 * dt, 110, 1120);
    if (state.possession === "opponent" && !state.ball.inFlight) {
      state.ball.x = o.x + o.facing * -27;
      state.ball.y = o.y - 75 + Math.sin(state.elapsed * 10 + 1) * 6;
      state.ball.loose = false;
    }
  }

  function updateShotCharge(dt) {
    if (!state.charging) return;
    state.chargeTime += dt;
    state.charge += state.chargeDir * dt * 1.45;
    if (state.charge >= 1) { state.charge = 1; state.chargeDir = -1; }
    if (state.charge <= .12) { state.charge = .12; state.chargeDir = 1; }
    updateShotMeter();
  }

  function updateBall(dt) {
    const b = state.ball;
    if (!b.inFlight) return;
    const flight = b.flight;
    flight.t += dt / flight.duration;
    const t = clamp(flight.t, 0, 1);
    b.x = lerp(flight.startX, flight.targetX, t);
    const baseY = lerp(flight.startY, flight.targetY, t);
    b.y = baseY - Math.sin(t * Math.PI) * flight.arc;
    b.spin += dt * 16;
    if (flight.t >= 1) {
      b.inFlight = false;
      if (flight.shooter === "player") resolvePlayerShot(flight);
      else resolveOpponentShot(flight);
    }
  }

  function updateLooseBall(dt) {
    const b = state.ball;
    if (!b.loose || b.inFlight) return;
    b.y += dt * 170;
    b.x += b.vx * dt;
    b.vx *= Math.pow(.04, dt);
    b.spin += dt * 14;
    if (b.y > floor.baseline - 25) {
      b.y = floor.baseline - 25;
      b.vy = (b.vy || -110) * -.47;
      b.vx *= .76;
      b.bounces = (b.bounces || 0) + 1;
      if (b.bounces > 2) {
        const pDist = Math.hypot(state.player.x - b.x, state.player.y - b.y);
        const oDist = Math.hypot(state.opponent.x - b.x, state.opponent.y - b.y);
        if (pDist < oDist && pDist < 115) setPossession("player");
        else if (oDist < 115) setPossession("opponent");
      }
    }
    if (b.vy) { b.vy += 320 * dt; b.y += b.vy * dt; }
  }

  function updateOpponentAI(dt) {
    if (state.mode === "duo") return;
    if (state.ball.inFlight) return;
    if (state.possession === "player") {
      if (state.charging && state.opponentDefenseCooldown <= 0) {
        const pressureDistance = distance(state.player, state.opponent);
        if (pressureDistance < 126) {
          state.opponentDefenseCooldown = 1.15;
          const stealChance = .16 + modeData[state.mode].opponentAccuracy * .18;
          if (Math.random() < stealChance) {
            state.charging = false;
            state.chargingShooter = null;
            ui.shotButton.classList.remove("pressed");
            ui.shotHint.textContent = "按住蓄力";
            setPossession("opponent");
            state.player.dash = .16;
            burst(state.opponent.x, state.opponent.y - 62, opponentPresentation[state.mode].color, 9);
            showToast(`${opponentPresentation[state.mode].name} 抓到你的蓄力空檔！`, 1200);
          }
        }
      }
      return;
    }
    if (state.possession !== "opponent" || state.opponentShotCooldown > 0) return;
    state.opponentThink -= dt;
    if (state.opponentThink > 0) return;
    state.opponentThink = 1.6 + Math.random() * 1.6;
    const distanceToHoop = Math.abs(hoop.x - state.opponent.x);
    if (distanceToHoop < 520) {
      state.opponentShotCooldown = 1.25;
      shootForOpponent();
    } else {
      state.opponent.dash = .35;
    }
  }

  function updateEffects(dt) {
    for (const p of state.particles) { p.life -= dt; p.x += p.vx * dt; p.y += p.vy * dt; p.vy += p.gravity * dt; }
    state.particles = state.particles.filter((p) => p.life > 0);
    for (const f of state.floaters) { f.life -= dt; f.y -= dt * 32; }
    state.floaters = state.floaters.filter((f) => f.life > 0);
    for (const r of state.rings) { r.life -= dt; r.radius += dt * r.speed; }
    state.rings = state.rings.filter((r) => r.life > 0);
  }

  function setPossession(who) {
    state.possession = who;
    state.ball.loose = false;
    state.ball.bounces = 0;
    state.ball.vx = 0;
    state.ball.vy = 0;
    if (who === "player") {
      state.ball.x = state.player.x + state.player.facing * 28;
      state.ball.y = state.player.y - 77;
    } else if (who === "opponent") {
      state.ball.x = state.opponent.x + state.opponent.facing * -27;
      state.ball.y = state.opponent.y - 77;
    }
    updateUI(true);
  }

  function beginShot() {
    if (!state.running) { showToast("先按「開始比賽」再上場！", 1300); return; }
    if (state.possession !== "player") { showToast("先把球搶回來！", 1100); return; }
    if (state.ball.inFlight || state.shotCooldown > 0 || state.charging) return;
    state.charging = true;
    state.chargingShooter = "player";
    state.charge = .16;
    state.chargeDir = 1;
    state.chargeTime = 0;
    ui.shotButton.classList.add("pressed");
    ui.shotHint.textContent = "放開出手";
    playTone(320, .05, "sine", .02);
  }

  function beginOpponentShot() {
    if (state.mode !== "duo") return;
    if (!state.running) { showToast("先按「開始比賽」再上場！", 1300); return; }
    if (state.possession !== "opponent") { showToast("P2 先把球搶回來！", 1100); return; }
    if (state.ball.inFlight || state.opponentShotCooldown > 0 || state.charging) return;
    state.charging = true;
    state.chargingShooter = "opponent";
    state.charge = .16;
    state.chargeDir = 1;
    state.chargeTime = 0;
    ui.shotButton.classList.add("pressed", "p2-charge");
    ui.shotHint.textContent = "P2 釋放出手";
    playTone(250, .05, "sine", .02);
  }

  function releaseShot(forceCharge = null) {
    if (!state.charging) return;
    const shooter = state.chargingShooter || "player";
    state.charging = false;
    state.chargingShooter = null;
    ui.shotButton.classList.remove("pressed");
    ui.shotButton.classList.remove("p2-charge");
    ui.shotHint.textContent = "按住蓄力";
    if (shooter === "opponent") {
      if (state.possession !== "opponent" || state.ball.inFlight) return;
      state.opponentShotCooldown = .55;
      launchOpponentShot(forceCharge ?? state.charge);
      return;
    }
    if (state.possession !== "player" || state.ball.inFlight) return;
    const charge = forceCharge ?? state.charge;
    const player = state.player;
    const distanceToHoop = Math.abs(hoop.x - player.x);
    const duration = clamp(.72 + distanceToHoop / 1600, .76, 1.25);
    state.ball.inFlight = true;
    state.ball.loose = false;
    state.ball.flight = { shooter: "player", startX: player.x + player.facing * 24, startY: player.y - 80, targetX: hoop.x, targetY: hoop.rimY - 12, arc: 112 + charge * 45, duration, t: 0, charge, distance: distanceToHoop };
    state.shotShooter = "player";
    state.possession = null;
    state.shotCooldown = .45;
    state.nextShotBonus = 0;
    addFloater(charge >= .61 && charge <= .83 ? "甜蜜點！" : "出手！", player.x, player.y - 129, charge >= .61 && charge <= .83 ? "#9dffc9" : "#d9e8ff");
    playTone(charge >= .61 && charge <= .83 ? 590 : 410, .09, "triangle", .028);
  }

  function shootForOpponent() {
    launchOpponentShot(.72);
  }

  function launchOpponentShot(charge = .72) {
    const o = state.opponent;
    const distanceToHoop = Math.abs(hoop.x - o.x);
    const duration = clamp(.8 + distanceToHoop / 1700, .8, 1.25);
    state.ball.inFlight = true;
    state.ball.loose = false;
    state.ball.flight = { shooter: "opponent", startX: o.x - 24, startY: o.y - 78, targetX: hoop.x, targetY: hoop.rimY - 12, arc: 112 + charge * 38, duration, t: 0, charge, distance: distanceToHoop };
    state.possession = null;
    const opponent = opponentPresentation[state.mode] || opponentPresentation.quick;
    addFloater(`${opponent.name}出手`, o.x, o.y - 126, opponent.color);
    playTone(state.mode === "duo" ? 410 : 285, .08, "sine", .022);
  }

  function resolvePlayerShot(flight) {
    const sweet = 1 - Math.min(1, Math.abs(flight.charge - .72) / .72);
    const distanceBonus = clamp(1 - Math.abs(flight.distance - 540) / 800, .35, 1);
    const data = characterData[state.character] || characterData.white;
    const shotBonus = (data.stats[1] - 76) * .0035;
    const threeBonus = flight.distance > 540 ? (data.stats[2] - 68) * .0025 : 0;
    const chance = clamp(.18 + sweet * .68 + distanceBonus * .08 + shotBonus + threeBonus + state.nextShotBonus, .08, .96);
    const made = sweet > .84 || Math.random() < chance;
    if (made) {
      const points = flight.distance > 540 ? 3 : 2;
      state.score.player += points;
      state.energy = clamp(state.energy + 12, 0, 100);
      state.screenShake = .24;
      state.rings.push({ x: hoop.x, y: hoop.rimY, radius: 22, speed: 115, life: .7, maxLife: .7, color: points === 3 ? "#74c9ff" : "#ffd36d" });
      burst(hoop.x, hoop.rimY, points === 3 ? "#86d4ff" : "#ffd36d", points === 3 ? 28 : 20);
      addFloater(`+${points}  ${points === 3 ? "三分命中！" : "漂亮！"}`, hoop.x - 40, hoop.rimY - 50, points === 3 ? "#9edcff" : "#ffe09a");
      showToast(points === 3 ? "🌟 三分命中！" : "🏀 兩分拿下！", 1800);
      playTone(points === 3 ? 780 : 660, .17, "triangle", .042);
      resetAfterScore("opponent");
    } else {
      addFloater("籃框彈出", hoop.x - 30, hoop.rimY - 40, "#ffb1b1");
      showToast("差一點！調整蓄力再試一次。", 1400);
      playTone(190, .1, "sawtooth", .02);
      makeLooseBall(hoop.x - 12, hoop.rimY + 12, -145, -205);
    }
  }

  function resolveOpponentShot(flight) {
    const opponentData = characterData.calico || characterData.white;
    const sweet = 1 - Math.min(1, Math.abs(flight.charge - .72) / .72);
    const distanceBonus = clamp(1 - Math.abs(flight.distance - 540) / 800, .35, 1);
    const humanChance = clamp(.18 + sweet * .68 + distanceBonus * .08 + (opponentData.stats[1] - 76) * .0035 + (flight.distance > 540 ? (opponentData.stats[2] - 68) * .0025 : 0), .08, .96);
    const chance = state.mode === "duo" ? humanChance : modeData[state.mode].opponentAccuracy;
    const opponent = opponentPresentation[state.mode] || opponentPresentation.quick;
    const made = Math.random() < chance;
    if (made) {
      const points = flight.distance > 540 ? 3 : 2;
      state.score.opponent += points;
      state.screenShake = .18;
      state.rings.push({ x: hoop.x, y: hoop.rimY, radius: 22, speed: 110, life: .6, maxLife: .6, color: "#ff8e9a" });
      burst(hoop.x, hoop.rimY, "#ff94a6", 16);
      addFloater(`${opponent.name} +${points}`, hoop.x - 45, hoop.rimY - 48, opponent.color);
      showToast(`${opponent.name}命中 ${points} 分`, 1500);
      playTone(330, .14, "sine", .03);
      resetAfterScore("player");
    } else {
      makeLooseBall(hoop.x - 12, hoop.rimY + 12, -120, -180);
      showToast("對手投丟了，快搶籃板！", 1200);
    }
  }

  function makeLooseBall(x, y, vx, vy) {
    state.ball.x = x;
    state.ball.y = y;
    state.ball.vx = vx;
    state.ball.vy = vy;
    state.ball.bounces = 0;
    state.ball.loose = true;
    state.ball.inFlight = false;
    state.possession = null;
  }

  function resetAfterScore(nextPossession) {
    state.ball.inFlight = false;
    state.ball.loose = false;
    state.player.x = 355;
    state.player.y = 542;
    state.opponent.x = 808;
    state.opponent.y = 535;
    setPossession(nextPossession);
  }

  function attemptSteal() {
    if (!state.running) { showToast("先開始比賽！", 1100); return; }
    if (state.possession !== "opponent") { showToast("現在是你的球權，往籃框切入！", 1100); return; }
    const near = distance(state.player, state.opponent) < 145;
    if (!near) {
      const opponent = opponentPresentation[state.mode] || opponentPresentation.quick;
      showToast(`靠近${opponent.name}再按抄球`, 1200);
      return;
    }
    state.player.dash = .18;
    state.player.stamina = Math.max(0, state.player.stamina - 8);
    const defenseStat = characterData[state.character]?.stats?.[3] ?? 58;
    const stealChance = clamp(.68 + (defenseStat - 58) * .004, .52, .84);
    if (Math.random() < stealChance) {
      setPossession("player");
      state.energy = clamp(state.energy + 8, 0, 100);
      burst(state.opponent.x, state.opponent.y - 60, "#75e7a9", 10);
      addFloater("抄球成功！", state.player.x, state.player.y - 125, "#9dffc4");
      showToast("✋ 抄球成功！", 1300);
      playTone(620, .1, "square", .025);
    } else {
      addFloater("被晃開了", state.player.x, state.player.y - 116, "#ffb7b7");
      showToast("差一點，抓準時機！", 1100);
      playTone(180, .08, "sawtooth", .018);
    }
  }

  function attemptOpponentSteal() {
    if (state.mode !== "duo") return;
    if (!state.running) { showToast("先開始比賽！", 1100); return; }
    if (state.possession !== "player") { showToast("P2 需要等 P1 持球時抄球", 1100); return; }
    if (state.charging && state.chargingShooter === "player") {
      state.charging = false;
      state.chargingShooter = null;
      ui.shotButton.classList.remove("pressed");
      ui.shotHint.textContent = "按住蓄力";
    }
    const near = distance(state.player, state.opponent) < 145;
    if (!near) { showToast("P2 靠近 P1 再按 / 抄球", 1200); return; }
    state.opponent.dash = .18;
    const defenseStat = characterData.calico?.stats?.[3] ?? 52;
    const stealChance = clamp(.64 + (defenseStat - 52) * .004, .50, .82);
    if (Math.random() < stealChance) {
      setPossession("opponent");
      burst(state.player.x, state.player.y - 60, opponentPresentation.duo.color, 10);
      addFloater("P2 抄球成功！", state.opponent.x, state.opponent.y - 125, "#ffb8c4");
      showToast("P2 ✋ 抄球成功！", 1300);
      playTone(380, .1, "square", .025);
    } else {
      addFloater("P2 被晃開了", state.opponent.x, state.opponent.y - 116, "#ffb7b7");
      showToast("P2 抄球失敗，抓準時機！", 1100);
      playTone(160, .08, "sawtooth", .018);
    }
  }

  function performPass() {
    if (!state.running) { showToast("先開始比賽！", 1100); return; }
    if (state.possession !== "player" || state.ball.inFlight) { showToast("先把球控好再傳球", 1100); return; }
    const direction = state.player.facing || 1;
    state.player.x = clamp(state.player.x + direction * 58, 110, 1015);
    state.player.dash = .24;
    state.player.stamina = Math.max(0, state.player.stamina - 4);
    state.energy = clamp(state.energy + 3, 0, 100);
    burst(state.player.x + direction * 20, state.player.y - 65, "#b387ff", 7);
    addFloater("假傳變向！", state.player.x, state.player.y - 117, "#d1b7ff");
    showToast("🤝 假傳變向，甩開防守！", 1200);
    playTone(480, .07, "triangle", .02);
  }

  function triggerSkill(skillName) {
    if (!state.running) { showToast("先開始比賽！", 1100); return; }
    const costs = { "火焰灌籃": 34, "後撤步三分": 28, "幻影變向": 22, "流星投籃": 40 };
    const cost = costs[skillName] || 25;
    if (state.energy < cost) { showToast(`能量不足，需要 ${cost}%`, 1200); return; }
    state.energy -= cost;
    state.skillFlash = skillName;
    state.skillFlashTime = .75;
    const p = state.player;
    if (skillName === "火焰灌籃") {
      p.dash = .6;
      p.x = clamp(hoop.x - 170, 130, 1015);
      burst(p.x, p.y - 70, "#ff9e4c", 22);
      if (state.possession === "player") {
        state.ball.inFlight = true;
        state.possession = null;
        state.ball.flight = { shooter: "player", startX: p.x + 25, startY: p.y - 78, targetX: hoop.x, targetY: hoop.rimY - 13, arc: 100, duration: .68, t: 0, charge: .74, distance: Math.abs(hoop.x - p.x), special: true };
        state.shotCooldown = .4;
      }
      showToast("🔥 火焰灌籃！", 1500);
      playTone(160, .2, "sawtooth", .035);
    } else if (skillName === "後撤步三分") {
      p.x = clamp(p.x - 110, 120, 1015);
      p.dash = .25;
      state.nextShotBonus = .2;
      burst(p.x, p.y - 58, "#72d8ff", 14);
      addFloater("三分加成 +25%", p.x, p.y - 123, "#9fe2ff");
      showToast("💠 後撤步完成！下一球命中率提升", 1700);
      playTone(690, .16, "triangle", .035);
    } else if (skillName === "幻影變向") {
      p.dash = .65;
      p.x = clamp(p.x + p.facing * 160, 120, 1015);
      burst(p.x, p.y - 56, "#c59bff", 18);
      addFloater("幻影消失！", p.x, p.y - 122, "#e0c8ff");
      showToast("🌀 幻影變向！防守失去目標", 1500);
      playTone(530, .16, "sine", .03);
    } else {
      if (state.possession === "player" && !state.ball.inFlight) releaseShot(.72);
      showToast("☄️ 流星投籃！", 1500);
      burst(p.x, p.y - 85, "#ff9de8", 19);
      playTone(840, .2, "triangle", .04);
    }
    updateUI(true);
  }

  function setMode(mode) {
    if (!modeData[mode]) return;
    if (state.running) {
      showToast("請先暫停比賽，再切換模式。", 1200, false);
      return;
    }
    document.querySelectorAll(".mode-card").forEach((button) => button.classList.toggle("active", button.dataset.mode === mode));
    state.mode = mode;
    state.modeName = modeData[mode].name;
    ui.matchLabel.textContent = modeData[mode].label;
    updateControlsUI();
    resetGame();
    showToast(`已切換至${modeData[mode].name}`, 1300, false);
  }

  function updateControlsUI() {
    const duo = state.mode === "duo";
    const hint = $("desktopHint");
    if (hint) {
      hint.innerHTML = duo
        ? "<kbd>WASD</kbd> P1 移動　 <kbd>Space</kbd> P1 投籃　 <kbd>X</kbd> P1 抄球　 <kbd>↑↓←→</kbd> P2 移動　 <kbd>Enter</kbd> P2 投籃　 <kbd>/</kbd> P2 抄球"
        : "<kbd>WASD</kbd> 移動　 <kbd>Space</kbd> 蓄力投籃　 <kbd>Shift</kbd> 衝刺";
    }
    const duoPanel = document.querySelector(".mode-duo");
    duoPanel?.classList.toggle("active", duo);
    const duoButton = duoPanel?.querySelector("button");
    if (duoButton) duoButton.textContent = duo ? "已選擇　✓" : "開始　›";
    const helpItems = document.querySelectorAll("#helpGrid > div");
    const helpControls = duo
      ? [["W A S D", "P1 移動"], ["Space", "P1 蓄力投籃"], ["↑ ↓ ← →", "P2 移動"], ["Enter / /", "P2 投籃／抄球"]]
      : [["W A S D", "移動喵白白"], ["Space", "按住蓄力，放開出手"], ["Shift", "消耗體力衝刺"], ["Q / E / R / F", "施放必殺技能"]];
    helpItems.forEach((item, index) => {
      if (!helpControls[index]) return;
      const key = item.querySelector("kbd");
      const title = item.querySelector("strong");
      if (key) key.textContent = helpControls[index][0];
      if (title) title.textContent = helpControls[index][1];
    });
    const helpDescription = $("helpDescription");
    if (helpDescription) helpDescription.textContent = duo
      ? "雙人模式共用同一球場：P1 用 WASD／Space／X，P2 用方向鍵／Enter／/；投失後靠近籃板取得下一回合。"
      : "手機玩家可以使用畫面上的搖桿和動作按鈕。投籃時讓指針停在綠色區域，會更容易命中。";
  }

  function selectCharacter(character) {
    if (!characterData[character]) return;
    state.character = character;
    document.querySelectorAll(".character-tab").forEach((tab) => tab.classList.toggle("active", tab.dataset.character === character));
    const data = characterData[character];
    $("characterName").textContent = data.name;
    $("characterRole").textContent = data.role;
    $("characterBio").textContent = data.bio;
    const stage = $("stageCat");
    const stageImage = $("stageCatImage");
    stageImage.src = data.asset;
    stageImage.alt = data.name;
    stage.dataset.number = data.number;
    ui.playerAvatar.src = data.asset;
    ui.playerAvatar.alt = data.name;
    ui.playerName.textContent = `P1 · ${data.name}`;
    ui.playerTeam.textContent = data.role.split("·")[0].trim();
    const playerAvatarBackground = {
      red: "linear-gradient(150deg, #ff8e83, #9f3c68)",
      teal: "linear-gradient(150deg, #36d7ce, #167897)",
      purple: "linear-gradient(150deg, #b07bff, #4b2a8d)",
      blue: "linear-gradient(150deg, #4e97fb, #2d4abb)",
    };
    ui.playerAvatar.parentElement.style.background = playerAvatarBackground[data.color] || playerAvatarBackground.blue;
    ui.playerStatusAvatar.src = data.asset;
    ui.playerStatusAvatar.alt = data.name;
    ui.statusPlayerName.textContent = data.name;
    ui.statusPlayerRole.textContent = data.role.replace(/^[^·]+·\s*/, "");
    const stageBackground = {
      red: "linear-gradient(145deg, #ff8e83, #9f3c68)",
      teal: "linear-gradient(145deg, #36d7ce, #167897)",
      purple: "linear-gradient(145deg, #b07bff, #4b2a8d)",
      blue: "linear-gradient(145deg, #4e97fb, #2d4abb)",
    };
    stage.style.background = stageBackground[data.color] || stageBackground.blue;
    ["statSpeed", "statShot", "statThree", "statDefense"].forEach((id, index) => {
      $(id).style.width = `${data.stats[index]}%`;
    });
    ["starsSpeed", "starsShot", "starsThree", "starsDefense"].forEach((id, index) => {
      $(id).textContent = data.stars[index];
    });
    showToast(`${data.name} 已上場`, 900, false);
  }

  function updateShotMeter() {
    const pct = Math.round(state.charge * 100);
    ui.shotButton.style.setProperty("--charge", `${pct}%`);
    ui.shotHint.textContent = `${state.chargingShooter === "opponent" ? "P2 " : ""}${pct}% · 放開出手`;
  }

  function updateUI(force = false) {
    scoreEls.player.textContent = String(state.score.player).padStart(2, "0");
    scoreEls.opponent.textContent = String(state.score.opponent).padStart(2, "0");
    const opponent = opponentPresentation[state.mode] || opponentPresentation.quick;
    const player = characterData[state.character] || characterData.white;
    ui.opponentName.textContent = `P2 · ${opponent.name}`;
    ui.opponentTeam.textContent = opponent.team;
    ui.opponentAvatar.src = opponent.asset;
    ui.opponentAvatar.alt = opponent.name;
    ui.opponentAvatar.parentElement.style.background = `linear-gradient(150deg, ${opponent.color}, #24345f)`;
    ui.playerName.textContent = `P1 · ${player.name}`;
    ui.playerTeam.textContent = player.role.split("·")[0].trim();
    ui.timer.textContent = formatTime(state.timeLeft);
    ui.period.textContent = String(state.period);
    if (state.running) ui.status.textContent = state.charging ? `${state.chargingShooter === "opponent" ? "P2" : "P1"} 蓄力瞄準中` : (state.possession === "player" ? "進攻回合" : state.possession === "opponent" ? "防守回合" : "爭搶籃板");
    ui.possession.textContent = state.possession === "player" ? "P1 持球" : state.possession === "opponent" ? "P2 持球" : "球在空中";
    ui.possession.style.color = state.possession === "opponent" ? "#ffadb8" : state.possession === "player" ? "#79e4ac" : "#ffd486";
    ui.possession.style.borderColor = state.possession === "opponent" ? "rgba(255, 115, 132, .3)" : state.possession === "player" ? "rgba(83, 224, 161, .26)" : "rgba(255, 198, 93, .3)";
    ui.possession.style.background = state.possession === "opponent" ? "rgba(255, 91, 104, .12)" : state.possession === "player" ? "rgba(63, 215, 143, .12)" : "rgba(255, 193, 82, .11)";
    const energy = Math.round(state.energy);
    ui.energyValue.textContent = String(energy);
    ui.energyBar.style.width = `${energy}%`;
    ui.energyText.textContent = `${energy}%`;
    const stamina = Math.round(state.player.stamina);
    ui.staminaBar.style.width = `${stamina}%`;
    ui.staminaText.textContent = `${stamina}/100`;
    if (state.charging) updateShotMeter();
    ui.shotButton.classList.toggle("ready", state.running && state.possession === "player" && !state.ball.inFlight && !state.charging);
    if (force) draw();
  }

  /* ------------------------------ canvas drawing ------------------------------ */

  function draw() {
    ctx.save();
    if (state.screenShake > 0) ctx.translate((Math.random() - .5) * 5 * state.screenShake / .24, (Math.random() - .5) * 4 * state.screenShake / .24);
    if (generatedArt.court.complete && generatedArt.court.naturalWidth > 0) {
      ctx.drawImage(generatedArt.court, 0, 0, W, H);
      ctx.fillStyle = "rgba(4, 11, 31, .10)";
      ctx.fillRect(0, 0, W, H);
    } else {
      drawSky();
      drawCourt();
    }
    if (!state.running && !state.gameOver && generatedArt.protagonistGroup.complete && generatedArt.protagonistGroup.naturalWidth > 0) {
      // Show the full cast on the ready screen only; gameplay keeps the live
      // sprites unobstructed while the transparent plate acts as a hero lineup.
      ctx.save();
      ctx.globalAlpha = .28;
      ctx.drawImage(generatedArt.protagonistGroup, 112, 196, 670, 377);
      ctx.restore();
    }
    drawHoop();
    drawAimGuide();
    drawPlayers();
    drawBall();
    drawEffects();
    drawCanvasOverlay();
    ctx.restore();
  }

  function drawSky() {
    const gradient = ctx.createLinearGradient(0, 0, 0, floor.horizon + 40);
    gradient.addColorStop(0, "#07112d"); gradient.addColorStop(.48, "#132b58"); gradient.addColorStop(1, "#244b6a");
    ctx.fillStyle = gradient; ctx.fillRect(0, 0, W, H);
    const moon = ctx.createRadialGradient(1000, 92, 2, 1000, 92, 58);
    moon.addColorStop(0, "rgba(255,245,205,.96)"); moon.addColorStop(.22, "rgba(255,229,166,.35)"); moon.addColorStop(1, "rgba(255,222,155,0)");
    ctx.fillStyle = moon; ctx.beginPath(); ctx.arc(1000, 92, 64, 0, TAU); ctx.fill();
    ctx.fillStyle = "#fff3c1"; ctx.beginPath(); ctx.arc(1000, 92, 20, 0, TAU); ctx.fill();
    ctx.fillStyle = "rgba(219, 234, 255, .72)";
    for (let i = 0; i < 38; i += 1) { const x = (i * 97) % W; const y = 30 + ((i * 53) % 170); const r = i % 5 === 0 ? 1.7 : .8; ctx.globalAlpha = .35 + (i % 4) * .12; ctx.beginPath(); ctx.arc(x, y, r, 0, TAU); ctx.fill(); }
    ctx.globalAlpha = 1;

    skyline.forEach(([x, width, height], index) => {
      const y = floor.horizon - height;
      const building = ctx.createLinearGradient(0, y, 0, floor.horizon + 5);
      building.addColorStop(0, index % 2 ? "#172f59" : "#132746"); building.addColorStop(1, "#10213e");
      ctx.fillStyle = building; ctx.fillRect(x, y, width, height + 20);
      ctx.fillStyle = "rgba(255, 202, 111, .58)";
      for (let row = 0; row < Math.floor(height / 23); row += 1) for (let col = 0; col < Math.max(1, Math.floor(width / 18)); col += 1) {
        if ((row * 3 + col + index) % 4 === 0) ctx.fillRect(x + 9 + col * 17, y + 13 + row * 22, 5, 7);
      }
    });
    const haze = ctx.createLinearGradient(0, floor.horizon - 38, 0, floor.horizon + 45);
    haze.addColorStop(0, "rgba(59, 128, 161, .04)"); haze.addColorStop(1, "rgba(112, 192, 195, .23)");
    ctx.fillStyle = haze; ctx.fillRect(0, floor.horizon - 40, W, 85);

    ctx.strokeStyle = "rgba(164, 203, 234, .28)"; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.moveTo(0, floor.horizon + 16); ctx.lineTo(W, floor.horizon + 16); ctx.stroke();
    ctx.strokeStyle = "rgba(182, 216, 240, .16)"; ctx.lineWidth = 1;
    for (let x = 0; x < W; x += 42) { ctx.beginPath(); ctx.moveTo(x, floor.horizon + 17); ctx.lineTo(x, floor.horizon + 74); ctx.stroke(); }
  }

  function drawCourt() {
    const gradient = ctx.createLinearGradient(0, floor.horizon, 0, H);
    gradient.addColorStop(0, "#9d7658"); gradient.addColorStop(.16, "#b58a63"); gradient.addColorStop(1, "#4b3040");
    ctx.fillStyle = gradient; ctx.fillRect(0, floor.horizon + 58, W, H - floor.horizon);
    ctx.save();
    ctx.globalAlpha = .16;
    for (let i = 0; i < 13; i += 1) {
      const y = floor.horizon + 67 + i * 32;
      ctx.strokeStyle = i % 2 ? "#ffe0a6" : "#2a1930"; ctx.lineWidth = i % 2 ? 2 : 1;
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y + 18); ctx.stroke();
    }
    for (let x = -160; x < W + 160; x += 116) { ctx.strokeStyle = "rgba(255, 235, 190, .2)"; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(x, floor.horizon + 55); ctx.lineTo(x + 95, H); ctx.stroke(); }
    ctx.restore();
    // back court / key
    ctx.save();
    ctx.strokeStyle = "rgba(255, 243, 220, .75)"; ctx.lineWidth = 4; ctx.lineCap = "round";
    ctx.beginPath(); ctx.moveTo(1010, floor.baseline + 2); ctx.lineTo(1010, floor.horizon + 65); ctx.lineTo(1240, floor.horizon + 65); ctx.lineTo(1240, floor.baseline + 2); ctx.stroke();
    ctx.beginPath(); ctx.arc(1010, floor.baseline - 2, 95, -Math.PI / 2, Math.PI / 2); ctx.stroke();
    ctx.beginPath(); ctx.arc(690, floor.baseline, 100, Math.PI, TAU); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(690, floor.horizon + 65); ctx.lineTo(690, floor.baseline + 3); ctx.stroke();
    ctx.beginPath(); ctx.arc(690, floor.baseline - 4, 48, 0, TAU); ctx.stroke();
    ctx.strokeStyle = "rgba(255, 236, 200, .33)"; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.arc(1010, floor.baseline, 177, -Math.PI / 2, Math.PI / 2); ctx.stroke();
    ctx.restore();
    // fence
    ctx.save();
    ctx.strokeStyle = "rgba(20, 36, 58, .7)"; ctx.lineWidth = 2;
    for (let x = 15; x < W; x += 18) { ctx.beginPath(); ctx.moveTo(x, floor.horizon + 16); ctx.lineTo(x + 58, floor.horizon + 138); ctx.stroke(); ctx.beginPath(); ctx.moveTo(x + 58, floor.horizon + 16); ctx.lineTo(x, floor.horizon + 138); ctx.stroke(); }
    ctx.strokeStyle = "rgba(201, 223, 241, .35)"; ctx.lineWidth = 3;
    [floor.horizon + 17, floor.horizon + 77, floor.horizon + 136].forEach((y) => { ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke(); });
    ctx.restore();
    // court lights / graffiti accents
    ctx.save();
    ctx.globalAlpha = .62; ctx.fillStyle = "#3d3148"; roundRect(ctx, 76, floor.horizon + 73, 148, 52, 8); ctx.fill();
    ctx.fillStyle = "#e7ae76"; ctx.font = "900 22px system-ui"; ctx.rotate(-.08); ctx.fillText("PAW", 91, floor.horizon + 109); ctx.fillText("HOOPS", 124, floor.horizon + 130);
    ctx.restore();
    // court side lights
    [80, 530, 1185].forEach((x, i) => {
      ctx.strokeStyle = "rgba(31, 47, 70, .9)"; ctx.lineWidth = 7; ctx.beginPath(); ctx.moveTo(x, floor.horizon - 100); ctx.lineTo(x, floor.horizon + 57); ctx.stroke();
      const glow = ctx.createRadialGradient(x, floor.horizon - 103, 2, x, floor.horizon - 103, 55);
      glow.addColorStop(0, "rgba(255,239,185,.68)"); glow.addColorStop(1, "rgba(255,226,151,0)"); ctx.fillStyle = glow; ctx.beginPath(); ctx.arc(x, floor.horizon - 103, 58, 0, TAU); ctx.fill();
      ctx.fillStyle = "#fff1bd"; ctx.beginPath(); ctx.ellipse(x, floor.horizon - 105, 17, 7, 0, 0, TAU); ctx.fill();
      if (i === 1) { ctx.strokeStyle = "rgba(32, 45, 69, .9)"; ctx.lineWidth = 4; ctx.beginPath(); ctx.moveTo(x, floor.horizon - 101); ctx.lineTo(x - 31, floor.horizon - 75); ctx.stroke(); }
    });
  }

  function drawHoop() {
    ctx.save();
    // backboard support
    ctx.strokeStyle = "rgba(29, 42, 57, .88)"; ctx.lineWidth = 11; ctx.beginPath(); ctx.moveTo(1130, floor.horizon + 72); ctx.lineTo(1130, 183); ctx.lineTo(1068, 157); ctx.stroke();
    ctx.fillStyle = "rgba(213, 229, 237, .84)"; ctx.strokeStyle = "rgba(29, 39, 61, .8)"; ctx.lineWidth = 5;
    ctx.beginPath(); ctx.moveTo(1020, 166); ctx.lineTo(1120, 140); ctx.lineTo(1120, 300); ctx.lineTo(1019, 325); ctx.closePath(); ctx.fill(); ctx.stroke();
    ctx.strokeStyle = "rgba(35, 50, 76, .8)"; ctx.lineWidth = 4; ctx.strokeRect(1039, 205, 63, 63);
    // rim glow
    const glow = ctx.createRadialGradient(hoop.x, hoop.rimY, 2, hoop.x, hoop.rimY, 58); glow.addColorStop(0, "rgba(255, 176, 61, .5)"); glow.addColorStop(1, "rgba(255, 145, 34, 0)"); ctx.fillStyle = glow; ctx.beginPath(); ctx.arc(hoop.x, hoop.rimY, 58, 0, TAU); ctx.fill();
    ctx.strokeStyle = "#e56f26"; ctx.lineWidth = 7; ctx.beginPath(); ctx.ellipse(hoop.x, hoop.rimY, 35, 9, 0, 0, TAU); ctx.stroke();
    ctx.strokeStyle = "rgba(250, 235, 224, .8)"; ctx.lineWidth = 2;
    for (let i = -3; i <= 3; i += 1) { ctx.beginPath(); ctx.moveTo(hoop.x + i * 9, hoop.rimY + 4); ctx.lineTo(hoop.x + i * 6, hoop.rimY + 48); ctx.stroke(); }
    ctx.beginPath(); ctx.moveTo(hoop.x - 34, hoop.rimY + 4); ctx.quadraticCurveTo(hoop.x, hoop.rimY + 59, hoop.x + 34, hoop.rimY + 4); ctx.stroke();
    ctx.restore();
  }

  function drawAimGuide() {
    if (!state.charging || state.possession !== "player") return;
    const startX = state.player.x + state.player.facing * 28;
    const startY = state.player.y - 80;
    ctx.save();
    ctx.setLineDash([5, 10]); ctx.lineWidth = 2; ctx.strokeStyle = "rgba(191, 225, 255, .55)";
    ctx.beginPath(); ctx.moveTo(startX, startY); ctx.quadraticCurveTo((startX + hoop.x) / 2, startY - 180 - state.charge * 40, hoop.x, hoop.rimY - 12); ctx.stroke(); ctx.setLineDash([]);
    const aim = ctx.createRadialGradient(hoop.x, hoop.rimY, 4, hoop.x, hoop.rimY, 37); aim.addColorStop(0, `rgba(103, 237, 164, ${.13 + state.charge * .2})`); aim.addColorStop(1, "rgba(103, 237, 164, 0)"); ctx.fillStyle = aim; ctx.beginPath(); ctx.arc(hoop.x, hoop.rimY, 38, 0, TAU); ctx.fill();
    // in-canvas power meter
    const meterX = state.player.x - 51; const meterY = state.player.y - 171; const meterW = 102; const meterH = 9;
    roundRect(ctx, meterX, meterY, meterW, meterH, 5); ctx.fillStyle = "rgba(6, 15, 34, .82)"; ctx.fill();
    const fill = ctx.createLinearGradient(meterX, 0, meterX + meterW, 0); fill.addColorStop(0, "#4abfd9"); fill.addColorStop(.62, "#72e49d"); fill.addColorStop(.82, "#ffd467"); fill.addColorStop(1, "#ed6d67"); roundRect(ctx, meterX + 2, meterY + 2, (meterW - 4) * state.charge, meterH - 4, 3); ctx.fillStyle = fill; ctx.fill();
    ctx.fillStyle = "rgba(246, 255, 242, .8)"; ctx.font = "800 10px system-ui"; ctx.textAlign = "center"; ctx.fillText("POWER", meterX + meterW / 2, meterY - 7); ctx.textAlign = "left";
    ctx.restore();
  }

  function drawPlayers() {
    drawCat(state.player.x, state.player.y, "blue", state.player.facing, state.player.bob, state.possession === "player");
    const opponent = opponentPresentation[state.mode] || opponentPresentation.quick;
    drawCat(state.opponent.x, state.opponent.y, "opponent", state.opponent.facing, state.opponent.bob, state.possession === "opponent");
    drawPlayerTag(state.player.x, state.player.y - 169, "P1", "#4ba4ff", state.possession === "player");
    drawPlayerTag(state.opponent.x, state.opponent.y - 169, "P2", opponent.color, state.possession === "opponent");
  }

  function drawPlayerTag(x, y, text, color, active) {
    ctx.save(); ctx.globalAlpha = active ? 1 : .68; ctx.fillStyle = color; roundRect(ctx, x - 19, y, 38, 22, 7); ctx.fill(); ctx.fillStyle = "#fff"; ctx.font = "900 11px system-ui"; ctx.textAlign = "center"; ctx.fillText(text, x, y + 15); ctx.beginPath(); ctx.moveTo(x - 5, y + 22); ctx.lineTo(x, y + 29); ctx.lineTo(x + 5, y + 22); ctx.closePath(); ctx.fill(); ctx.restore();
  }

  function drawCat(x, groundY, team, facing, bob, active) {
    const isBlue = team === "blue";
    const opponent = opponentPresentation[state.mode] || opponentPresentation.quick;
    const main = isBlue ? "#2f75df" : opponent.color;
    const light = isBlue ? "#75bdff" : opponent.color;
    const dark = isBlue ? "#19336f" : "#35234f";
    const skin = isBlue ? "#fff7ec" : "#f9eee0";
    const bounce = Math.sin(bob) * (active ? 2.8 : 1.3);
    ctx.save(); ctx.translate(x, groundY + bounce); ctx.scale(facing, 1);
    // shadow
    ctx.globalAlpha = .35; ctx.fillStyle = "#111021"; ctx.beginPath(); ctx.ellipse(0, 5, 48, 10, 0, 0, TAU); ctx.fill(); ctx.globalAlpha = 1;
    const playerArt = state.character === "calico" ? generatedArt.opponent : state.character === "orange" ? generatedArt.storyOpponent : state.character === "boss" ? generatedArt.bossOpponent : generatedArt.player;
    const generatedCat = isBlue ? playerArt : (state.mode === "story" ? generatedArt.storyOpponent : state.mode === "boss" ? generatedArt.bossOpponent : generatedArt.opponent);
    if (generatedCat.complete && generatedCat.naturalWidth > 0) {
      ctx.drawImage(generatedCat, -112, -240, 224, 240);
      if (active) {
        ctx.strokeStyle = isBlue ? "rgba(98, 204, 255, .9)" : rgba(opponent.color, .9);
        ctx.lineWidth = 2;
        ctx.setLineDash([3, 4]);
        ctx.beginPath(); ctx.ellipse(0, -112, 119, 122, 0, 0, TAU); ctx.stroke();
        ctx.setLineDash([]);
      }
      ctx.restore();
      return;
    }
    // tail
    ctx.strokeStyle = skin; ctx.lineWidth = 13; ctx.lineCap = "round"; ctx.beginPath(); ctx.moveTo(-31, -72); ctx.bezierCurveTo(-69, -101, -64, -145, -29, -137); ctx.stroke(); ctx.strokeStyle = dark; ctx.lineWidth = 5; ctx.beginPath(); ctx.moveTo(-31, -72); ctx.bezierCurveTo(-69, -101, -64, -145, -29, -137); ctx.stroke();
    // legs and shoes
    ctx.fillStyle = skin; roundRect(ctx, -25, -45, 16, 37, 7); ctx.fill(); roundRect(ctx, 9, -45, 16, 37, 7); ctx.fill();
    ctx.fillStyle = dark; roundRect(ctx, -31, -15, 29, 13, 6); ctx.fill(); roundRect(ctx, 6, -15, 29, 13, 6); ctx.fill();
    ctx.fillStyle = "rgba(255,255,255,.55)"; ctx.fillRect(-25, -13, 17, 3); ctx.fillRect(12, -13, 17, 3);
    // body / jersey
    ctx.fillStyle = main; ctx.beginPath(); ctx.moveTo(-34, -116); ctx.quadraticCurveTo(0, -128, 34, -116); ctx.lineTo(28, -49); ctx.quadraticCurveTo(0, -38, -28, -49); ctx.closePath(); ctx.fill();
    ctx.strokeStyle = "rgba(255,255,255,.48)"; ctx.lineWidth = 3; ctx.beginPath(); ctx.moveTo(-28, -112); ctx.lineTo(-23, -51); ctx.moveTo(28, -112); ctx.lineTo(23, -51); ctx.stroke();
    ctx.fillStyle = "rgba(255,255,255,.88)"; ctx.font = "900 18px system-ui"; ctx.textAlign = "center"; ctx.fillText("23", 0, -75);
    // arms
    ctx.strokeStyle = skin; ctx.lineWidth = 13; ctx.lineCap = "round"; ctx.beginPath(); ctx.moveTo(28, -105); ctx.quadraticCurveTo(43, -87, 49, -69); ctx.stroke(); ctx.beginPath(); ctx.moveTo(-28, -105); ctx.quadraticCurveTo(-44, -86, -50, -76); ctx.stroke();
    // head + ears
    ctx.fillStyle = skin; ctx.beginPath(); ctx.arc(0, -145, 32, 0, TAU); ctx.fill();
    ctx.fillStyle = skin; ctx.beginPath(); ctx.moveTo(-27, -164); ctx.lineTo(-23, -196); ctx.lineTo(-3, -171); ctx.closePath(); ctx.fill(); ctx.beginPath(); ctx.moveTo(27, -164); ctx.lineTo(23, -196); ctx.lineTo(3, -171); ctx.closePath(); ctx.fill();
    ctx.fillStyle = isBlue ? "#f3a0a8" : "#e9a78e"; ctx.beginPath(); ctx.moveTo(-22, -169); ctx.lineTo(-20, -187); ctx.lineTo(-8, -172); ctx.closePath(); ctx.fill(); ctx.beginPath(); ctx.moveTo(22, -169); ctx.lineTo(20, -187); ctx.lineTo(8, -172); ctx.closePath(); ctx.fill();
    // hair / patch
    ctx.fillStyle = isBlue ? "#d4e6ff" : "#4e2b32"; ctx.beginPath(); ctx.arc(0, -165, 27, Math.PI, TAU); ctx.quadraticCurveTo(8, -179, 17, -163); ctx.quadraticCurveTo(0, -174, -16, -163); ctx.closePath(); ctx.fill();
    if (!isBlue) { ctx.fillStyle = "#f28b3c"; ctx.beginPath(); ctx.moveTo(4, -180); ctx.lineTo(17, -168); ctx.lineTo(6, -159); ctx.closePath(); ctx.fill(); }
    // eyes
    ctx.fillStyle = "#1a1b2d"; ctx.beginPath(); ctx.ellipse(-11, -148, 5, 7, 0, 0, TAU); ctx.fill(); ctx.beginPath(); ctx.ellipse(11, -148, 5, 7, 0, 0, TAU); ctx.fill(); ctx.fillStyle = "#fff"; ctx.beginPath(); ctx.arc(-9, -151, 1.7, 0, TAU); ctx.arc(13, -151, 1.7, 0, TAU); ctx.fill();
    ctx.fillStyle = "#ec8c8c"; ctx.beginPath(); ctx.moveTo(-3, -136); ctx.lineTo(3, -136); ctx.lineTo(0, -131); ctx.closePath(); ctx.fill(); ctx.strokeStyle = "rgba(89, 46, 61, .6)"; ctx.lineWidth = 1.4; ctx.beginPath(); ctx.moveTo(0, -131); ctx.quadraticCurveTo(-5, -126, -10, -129); ctx.moveTo(0, -131); ctx.quadraticCurveTo(5, -126, 10, -129); ctx.stroke();
    // whiskers
    ctx.strokeStyle = "rgba(255,255,255,.64)"; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(-9, -136); ctx.lineTo(-39, -142); ctx.moveTo(-8, -132); ctx.lineTo(-40, -132); ctx.moveTo(9, -136); ctx.lineTo(39, -142); ctx.moveTo(8, -132); ctx.lineTo(40, -132); ctx.stroke();
    if (active) { ctx.strokeStyle = isBlue ? "rgba(98, 204, 255, .9)" : "rgba(255, 139, 127, .9)"; ctx.lineWidth = 2; ctx.setLineDash([3, 4]); ctx.beginPath(); ctx.ellipse(0, -93, 46, 67, 0, 0, TAU); ctx.stroke(); ctx.setLineDash([]); }
    ctx.restore();
  }

  function drawBall() {
    const b = state.ball;
    if (!b) return;
    if (generatedArt.player.complete && generatedArt.player.naturalWidth > 0 && !b.inFlight && !b.loose) return;
    ctx.save();
    const glow = ctx.createRadialGradient(b.x - 3, b.y - 3, 1, b.x, b.y, b.r * 2.7); glow.addColorStop(0, "rgba(255, 189, 77, .25)"); glow.addColorStop(1, "rgba(255, 152, 28, 0)"); ctx.fillStyle = glow; ctx.beginPath(); ctx.arc(b.x, b.y, b.r * 2.7, 0, TAU); ctx.fill();
    const ballGradient = ctx.createRadialGradient(b.x - 5, b.y - 6, 2, b.x, b.y, b.r); ballGradient.addColorStop(0, "#ffc66a"); ballGradient.addColorStop(.45, "#ed7d27"); ballGradient.addColorStop(1, "#b43e1d"); ctx.fillStyle = ballGradient; ctx.beginPath(); ctx.arc(b.x, b.y, b.r, 0, TAU); ctx.fill();
    ctx.save(); ctx.translate(b.x, b.y); ctx.rotate(b.spin || 0); ctx.strokeStyle = "rgba(102, 36, 21, .7)"; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(0, 0, b.r - 1, -.9, .9); ctx.stroke(); ctx.beginPath(); ctx.arc(0, 0, b.r - 1, Math.PI - .9, Math.PI + .9); ctx.stroke(); ctx.beginPath(); ctx.moveTo(-b.r + 2, -2); ctx.quadraticCurveTo(0, 7, b.r - 2, 2); ctx.stroke(); ctx.restore();
    ctx.restore();
  }

  function drawEffects() {
    const skillVfx = state.skillFlash === "火焰灌籃" ? generatedArt.fireDunkVfx : state.skillFlash === "後撤步三分" ? generatedArt.threePointerVfx : state.skillFlash === "幻影變向" ? generatedArt.crossoverVfx : null;
    if (skillVfx?.complete && skillVfx.naturalWidth > 0 && state.skillFlashTime > 0) {
      ctx.save();
      ctx.globalAlpha = clamp(state.skillFlashTime / .75, 0, 1) * .78;
      const width = state.skillFlash === "火焰灌籃" ? 264 : 284;
      const height = state.skillFlash === "火焰灌籃" ? 294 : 284;
      ctx.drawImage(skillVfx, state.player.x - width / 2, state.player.y - height - 2, width, height);
      ctx.restore();
    }
    state.rings.forEach((ring) => { ctx.save(); ctx.globalAlpha = ring.life / ring.maxLife; ctx.strokeStyle = ring.color; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(ring.x, ring.y, ring.radius, 0, TAU); ctx.stroke(); ctx.restore(); });
    state.particles.forEach((p) => { ctx.save(); ctx.globalAlpha = clamp(p.life / p.maxLife, 0, 1); ctx.fillStyle = p.color; if (p.shape === "star") { drawStar(p.x, p.y, p.size, p.size * .45, 5); } else { ctx.beginPath(); ctx.arc(p.x, p.y, p.size, 0, TAU); ctx.fill(); } ctx.restore(); });
    state.floaters.forEach((f) => { ctx.save(); ctx.globalAlpha = clamp(f.life / f.maxLife, 0, 1); ctx.fillStyle = f.color; ctx.font = "900 17px system-ui"; ctx.textAlign = "center"; ctx.shadowColor = "rgba(0,0,0,.5)"; ctx.shadowBlur = 5; ctx.fillText(f.text, f.x, f.y); ctx.restore(); });
    if (state.skillFlashTime > 0) { ctx.save(); ctx.globalAlpha = state.skillFlashTime / .75 * .25; ctx.fillStyle = state.skillFlash === "火焰灌籃" ? "#ff7c35" : state.skillFlash === "後撤步三分" ? "#54c9ff" : "#d391ff"; ctx.fillRect(0, 0, W, H); ctx.restore(); }
  }
  function drawStar(x, y, outer, inner, points) { ctx.beginPath(); for (let i = 0; i < points * 2; i += 1) { const r = i % 2 ? inner : outer; const a = -Math.PI / 2 + i * Math.PI / points; const px = x + Math.cos(a) * r; const py = y + Math.sin(a) * r; if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py); } ctx.closePath(); ctx.fill(); }

  function drawCanvasOverlay() {
    if (!state.running && !state.gameOver) {
      ctx.save(); ctx.fillStyle = "rgba(4, 11, 31, .22)"; ctx.fillRect(0, 0, W, H); ctx.fillStyle = "rgba(231, 242, 255, .88)"; ctx.font = "900 22px system-ui"; ctx.textAlign = "center"; ctx.fillText("準備好上場了嗎？", W / 2, 95); ctx.fillStyle = "rgba(169, 197, 239, .75)"; ctx.font = "700 12px system-ui"; ctx.fillText("按下下方開始按鈕，來一場喵萌街頭對決", W / 2, 118); ctx.restore();
    }
    if (state.gameOver) {
      ctx.save(); ctx.fillStyle = "rgba(5, 11, 29, .46)"; ctx.fillRect(0, 0, W, H);
      if (state.score.player > state.score.opponent && generatedArt.trophyBadge.complete && generatedArt.trophyBadge.naturalWidth > 0) {
        ctx.globalAlpha = .92;
        ctx.drawImage(generatedArt.trophyBadge, W / 2 - 48, 28, 96, 96);
      }
      ctx.fillStyle = "#fff"; ctx.font = "1000 34px system-ui"; ctx.textAlign = "center"; ctx.fillText(state.score.player > state.score.opponent ? "VICTORY" : state.score.player === state.score.opponent ? "DRAW" : "NEXT GAME", W / 2, 120); ctx.fillStyle = "#a8caff"; ctx.font = "800 13px system-ui"; ctx.fillText(`${state.score.player}  —  ${state.score.opponent}`, W / 2, 148); ctx.restore();
    }
  }

  /* ------------------------------ input wiring ------------------------------ */

  function bindHoldButton(button, onDown, onUp) {
    ["pointerdown"].forEach((type) => button.addEventListener(type, (event) => { event.preventDefault(); event.stopPropagation(); button.setPointerCapture?.(event.pointerId); onDown(); }));
    ["pointerup", "pointercancel", "lostpointercapture"].forEach((type) => button.addEventListener(type, (event) => { event.preventDefault(); event.stopPropagation(); onUp(); }));
  }

  window.addEventListener("keydown", (event) => {
    if (["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", " ", "Spacebar"].includes(event.key)) event.preventDefault();
    state.keys[event.key] = true;
    if (event.key === " " || event.code === "Space") beginShot();
    if (event.key === "Enter" && state.mode === "duo") beginOpponentShot();
    if (event.key === "/" && state.mode === "duo") attemptOpponentSteal();
    if (event.key.toLowerCase() === "x") attemptSteal();
    if (event.key.toLowerCase() === "q") triggerSkill("火焰灌籃");
    if (event.key.toLowerCase() === "e") triggerSkill("後撤步三分");
    if (event.key.toLowerCase() === "r") triggerSkill("幻影變向");
    if (event.key.toLowerCase() === "f") triggerSkill("流星投籃");
  });
  window.addEventListener("keyup", (event) => {
    state.keys[event.key] = false;
    if (event.key === " " || event.code === "Space") releaseShot();
    if (event.key === "Enter" && state.mode === "duo" && state.chargingShooter === "opponent") releaseShot();
    if (event.key === "Shift") state.sprinting = false;
  });

  bindHoldButton(ui.shotButton, beginShot, releaseShot);
  bindHoldButton($("sprintButton"), () => { state.sprinting = true; }, () => { state.sprinting = false; });
  $("passButton").addEventListener("click", performPass);
  $("stealButton").addEventListener("click", attemptSteal);
  ui.start.addEventListener("click", startOrPause);
  ui.reset.addEventListener("click", () => resetGame());

  // Mouse/touch on the court itself doubles as a large shot button for desktop/tablet.
  let canvasShotPointer = null;
  canvas.addEventListener("pointerdown", (event) => {
    if (event.pointerType === "mouse" && event.button !== 0) return;
    canvasShotPointer = event.pointerId;
    canvas.setPointerCapture?.(event.pointerId);
    beginShot();
  });
  ["pointerup", "pointercancel", "lostpointercapture"].forEach((type) => canvas.addEventListener(type, (event) => { if (canvasShotPointer === event.pointerId) { canvasShotPointer = null; releaseShot(); } }));

  const joystick = $("joystick");
  const joystickStick = $("joystickStick");
  let joystickPointer = null;
  function updateJoystick(event) {
    const rect = joystick.getBoundingClientRect();
    const radius = rect.width * .38;
    const cx = rect.left + rect.width / 2;
    const cy = rect.top + rect.height / 2;
    const dx = event.clientX - cx;
    const dy = event.clientY - cy;
    const length = Math.min(radius, Math.hypot(dx, dy));
    const angle = Math.atan2(dy, dx);
    const nx = length ? Math.cos(angle) * length / radius : 0;
    const ny = length ? Math.sin(angle) * length / radius : 0;
    state.joystick.x = nx;
    state.joystick.y = ny;
    joystickStick.style.transform = `translate(calc(-50% + ${Math.cos(angle) * length}px), calc(-50% + ${Math.sin(angle) * length}px))`;
  }
  joystick.addEventListener("pointerdown", (event) => { event.preventDefault(); event.stopPropagation(); joystickPointer = event.pointerId; joystick.setPointerCapture?.(event.pointerId); state.joystick.active = true; updateJoystick(event); });
  joystick.addEventListener("pointermove", (event) => { if (joystickPointer === event.pointerId) updateJoystick(event); });
  ["pointerup", "pointercancel", "lostpointercapture"].forEach((type) => joystick.addEventListener(type, (event) => { if (joystickPointer === event.pointerId) { joystickPointer = null; state.joystick.active = false; state.joystick.x = 0; state.joystick.y = 0; joystickStick.style.transform = "translate(-50%, -50%)"; } }));

  $("soundToggle").addEventListener("click", () => { state.muted = !state.muted; $("soundToggle").classList.toggle("muted", state.muted); $("soundToggle").setAttribute("aria-pressed", String(!state.muted)); showToast(state.muted ? "音效已關閉" : "音效已開啟", 900, false); if (!state.muted) playTone(560, .08, "triangle"); });
  $("howToPlay").addEventListener("click", () => { $("helpModal").classList.add("open"); $("helpModal").setAttribute("aria-hidden", "false"); });
  $("closeHelp").addEventListener("click", () => { $("helpModal").classList.remove("open"); $("helpModal").setAttribute("aria-hidden", "true"); });
  $("modalStart").addEventListener("click", () => { $("helpModal").classList.remove("open"); $("helpModal").setAttribute("aria-hidden", "true"); if (!state.running) startOrPause(); });
  $("helpModal").addEventListener("click", (event) => { if (event.target === $("helpModal")) { $("helpModal").classList.remove("open"); $("helpModal").setAttribute("aria-hidden", "true"); } });

  document.querySelectorAll(".mode-card").forEach((button) => button.addEventListener("click", () => setMode(button.dataset.mode)));
  document.querySelectorAll(".mode-duo button").forEach((button) => button.addEventListener("click", () => {
    setMode(button.dataset.mode);
    showToast("雙人對戰：P1 用 WASD／Space，P2 用方向鍵／Enter，/ 可抄球", 2200);
  }));
  document.querySelectorAll(".character-tab").forEach((button) => button.addEventListener("click", () => selectCharacter(button.dataset.character)));
  document.querySelectorAll(".skill-card").forEach((button) => button.addEventListener("click", () => triggerSkill(button.dataset.skill)));

  function loop(time) {
    const dt = state.lastTime ? Math.min(.04, (time - state.lastTime) / 1000) : 0;
    state.lastTime = time;
    update(dt);
    draw();
    requestAnimationFrame(loop);
  }

  resetGame(false);
  requestAnimationFrame(loop);
})();
