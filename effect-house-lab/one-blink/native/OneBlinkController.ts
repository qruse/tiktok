/* Shared deterministic rules. No browser, camera, network or platform APIs. */
class OneBlinkGame {
  seed: number; state: string; round: number; cleared: number; spent: number; penalty: number; phaseTime: number; limit: number; cards: number[]; target: number; correctIndex: number; wrong: number[]; lastWrong: number; messageTime: number; roundTimes: number[]; roundStart: number;
  constructor(seed = 1) {
    this.seed = seed >>> 0 || 1;
    this.state = 'intro'; this.round = 0; this.cleared = 0;
    this.spent = 0; this.penalty = 0; this.phaseTime = 0;
    this.limit = 14; this.cards = []; this.target = 0;
    this.correctIndex = -1; this.wrong = []; this.lastWrong = -1;
    this.messageTime = 0; this.roundTimes = []; this.roundStart = 0;
  }
  random() {
    this.seed = (Math.imul(this.seed, 1664525) + 1013904223) >>> 0;
    return this.seed / 4294967296;
  }
  start() { if (this.state !== 'intro' && this.state !== 'result') return; this.round = 0; this.cleared = 0; this.spent = 0; this.penalty = 0; this.roundTimes = []; this.nextRound(); }
  nextRound() {
    this.round++; this.state = 'memorize'; this.phaseTime = 1.5;
    this.target = Math.floor(this.random() * 12); this.wrong = []; this.lastWrong = -1;
    const count = [0, 6, 9, 12][this.round];
    this.correctIndex = Math.floor(this.random() * count);
    this.cards = Array.from({length:count}, (_, i) => {
      if (i === this.correctIndex) return this.target;
      let variant = Math.floor(this.random() * 11);
      return variant >= this.target ? variant + 1 : variant;
    });
    this.roundStart = this.spent + this.penalty;
  }
  update(dt: number) {
    if (!Number.isFinite(dt) || dt <= 0) return;
    this.messageTime = Math.max(0, this.messageTime - dt);
    if (this.state === 'search') {
      this.spent += dt;
      if (this.spent + this.penalty >= this.limit) { this.spent = Math.max(0, this.limit - this.penalty); this.finish(); }
    } else if (this.state === 'memorize' || this.state === 'correct') {
      this.phaseTime -= dt;
      if (this.phaseTime <= 0) {
        if (this.state === 'memorize') this.state = 'search';
        else if (this.cleared === 3) this.finish();
        else this.nextRound();
        this.phaseTime = 0;
        if (this.state === 'memorize') this.phaseTime = 1.5;
      }
    }
  }
  tap(index: number) {
    if (this.state !== 'search' || !Number.isInteger(index) || index < 0 || index >= this.cards.length || this.wrong.includes(index)) return 'ignored';
    if (index === this.correctIndex) {
      this.cleared++; this.roundTimes.push(this.spent + this.penalty - this.roundStart);
      this.state = 'correct'; this.phaseTime = .65; return 'correct';
    }
    this.wrong.push(index); this.lastWrong = index; this.penalty = Math.min(this.limit, this.penalty + 1);
    this.messageTime = .75;
    if (this.spent + this.penalty >= this.limit) this.finish();
    return 'wrong';
  }
  finish() { this.state = 'result'; this.phaseTime = 0; }
  remaining() { return Math.max(0, this.limit - this.spent - this.penalty); }
  score() { return Math.min(this.limit, this.spent + this.penalty); }
}


