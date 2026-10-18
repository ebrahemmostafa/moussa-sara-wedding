// Gently scrolls the invitation once the guest has been idle for 4 seconds.
// Any touch, wheel, key or click pauses it; it resumes after another 4 idle seconds.
(function () {
  var IDLE_MS = 4000;
  var SPEED = 60; // pixels per second
  if (window.matchMedia && matchMedia("(prefers-reduced-motion: reduce)").matches) return;

  var idleTimer = null;
  var frame = null;
  var last = 0;
  var carry = 0;

  function ready() {
    // The main page exists only after the envelope intro has finished.
    return !!document.querySelector("main");
  }

  function atBottom() {
    return window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2;
  }

  function typing() {
    var el = document.activeElement;
    return el && /^(INPUT|TEXTAREA|SELECT)$/.test(el.tagName);
  }

  function step(now) {
    if (!last) last = now;
    carry += (now - last) / 1000 * SPEED;
    last = now;
    var px = Math.floor(carry);
    if (px > 0) {
      carry -= px;
      window.scrollBy(0, px);
    }
    if (atBottom()) return stop();
    frame = requestAnimationFrame(step);
  }

  function start() {
    if (frame || !ready() || typing() || atBottom()) return schedule();
    last = 0;
    carry = 0;
    frame = requestAnimationFrame(step);
  }

  function stop() {
    if (frame) cancelAnimationFrame(frame);
    frame = null;
  }

  function schedule() {
    clearTimeout(idleTimer);
    idleTimer = setTimeout(start, IDLE_MS);
  }

  function userActed() {
    stop();
    schedule();
  }

  ["wheel", "touchstart", "touchmove", "keydown", "pointerdown", "focusin"].forEach(function (type) {
    window.addEventListener(type, userActed, { passive: true });
  });
  document.addEventListener("visibilitychange", function () {
    if (document.hidden) stop(); else schedule();
  });

  schedule();
})();
