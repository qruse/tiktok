/* Shared deterministic rules. No browser, camera, network or platform APIs. */
class OneBlinkGame {
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
  update(dt) {
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
  tap(index) {
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
if (typeof module !== 'undefined') module.exports = {OneBlinkGame};

