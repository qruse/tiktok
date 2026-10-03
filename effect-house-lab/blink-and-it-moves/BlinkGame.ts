// Blink and It Moves: every blink lets the figure behind you step closer; on the last step it lunges.
// The figure moves while the eyes are closed, so the player never sees it move.
@component()
export class BlinkGame extends APJS.BasicScriptComponent {
  @header('Theme & Assets')
  @tooltip('Figure poses from far to near; the step range is split evenly between them')
  @serializeProperty poses: APJS.Texture[] = [];
  @header('Gameplay Tuning')
  @spinBox(3, 12, 1)
  @serializeProperty steps: number = 7;
  @slider(0.2, 1.5, 0.05)
  @serializeProperty minGap: number = 0.4;
  @slider(2, 15, 0.5)
  @tooltip('Seconds without a blink before the figure steps on its own')
  @serializeProperty idleStep: number = 6;
  @slider(0.3, 0.9, 0.05)
  @tooltip('Eye counts as closed below this share of the open-eye baseline')
  @serializeProperty closeRatio: number = 0.6;
  @header('Advanced - Scene Wiring')
  @serializeProperty figure: APJS.SceneObject;
  @serializeProperty segCamera: APJS.SceneObject;
  @serializeProperty introText: APJS.SceneObject;
  @serializeProperty blackout: APJS.SceneObject;
  @serializeProperty scareFigure: APJS.SceneObject;
  @serializeProperty flash: APJS.SceneObject;
  @serializeProperty resultPanel: APJS.SceneObject;
  @serializeProperty frames: APJS.SceneObject[] = [];
  @serializeProperty frameLabels: APJS.SceneObject[] = [];
  @serializeProperty timeText: APJS.SceneObject;
  @serializeProperty retryButton: APJS.SceneObject;
  @serializeProperty droneSfx: APJS.SceneObject;
  @serializeProperty thumpSfx: APJS.SceneObject;
  @serializeProperty heartSfx: APJS.SceneObject;
  @serializeProperty stingSfx: APJS.SceneObject;

  private ready = false;
  private figTr!: APJS.ScreenTransform;
  private figImg!: APJS.Image;
  private scareTr!: APJS.ScreenTransform;
  private introTr!: APJS.ScreenTransform;
  private scareHome = new APJS.Vector2f(0, 200);
  private cam!: APJS.Camera;
  private frameImgs: APJS.Image[] = [];
  private frameTexts: APJS.Text[] = [];
  private shotTimes: number[] = [];
  private time!: APJS.Text;
  private retryImg!: APJS.Image;
  private drone: APJS.AudioComponent[] = [];
  private thump: APJS.AudioComponent[] = [];
  private heart: APJS.AudioComponent[] = [];
  private sting: APJS.AudioComponent[] = [];
  private heartT = -1;
  private scareShot = 0;
  private bestReact = -1;
  private readonly reactTimes = [0.42, 0.67, 0.92];
  private readonly scareDark = 0.12;
  private revealed = false;

  private state = 'intro';
  private t = 0;
  private playTime = 0;
  private step = 0;
  private sinceStep = 0;
  private lastClose = -10;
  private wasClosed = false;
  private earBase = 0;
  private blackT = 0;
  private captureT = -1;
  private shots: APJS.Texture[] = [];
  private reaction: APJS.Texture[] = [];

  private onTouch = (event: APJS.IEvent): void => {
    const touch = event.args[0] as APJS.TouchData;
    if (this.state !== 'result' || touch.phase !== APJS.TouchPhase.Began) return;
    if (APJS.TouchUtils.isScreenPointOnImage(touch.position, this.retryImg)) this.reset();
  };
  private onRecord = (): void => { if (this.ready) this.reset(); };

  private init(): boolean {
    const refs = [this.figure, this.segCamera, this.introText, this.blackout, this.scareFigure, this.resultPanel, this.timeText, this.retryButton];
    if (refs.some(r => !r) || this.frames.length < 4) return false;
    this.figTr = this.figure.getComponent('ScreenTransform') as APJS.ScreenTransform;
    this.figImg = this.figure.getComponent('Image') as APJS.Image;
    this.scareTr = this.scareFigure.getComponent('ScreenTransform') as APJS.ScreenTransform;
    this.introTr = this.introText.getComponent('ScreenTransform') as APJS.ScreenTransform;
    if (this.scareTr) this.scareHome = this.scareTr.anchoredPosition;
    this.cam = this.segCamera.getComponent('Camera') as APJS.Camera;
    this.frameImgs = this.frames.map(o => o.getComponent('Image') as APJS.Image);
    this.time = this.timeText.getComponent('Text') as APJS.Text;
    this.frameTexts = this.frameLabels.map(o => o.getComponent('Text') as APJS.Text);
    this.retryImg = this.retryButton.getComponent('Image') as APJS.Image;
    if (!this.figTr || !this.scareTr || !this.cam || !this.time || !this.retryImg || this.frameImgs.some(x => !x)) return false;
    // sounds are optional: a missing player just stays silent
    const sfx = (o: APJS.SceneObject): APJS.AudioComponent[] => {
      const a = o ? (o.getComponent('AudioComponent') as APJS.AudioComponent) : undefined;
      return a ? [a] : [];
    };
    this.drone = sfx(this.droneSfx); this.thump = sfx(this.thumpSfx); this.heart = sfx(this.heartSfx); this.sting = sfx(this.stingSfx);
    APJS.EventManager.getGlobalEmitter().on(APJS.EventType.Touch, this.onTouch, this);
    APJS.EventManager.getGlobalEmitter().on(APJS.EventType.RecordStart, this.onRecord, this);
    this.ready = true;
    this.reset();
    return true;
  }

