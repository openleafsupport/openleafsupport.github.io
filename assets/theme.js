(function () {
  var root = document.documentElement;
  var storageKey = 'theme_mode';
  var mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  var buttons = document.querySelectorAll('[data-theme-control]');

  function storedMode() {
    try {
      return localStorage.getItem(storageKey) || root.getAttribute('data-theme-mode') || 'system';
    } catch (error) {
      return root.getAttribute('data-theme-mode') || 'system';
    }
  }

  function resolveMode(mode) {
    if (mode === 'dark') return 'dark';
    if (mode === 'light') return 'light';
    return mediaQuery.matches ? 'dark' : 'light';
  }

  function updateButtons(mode) {
    buttons.forEach(function (button) {
      var active = button.getAttribute('data-theme-control') === mode;
      button.classList.toggle('is-active', active);
      button.setAttribute('aria-pressed', active ? 'true' : 'false');
    });
  }

  function applyTheme(mode, persist) {
    var resolved = resolveMode(mode);
    root.setAttribute('data-theme-mode', mode);
    root.setAttribute('data-theme', resolved);
    root.style.colorScheme = resolved;

    if (persist) {
      try {
        localStorage.setItem(storageKey, mode);
      } catch (error) {
        // Ignore storage errors.
      }
    }

    updateButtons(mode);
  }

  buttons.forEach(function (button) {
    button.addEventListener('click', function () {
      applyTheme(button.getAttribute('data-theme-control'), true);
    });
  });

  if (typeof mediaQuery.addEventListener === 'function') {
    mediaQuery.addEventListener('change', function () {
      if (storedMode() === 'system') applyTheme('system', false);
    });
  }

  applyTheme(storedMode(), false);
})();