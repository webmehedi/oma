/* ============================================================
   Ledgerly — motion.js (shared by every mockup page)
   Implements motion-spec.md ONLY: Lenis (scroll.lerp), reveal-
   on-scroll (scroll tokens), enter/stagger helpers (duration/
   easing tokens), the paid `emphasis` moment, and the mockup
   state switcher. Everything gates on prefers-reduced-motion.
   Values are read from tokens.css custom properties — no magic
   numbers in this file.
   ============================================================ */
(function () {
  'use strict';

  var reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  var rootStyle = getComputedStyle(document.documentElement);
  function cssVar(name) { return rootStyle.getPropertyValue(name).trim(); }
  function cssMs(name) { return parseFloat(cssVar(name)) || 0; }
  function cssNum(name) { return parseFloat(cssVar(name)) || 0; }

  var T = {
    enterFast: cssMs('--dur-enter-fast'),
    enterDefault: cssMs('--dur-enter-default'),
    exitFast: cssMs('--dur-exit-fast'),
    exitDefault: cssMs('--dur-exit-default'),
    move: cssMs('--dur-move'),
    emphasis: cssMs('--dur-emphasis'),
    easeEnter: cssVar('--ease-enter'),
    easeExit: cssVar('--ease-exit'),
    easeMove: cssVar('--ease-move'),
    staggerList: cssMs('--stagger-list'),
    staggerHero: cssMs('--stagger-hero'),
    scrollLerp: cssNum('--scroll-lerp'),
    revealOffsetPct: cssNum('--reveal-offset'),
    revealDistance: cssNum('--reveal-distance')
  };

  if (reduced) { document.documentElement.classList.add('no-motion'); }

  var hasMotion = typeof window.Motion !== 'undefined' && typeof window.Motion.animate === 'function';

  /* ---------- core animate helper (Motion UMD, WAAPI fallback) ---------- */
  function animate(el, keyframes, opts) {
    if (reduced) {
      // Collapse: final values, instantly. Opacity-only philosophy.
      el.style.opacity = '';
      el.style.transform = '';
      return;
    }
    if (hasMotion) {
      window.Motion.animate(el, keyframes, {
        duration: (opts.duration || T.enterDefault) / 1000,
        ease: opts.cubic || [0.2, 0, 0, 1],
        delay: (opts.delay || 0) / 1000
      });
    } else if (el.animate) {
      var frames = {};
      Object.keys(keyframes).forEach(function (k) { frames[k] = keyframes[k]; });
      el.animate(frames, {
        duration: opts.duration || T.enterDefault,
        easing: opts.easing || T.easeEnter,
        delay: opts.delay || 0,
        fill: 'both'
      });
    }
  }

  /* ---------- enter / stagger ---------- */
  function enterEl(el, delay) {
    animate(el, { opacity: [0, 1], transform: ['translateY(' + (T.revealDistance / 3) + 'px)', 'translateY(0px)'] },
      { duration: T.enterDefault, easing: T.easeEnter, cubic: [0.2, 0, 0, 1], delay: delay || 0 });
  }
  function enterFastEl(el, delay) {
    animate(el, { opacity: [0, 1], transform: ['translateY(' + (T.revealDistance / 3) + 'px)', 'translateY(0px)'] },
      { duration: T.enterFast, easing: T.easeEnter, cubic: [0.2, 0, 0, 1], delay: delay || 0 });
  }
  // stagger.list over children; batches after 8 per motion-spec
  function staggerChildren(container, step) {
    var kids = Array.prototype.slice.call(container.children);
    kids.forEach(function (kid, i) {
      var delay = Math.min(i, 8) * (step || T.staggerList);
      enterFastEl(kid, delay);
    });
  }
  // stagger.hero across explicitly marked blocks
  function heroSequence(els) {
    els.forEach(function (el, i) { enterEl(el, i * T.staggerHero); });
  }

  /* ---------- emphasis: the Paid moment only ---------- */
  function emphasize(el) {
    if (reduced) return;
    if (hasMotion) {
      window.Motion.animate(el, { scale: [1, 1.06, 1] }, { duration: T.emphasis / 1000, type: 'spring', bounce: 0.35 });
    } else if (el.animate) {
      el.animate({ transform: ['scale(1)', 'scale(1.06)', 'scale(1)'] }, { duration: T.emphasis, easing: T.easeMove });
    }
  }

  /* ---------- exit helper ---------- */
  function exitEl(el, done) {
    if (reduced) { if (done) done(); return; }
    var finish = function () { if (done) done(); };
    if (el.animate) {
      var a = el.animate({ opacity: [1, 0] }, { duration: T.exitDefault, easing: T.easeExit, fill: 'forwards' });
      a.onfinish = finish;
    } else { finish(); }
  }

  /* ---------- Lenis smooth scroll ---------- */
  function initLenis() {
    if (reduced || typeof window.Lenis === 'undefined') return;
    var lenis = new window.Lenis({ lerp: T.scrollLerp });
    function raf(time) { lenis.raf(time); window.requestAnimationFrame(raf); }
    window.requestAnimationFrame(raf);
  }

  /* ---------- reveal on scroll ---------- */
  function initReveal() {
    var els = document.querySelectorAll('[data-reveal]');
    if (!els.length) return;
    if (reduced || typeof IntersectionObserver === 'undefined') {
      els.forEach(function (el) { el.classList.add('revealed'); });
      return;
    }
    var margin = '0px 0px -' + T.revealOffsetPct + '% 0px';
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        var el = entry.target;
        el.classList.add('revealed');
        animate(el, { opacity: [0, 1], transform: ['translateY(' + T.revealDistance + 'px)', 'translateY(0px)'] },
          { duration: T.enterDefault, easing: T.easeEnter, cubic: [0.2, 0, 0, 1] });
        io.unobserve(el);
      });
    }, { rootMargin: margin });
    els.forEach(function (el) { io.observe(el); });
  }

  /* ---------- state switcher (mockup-only) ---------- */
  function applyState(state, opts) {
    document.body.setAttribute('data-screen-state', state);
    document.querySelectorAll('[data-state-panel]').forEach(function (panel) {
      var states = panel.getAttribute('data-state-panel').split(/\s+/);
      var show = states.indexOf(state) !== -1;
      if (show && panel.hidden) {
        panel.hidden = false;
        if (!(opts && opts.initial)) {
          enterEl(panel);
          panel.querySelectorAll('[data-stagger]').forEach(function (c) { staggerChildren(c); });
        }
      } else if (!show) {
        panel.hidden = true;
      }
    });
    document.querySelectorAll('.state-switcher [data-set-state]').forEach(function (btn) {
      btn.setAttribute('aria-pressed', String(btn.getAttribute('data-set-state') === state));
    });
  }

  function initStateSwitcher() {
    var switcher = document.querySelector('.state-switcher');
    var initial = document.body.getAttribute('data-screen-state') || 'ideal';
    applyState(initial, { initial: true });
    if (!switcher) return;
    switcher.addEventListener('click', function (e) {
      var btn = e.target.closest('[data-set-state]');
      if (btn) applyState(btn.getAttribute('data-set-state'));
    });
  }

  /* ---------- paid/unpaid demo toggles (REQ-005 feel) ---------- */
  // Any element: <button data-toggle-paid aria-pressed="false"> next to a
  // .badge — flips badge classes/text and plays the emphasis on flip-to-paid.
  function initPaidToggles() {
    document.addEventListener('click', function (e) {
      var btn = e.target.closest('[data-toggle-paid]');
      if (!btn) return;
      var scope = btn.closest('[data-invoice-row]') || document;
      var badge = scope.querySelector('.badge');
      if (!badge) return;
      var makingPaid = badge.classList.contains('badge-unpaid');
      badge.classList.toggle('badge-unpaid', !makingPaid);
      badge.classList.toggle('badge-paid', makingPaid);
      badge.textContent = makingPaid ? 'Paid' : 'Unpaid';
      btn.textContent = makingPaid ? 'Mark unpaid' : 'Mark paid';
      var live = document.getElementById('status-live');
      var label = scope.getAttribute('data-invoice-label') || 'Invoice';
      if (live) live.textContent = label + (makingPaid ? ' marked paid' : ' marked unpaid');
      var stamp = scope.querySelector('.doc-stamp');
      if (stamp) {
        stamp.classList.toggle('unpaid', !makingPaid);
        stamp.classList.toggle('paid', makingPaid);
        stamp.textContent = makingPaid ? 'Paid' : 'Unpaid';
      }
      var paidDateEl = scope.querySelector('[data-paid-date]');
      if (paidDateEl) {
        paidDateEl.hidden = !makingPaid;
        if (makingPaid) enterFastEl(paidDateEl);
      }
      if (makingPaid) emphasize(badge); // emphasis is paid-only per motion-spec
    });
  }

  /* ---------- first paint ---------- */
  function firstPaint() {
    var hero = document.querySelectorAll('[data-hero-step]');
    if (hero.length) heroSequence(Array.prototype.slice.call(hero));
    document.querySelectorAll('[data-enter]').forEach(function (el) { enterEl(el); });
    document.querySelectorAll('[data-stagger]').forEach(function (c) {
      // Only stagger containers visible at load (state panels handle their own)
      if (!c.closest('[hidden]')) staggerChildren(c);
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    initLenis();
    initStateSwitcher();
    initReveal();
    initPaidToggles();
    firstPaint();
  });

  // Shared helpers for per-page scripts
  window.LedgerlyMotion = {
    tokens: T,
    reduced: reduced,
    enter: enterEl,
    enterFast: enterFastEl,
    exit: exitEl,
    stagger: staggerChildren,
    emphasize: emphasize,
    applyState: applyState
  };
})();