  private reset(): void {
    this.state = 'intro'; this.t = 0; this.playTime = 0; this.step = 0; this.sinceStep = 0;
    this.wasClosed = false; this.blackT = 0; this.captureT = -1; this.shots = []; this.reaction = []; this.shotTimes = [];
    this.lastClose = -10; this.heartT = -1;
    this.drone.forEach(a => { a.volume = 30; a.play(); });
    this.figure.setEnabledInHierarchy(true);
    this.introText.setEnabledInHierarchy(true);
    this.blackout.setEnabledInHierarchy(false);
    this.scareFigure.setEnabledInHierarchy(false);
    if (this.flash) this.flash.setEnabledInHierarchy(false);
    this.resultPanel.setEnabledInHierarchy(false);
    this.placeFigure();
    console.log('[game] reset');
  }

  private placeFigure(): void {
    // the first step is the biggest jump so the rule reads at once; later steps are even
    const f = this.step <= 0 ? 0 : Math.min(1, 0.3 + 0.7 * (this.step - 1) / Math.max(1, this.steps - 2));
    // big enough on the first screen that the player notices someone is standing there
    const h = 1280 * (0.22 + 0.63 * f);
    // keep the figure's head peeking over the player's right shoulder as it grows
    const headY = 250 + 110 * f;
    this.figTr.sizeDelta = new APJS.Vector2f(h * 9 / 16, h);
    this.figTr.anchoredPosition = new APJS.Vector2f(200 + 15 * f, headY - 0.42 * h);
    if (this.poses.length > 0 && this.figImg) {
      const k = Math.min(this.poses.length - 1, Math.floor(f * this.poses.length));
      if (this.poses[k]) this.figImg.texture = this.poses[k];
    }
  }

  // true while both eyes are shut, from landmark eye aspect ratio or the built-in blink flags
  private eyesClosed(face: APJS.Face106Interface, dt: number): boolean {
    const p = face.pointsArray;
    const d = (i: number, j: number): number => Math.sqrt((p[2 * i] - p[2 * j]) ** 2 + (p[2 * i + 1] - p[2 * j + 1]) ** 2);
    const ear = (d(72, 73) / Math.max(1e-5, d(52, 55)) + d(75, 76) / Math.max(1e-5, d(58, 61))) * 0.5;
    if (this.earBase === 0) this.earBase = ear;
    const closed = ear < this.earBase * this.closeRatio;
    if (!closed) this.earBase += (ear - this.earBase) * Math.min(1, dt * 1.5);
    return closed || face.hasAction(APJS.FaceAction.EyeBlink) || face.hasAction(APJS.FaceAction.EyeBlinkLeft) || face.hasAction(APJS.FaceAction.EyeBlinkRight);
  }

  private capture(): APJS.Texture | undefined {
    const tex = APJS.CaptureFrameHelper.captureCameraOutput(this.cam, new APJS.Rect(0, 0, 1, 1), 0.3);
    return tex ? tex : undefined;
  }

  private doStep(reason: string): void {
    this.step++; this.sinceStep = 0;
    console.log('[game] step ' + this.step + ' (' + reason + ') at ' + this.playTime.toFixed(2) + 's');
    if (this.step >= this.steps) { this.startScare(); return; }
    this.placeFigure();
    this.blackT = 0.12; this.blackout.setEnabledInHierarchy(true);
    this.captureT = 0.3;
    this.thump.forEach(a => a.play());
    this.heartT = 0.45;
    this.drone.forEach(a => { a.volume = Math.min(80, 30 + this.step * 8); });
  }

  private startScare(): void {
    this.state = 'scare'; this.t = 0; this.captureT = -1; this.scareShot = 0; this.bestReact = -1; this.revealed = false;
    this.figure.setEnabledInHierarchy(false);
    // the last "blink": a dark beat, then it is already in your face (revealed in onUpdate)
    this.blackout.setEnabledInHierarchy(true);
    this.scareFigure.setEnabledInHierarchy(false);
    this.heartT = -1;
    this.drone.forEach(a => a.stop());
  }