// Appended after the shared rules by build-native.cjs. Import through Effect House
// add_script, then attach and wire after its compile step. Not a native project file.
@component()
export class OneBlinkController extends APJS.BasicScriptComponent {
  @serializeProperty() faceTextures: APJS.Texture[] = [];
  @serializeProperty() tiles: APJS.SceneObject[] = [];
  @serializeProperty() introPanel!: APJS.SceneObject;
  @serializeProperty() playPanel!: APJS.SceneObject;
  @serializeProperty() resultPanel!: APJS.SceneObject;
  @serializeProperty() memoryStar!: APJS.SceneObject;
  @serializeProperty() startButton!: APJS.SceneObject;
  @serializeProperty() retryButton!: APJS.SceneObject;
  @serializeProperty() promptObject!: APJS.SceneObject;
  @serializeProperty() hintObject!: APJS.SceneObject;
  @serializeProperty() roundObject!: APJS.SceneObject;
  @serializeProperty() timerObject!: APJS.SceneObject;
  @serializeProperty() feedbackObject!: APJS.SceneObject;
  @serializeProperty() resultTitleObject!: APJS.SceneObject;
  @serializeProperty() resultScoreObject!: APJS.SceneObject;
  @serializeProperty() resultDetailObject!: APJS.SceneObject;
  private game = new OneBlinkGame(Math.floor(Math.random()*4294967295));
  private ready = false;
  private previousState = '';
  private previousRound = 0;
  private images: APJS.Image[] = [];
  private transforms: APJS.ScreenTransform[] = [];
  private memoryImage!: APJS.Image;
  private startImage!: APJS.Image;
  private retryImage!: APJS.Image;
  private promptText!: APJS.Text;
  private hintText!: APJS.Text;
  private roundText!: APJS.Text;
  private timerText!: APJS.Text;
  private feedbackText!: APJS.Text;
  private resultTitle!: APJS.Text;
  private resultScore!: APJS.Text;
  private resultDetail!: APJS.Text;
  private touch = (event: APJS.IEvent): void => {
    if(!this.ready)return;
    const t=event.args[0] as APJS.TouchData;
    if(t.phase!==APJS.TouchPhase.Began || t.touchCount>1)return;
    if(this.game.state==='intro' && APJS.TouchUtils.isScreenPointOnImage(t.position,this.startImage))this.game.start();
    else if(this.game.state==='result' && APJS.TouchUtils.isScreenPointOnImage(t.position,this.retryImage))this.game.start();
    else if(this.game.state==='search') {
      for(let i=0;i<this.game.cards.length;i++)if(APJS.TouchUtils.isScreenPointOnImage(t.position,this.images[i])){this.game.tap(i);break;}
    }
    this.render();
  };
  // Every recorded take starts clean; unrecorded practice is never inherited.
  private recordStart = (): void => {this.game=new OneBlinkGame(Math.floor(Math.random()*4294967295));this.previousState='';this.previousRound=0;if(this.ready)this.render();};
  private initialize(): boolean {
    const objects=[this.introPanel,this.playPanel,this.resultPanel,this.memoryStar,this.startButton,this.retryButton,this.promptObject,this.hintObject,this.roundObject,this.timerObject,this.feedbackObject,this.resultTitleObject,this.resultScoreObject,this.resultDetailObject];
    if(objects.some(x=>!x)||this.faceTextures.length!==12||this.tiles.length!==12||this.faceTextures.some(x=>!x)||this.tiles.some(x=>!x))return false;
    this.images=this.tiles.map(o=>o.getComponent('Image') as APJS.Image);
    this.transforms=this.tiles.map(o=>o.getComponent('ScreenTransform') as APJS.ScreenTransform);
    this.memoryImage=this.memoryStar.getComponent('Image') as APJS.Image;
    this.startImage=this.startButton.getComponent('Image') as APJS.Image;
    this.retryImage=this.retryButton.getComponent('Image') as APJS.Image;
    this.promptText=this.promptObject.getComponent('Text') as APJS.Text;
    this.hintText=this.hintObject.getComponent('Text') as APJS.Text;
    this.roundText=this.roundObject.getComponent('Text') as APJS.Text;
    this.timerText=this.timerObject.getComponent('Text') as APJS.Text;
    this.feedbackText=this.feedbackObject.getComponent('Text') as APJS.Text;
    this.resultTitle=this.resultTitleObject.getComponent('Text') as APJS.Text;
    this.resultScore=this.resultScoreObject.getComponent('Text') as APJS.Text;
    this.resultDetail=this.resultDetailObject.getComponent('Text') as APJS.Text;
    if(this.images.some(x=>!x)||this.transforms.some(x=>!x)||!this.memoryImage||!this.startImage||!this.retryImage||!this.promptText||!this.hintText||!this.roundText||!this.timerText||!this.feedbackText||!this.resultTitle||!this.resultScore||!this.resultDetail)return false;
    APJS.EventManager.getGlobalEmitter().on(APJS.EventType.Touch,this.touch,this);
    APJS.EventManager.getGlobalEmitter().on(APJS.EventType.RecordStart,this.recordStart,this);
    this.ready=true;this.render();return true;
  }
  onUpdate(dt: number): void {if(!this.ready&&!this.initialize())return;this.game.update(dt);this.render();}
  private render(): void {
    const g=this.game, changed=g.state!==this.previousState||g.round!==this.previousRound;
    if(changed){this.introPanel.setEnabledInHierarchy(g.state==='intro');this.playPanel.setEnabledInHierarchy(g.state!=='intro'&&g.state!=='result');this.resultPanel.setEnabledInHierarchy(g.state==='result');}
    this.memoryStar.setEnabledInHierarchy(g.state==='memorize');
    this.memoryImage.texture=this.faceTextures[g.target];
    this.promptText.text=g.state==='memorize'?'이 표정을 기억해!':g.state==='correct'?'맞아, 바로 그 별!':'방금 본 별은 어디?';
    this.hintText.text=g.state==='memorize'?'눈과 입을 잘 봐요 · '+Math.max(0,g.phaseTime).toFixed(1)+'초':'같은 표정의 별을 탭해요';
    this.roundText.text='ROUND 0'+g.round+' / 03';this.timerText.text=g.remaining().toFixed(2)+'s';
    this.feedbackText.text=g.state==='correct'?'GOT IT':g.messageTime>0?'+1초 · 눈과 입을 다시 봐요':'';
    for(let i=0;i<12;i++){
      const visible=i<g.cards.length&&(g.state==='search'||g.state==='correct');this.tiles[i].setEnabledInHierarchy(visible);
      if(!visible)continue;
      this.images[i].texture=this.faceTextures[g.cards[i]];
      this.images[i].opacity=g.wrong.indexOf(i)>=0?.25:1;
      if(changed){const cols=g.cards.length<=9?3:4,rows=Math.ceil(g.cards.length/cols),w=540/cols,h=390/rows;
        this.transforms[i].anchoredPosition=new APJS.Vector2f(-270+w*(i%cols+.5),170-h*(Math.floor(i/cols)+.5));
        const size=Math.min(w-10,h-6);this.transforms[i].sizeDelta=new APJS.Vector2f(size,size);
      }
      const scale=g.state==='correct'&&i===g.correctIndex?1.08:1;this.transforms[i].scale=new APJS.Vector2f(scale,scale);
    }
    if(changed&&g.state==='result'){const won=g.cleared===3;this.resultTitle.text=won?'눈치 챘네!':'거의 다 찾았어';this.resultScore.text=won?g.score().toFixed(2)+'초':g.cleared+' / 3 ROUND';this.resultDetail.text=(won?'3라운드 성공':'찾는 시간 14초 종료')+' · 오답 가산 '+g.penalty+'초';}
    this.previousState=g.state;this.previousRound=g.round;
  }
  onDestroy(): void {if(!this.ready)return;APJS.EventManager.getGlobalEmitter().off(APJS.EventType.Touch,this.touch,this);APJS.EventManager.getGlobalEmitter().off(APJS.EventType.RecordStart,this.recordStart,this);this.ready=false;}
}
