(function () {
  function enhanceExternalLinks(root) {
    var scope = root || document;
    var links = scope.querySelectorAll('a[href]');

    Array.prototype.forEach.call(links, function (link) {
      var href = link.getAttribute('href');
      if (!href || href.indexOf('http://') !== 0 && href.indexOf('https://') !== 0) return;

      try {
        var url = new URL(href, window.location.href);
        if (url.origin === window.location.origin) return;
      } catch (error) {
        return;
      }

      link.setAttribute('target', '_blank');

      var rel = (link.getAttribute('rel') || '').split(/\s+/).filter(Boolean);
      ['noopener', 'noreferrer'].forEach(function (value) {
        if (rel.indexOf(value) === -1) rel.push(value);
      });
      link.setAttribute('rel', rel.join(' '));
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    enhanceExternalLinks(document);
  });

  window.enhanceExternalLinks = enhanceExternalLinks;
})();