  private showResult(): void {
    this.state = 'result';
    this.scareFigure.setEnabledInHierarchy(false);
    if (this.flash) this.flash.setEnabledInHierarchy(false);
    this.figure.setEnabledInHierarchy(true);
    this.resultPanel.setEnabledInHierarchy(true);
    const n = this.shots.length;
    for (let i = 0; i < 3; i++) {
      const k = Math.round((i + 1) * n / 3) - 1;
      if (k >= 0 && k < n) {
        this.frameImgs[i].texture = this.shots[k];
        if (this.frameTexts[i]) this.frameTexts[i].text = this.shotTimes[k].toFixed(1) + 's';
      }
    }
    if (this.reaction.length > 0) this.frameImgs[3].texture = this.reaction[0];
    if (this.frameTexts[3]) this.frameTexts[3].text = 'CAUGHT';
    this.time.text = 'LASTED ' + this.playTime.toFixed(1) + 's';
    console.log('[game] result time=' + this.playTime.toFixed(2) + ' shots=' + n + ' reaction=' + this.reaction.length);
  }

  onUpdate(dt: number): void {
    if (!this.ready && !this.init()) return;
    // a load hitch (scene reload, record start) must not eat the intro or count as play time
    dt = Math.min(dt, 0.1);
    this.t += dt;
    if (this.blackT > 0) { this.blackT -= dt; if (this.blackT <= 0) this.blackout.setEnabledInHierarchy(false); }
    if (this.heartT >= 0) { this.heartT -= dt; if (this.heartT < 0) this.heart.forEach(a => a.play()); }
    if (this.captureT >= 0) {
      this.captureT -= dt;
      if (this.captureT < 0) {
        const tex = this.capture();
        if (tex) { if (this.state === 'scare') this.reaction = [tex]; else if (this.shots.length < 12) { this.shots.push(tex); this.shotTimes.push(this.playTime); } }
      }
    }
    if (this.state === 'intro') {
      if (this.introTr) { const pulse = 1 + 0.06 * Math.sin(this.t * 7); this.introTr.scale = new APJS.Vector2f(pulse, pulse); }
      if (this.t >= 2.5) { this.state = 'play'; this.t = 0; this.introText.setEnabledInHierarchy(false); console.log('[game] play'); }
      return;
    }
    if (this.state === 'scare') {
      const r = this.t - this.scareDark;
      if (r < 0) return;
      if (!this.revealed) {
        this.revealed = true;
        this.blackout.setEnabledInHierarchy(false);
        this.scareFigure.setEnabledInHierarchy(true);
        this.sting.forEach(a => a.play());
      }
      // already close when the dark beat ends, then a short punch-in and a slow creep until the cut
      const k = Math.min(1, r / 0.1), e = 1 - (1 - k) * (1 - k) * (1 - k);
      const s = 1.5 + 0.4 * e + 0.15 * Math.min(1, Math.max(0, r - 0.1) / 0.78);
      this.scareTr.scale = new APJS.Vector2f(s, s);
      // white pop on impact, then a short decaying shake
      if (this.flash) this.flash.setEnabledInHierarchy(r < 0.06);
      const amp = 34 * Math.max(0, 1 - r / 0.5);
      this.scareTr.anchoredPosition = new APJS.Vector2f(this.scareHome.x + amp * Math.sin(r * 90), this.scareHome.y + amp * Math.cos(r * 77));
      // keep the most surprised/fearful of three reaction shots
      if (this.scareShot < this.reactTimes.length && this.t >= this.reactTimes[this.scareShot]) {
        this.scareShot++;
        const res = APJS.AlgorithmManager.getResult();
        let score = 0;
        if (res.getFaceAttributeCount() > 0) { const pr = res.getFaceAttributeInfo(0).expressionProbabilities; score = pr[5] + pr[2]; }
        if (score > this.bestReact) { const tex = this.capture(); if (tex) { this.reaction = [tex]; this.bestReact = score; } }
        console.log('[game] reaction shot ' + this.scareShot + ' score=' + score.toFixed(3));
      }
      // the face stays covered for 0.88 s (under the 1 s limit)
      if (r >= 0.88) this.showResult();
      return;
    }
    if (this.state !== 'play') return;
    this.playTime += dt;
    const result = APJS.AlgorithmManager.getResult();
    if (result.getFaceCount() === 0) { this.wasClosed = false; return; }
    this.sinceStep += dt;
    const closed = this.eyesClosed(result.getFaceBaseInfo(0), dt);
    if (closed && !this.wasClosed && this.playTime - this.lastClose >= this.minGap) { this.lastClose = this.playTime; this.doStep('blink'); }
    else if (this.sinceStep >= this.idleStep) this.doStep('idle');
    this.wasClosed = closed;
  }

  onDestroy(): void {
    if (!this.ready) return;
    APJS.EventManager.getGlobalEmitter().off(APJS.EventType.Touch, this.onTouch, this);
    APJS.EventManager.getGlobalEmitter().off(APJS.EventType.RecordStart, this.onRecord, this);
  }
}