(function () {
  var root = document.documentElement;
  var storageKey = 'theme_mode';
  var mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  var toggle = document.querySelector('[data-theme-toggle]');

  function storedMode() {
    try {
      var stored = localStorage.getItem(storageKey);
      if (stored === 'dark' || stored === 'light') return stored;
    } catch (error) {
      // Ignore storage errors.
    }

    var current = root.getAttribute('data-theme');
    if (current === 'dark' || current === 'light') return current;
    return mediaQuery.matches ? 'dark' : 'light';
  }

  function updateToggle(mode) {
    if (!toggle) return;

    var nextMode = mode === 'dark' ? 'light' : 'dark';
    var label = nextMode === 'dark' ? 'Switch to dark theme' : 'Switch to light theme';

    toggle.setAttribute('aria-label', label);
    toggle.setAttribute('title', label);
  }

  function applyTheme(mode, persist) {
    root.setAttribute('data-theme-mode', mode);
    root.setAttribute('data-theme', mode);
    root.style.colorScheme = mode;

    if (persist) {
      try {
        localStorage.setItem(storageKey, mode);
      } catch (error) {
        // Ignore storage errors.
      }
    }

    updateToggle(mode);
  }

  if (toggle) {
    toggle.addEventListener('click', function () {
      var current = root.getAttribute('data-theme') === 'dark' ? 'dark' : 'light';
      applyTheme(current === 'dark' ? 'light' : 'dark', true);
    });
  }

  applyTheme(storedMode(), false);
})();