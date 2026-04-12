(function () {
  var selector = '.featured-post-image, .blog-card-image, .post-cover img';

  function markBroken(img) {
    if (!img) return;

    var featured = img.closest('.featured-post-layout');
    var card = img.closest('.blog-card');
    var cover = img.closest('.post-cover');

    if (featured) featured.classList.add('is-image-missing');
    if (card) card.classList.add('is-image-missing');
    if (cover) cover.classList.add('is-image-missing');
  }

  function attach(img) {
    if (!img || img.dataset.fallbackBound === 'true') return;
    img.dataset.fallbackBound = 'true';

    img.addEventListener('error', function () {
      markBroken(img);
    });

    if (img.complete && img.naturalWidth === 0) {
      markBroken(img);
    }
  }

  window.applyImageFallbacks = function (root) {
    var scope = root || document;
    Array.prototype.forEach.call(scope.querySelectorAll(selector), attach);
  };

  document.addEventListener('DOMContentLoaded', function () {
    window.applyImageFallbacks(document);
  });
})();