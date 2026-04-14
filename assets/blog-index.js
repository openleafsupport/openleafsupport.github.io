(function () {
  var recentCarousel = document.querySelector('[data-recent-carousel]');
  var recentSlides = Array.prototype.slice.call(document.querySelectorAll('[data-recent-slide]'));
  var recentDots = Array.prototype.slice.call(document.querySelectorAll('[data-recent-dot]'));
  var recentPrev = document.querySelector('[data-recent-prev]');
  var recentNext = document.querySelector('[data-recent-next]');
  var dataEl = document.getElementById('blog-posts-data');
  var grid = document.getElementById('blog-grid');
  var emptyState = document.getElementById('blog-empty');
  var results = document.getElementById('blog-results-count');
  var search = document.getElementById('blog-search');
  var year = document.getElementById('blog-year');
  var month = document.getElementById('blog-month');
  var tag = document.getElementById('blog-tag');
  var toolbar = document.querySelector('.blog-toolbar');
  var sentinel = document.getElementById('blog-scroll-sentinel');
  var categoryButtons = Array.prototype.slice.call(document.querySelectorAll('[data-category-filter]'));
  var jumpButtons = Array.prototype.slice.call(document.querySelectorAll('[data-category-jump]'));
  var pageSize = 5;
  var recentIndex = 0;
  var swipeStartX = null;
  var swipeStartY = null;
  var swipeThreshold = 48;

  function setRecentSlide(index) {
    if (!recentSlides.length) return;

    if (index < 0) index = recentSlides.length - 1;
    if (index >= recentSlides.length) index = 0;
    recentIndex = index;

    recentSlides.forEach(function (slide, slideIndex) {
      var active = slideIndex === index;
      slide.hidden = !active;
      slide.classList.toggle('is-active', active);
    });

    recentDots.forEach(function (dot, dotIndex) {
      var active = dotIndex === index;
      dot.classList.toggle('is-active', active);
      dot.setAttribute('aria-pressed', active ? 'true' : 'false');
    });
  }

  recentDots.forEach(function (dot) {
    dot.addEventListener('click', function () {
      setRecentSlide(Number(dot.getAttribute('data-recent-dot') || 0));
    });
  });

  if (recentPrev) {
    recentPrev.addEventListener('click', function () {
      setRecentSlide(recentIndex - 1);
    });
  }

  if (recentNext) {
    recentNext.addEventListener('click', function () {
      setRecentSlide(recentIndex + 1);
    });
  }

  function handleSwipeEnd(endX, endY) {
    if (swipeStartX === null || swipeStartY === null) return;
    var deltaX = endX - swipeStartX;
    var deltaY = endY - swipeStartY;

    swipeStartX = null;
    swipeStartY = null;

    if (Math.abs(deltaX) < swipeThreshold || Math.abs(deltaX) < Math.abs(deltaY)) return;
    setRecentSlide(deltaX < 0 ? recentIndex + 1 : recentIndex - 1);
  }

  if (recentCarousel) {
    recentCarousel.addEventListener('touchstart', function (event) {
      if (!event.touches[0]) return;
      swipeStartX = event.touches[0].clientX;
      swipeStartY = event.touches[0].clientY;
    }, { passive: true });

    recentCarousel.addEventListener('touchend', function (event) {
      if (!event.changedTouches[0]) return;
      handleSwipeEnd(event.changedTouches[0].clientX, event.changedTouches[0].clientY);
    }, { passive: true });

    recentCarousel.addEventListener('pointerdown', function (event) {
      if (event.pointerType !== 'mouse' && event.pointerType !== 'pen') return;
      swipeStartX = event.clientX;
      swipeStartY = event.clientY;
    });

    recentCarousel.addEventListener('pointerup', function (event) {
      if (swipeStartX === null) return;
      handleSwipeEnd(event.clientX, event.clientY);
    });

    recentCarousel.addEventListener('pointerleave', function () {
      swipeStartX = null;
      swipeStartY = null;
    });
  }

  if (recentSlides.length) {
    setRecentSlide(0);
  }

  if (!dataEl || !grid || !results) return;

  var posts = JSON.parse(dataEl.textContent || '[]').sort(function (a, b) {
    return new Date(b.date) - new Date(a.date);
  });

  var state = { query: '', year: '', month: '', tag: '', category: 'All', visible: pageSize };

  function filteredPosts() {
    return posts.filter(function (post) {
      var haystack = [post.title, post.description, post.category, post.categoryLabel || ''].join(' ').toLowerCase();
      var matchesQuery = !state.query || haystack.indexOf(state.query) !== -1;
      var matchesYear = !state.year || post.year === state.year;
      var matchesMonth = !state.month || post.month === state.month;
      var matchesCategory = state.category === 'All' || post.category === state.category;
      var matchesTag = !state.tag || (post.tags && post.tags.indexOf(state.tag) !== -1);
      return matchesQuery && matchesYear && matchesMonth && matchesCategory && matchesTag;
    });
  }

  function populateYears() {
    var years = [];
    posts.forEach(function (post) {
      if (years.indexOf(post.year) === -1) years.push(post.year);
    });
    years.sort(function (a, b) { return Number(b) - Number(a); });
    years.forEach(function (value) {
      var option = document.createElement('option');
      option.value = value;
      option.textContent = value;
      year.appendChild(option);
    });
  }

  function populateMonths() {
    var months = [];
    posts.forEach(function (post) {
      if (state.year && post.year !== state.year) return;
      if (!months.some(function (item) { return item.value === post.month; })) {
        months.push({ value: post.month, label: post.monthName });
      }
    });

    months.sort(function (a, b) { return Number(b.value) - Number(a.value); });
    month.innerHTML = '<option value="">All months</option>';

    months.forEach(function (item) {
      var option = document.createElement('option');
      option.value = item.value;
      option.textContent = item.label;
      month.appendChild(option);
    });

    if (state.month && !months.some(function (item) { return item.value === state.month; })) {
      state.month = '';
      month.value = '';
    }
  }

  function populateTags() {
    var tags = [];
    posts.forEach(function (post) {
      if (!post.tags) return;
      post.tags.forEach(function (t) {
        if (tags.indexOf(t) === -1) tags.push(t);
      });
    });
    tags.sort(function (a, b) { return a.toLowerCase().localeCompare(b.toLowerCase()); });
    tag.innerHTML = '<option value="">All topics</option>';
    tags.forEach(function (t) {
      var option = document.createElement('option');
      option.value = t;
      option.textContent = t;
      tag.appendChild(option);
    });

    if (state.tag && tags.indexOf(state.tag) === -1) {
      state.tag = '';
      tag.value = '';
    }
  }

  function updateCategoryButtons() {
    categoryButtons.forEach(function (button) {
      var active = button.getAttribute('data-category-filter') === state.category;
      button.classList.toggle('is-active', active);
      button.setAttribute('aria-pressed', active ? 'true' : 'false');
    });
  }

  function escapeHtml(value) {
    return String(value)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function renderCard(post) {
    return [
      '<article class="blog-card">',
      '<a class="blog-card-image-link" href="', escapeHtml(post.url), '">',
      '<img class="blog-card-image" src="', escapeHtml(post.coverImage), '" alt="', escapeHtml(post.coverImageAlt), '" width="640" height="400" loading="lazy" decoding="async">',
      '</a>',
      '<div class="blog-card-body">',
      '<div class="blog-card-top">',
      '<span class="blog-card-category">', escapeHtml(post.categoryLabel || post.category), '</span>',
      '<span class="blog-card-date">', escapeHtml(post.displayDate), '</span>',
      '</div>',
      '<h3 class="blog-card-title"><a href="', escapeHtml(post.url), '">', escapeHtml(post.title), '</a></h3>',
      '<p class="blog-card-desc">', escapeHtml(post.description), '</p>',
      '<a class="blog-card-link" href="', escapeHtml(post.url), '">Read post</a>',
      '</div>',
      '</article>'
    ].join('');
  }

  function render() {
    var matches = filteredPosts();
    var visiblePosts = matches.slice(0, state.visible);
    grid.innerHTML = visiblePosts.map(renderCard).join('');
    if (window.applyImageFallbacks) {
      window.applyImageFallbacks(grid);
    }
    emptyState.hidden = matches.length !== 0;
    results.textContent = matches.length ? 'Showing ' + visiblePosts.length + ' of ' + matches.length + ' posts.' : 'No posts found for this filter.';

    if (sentinel) {
      sentinel.hidden = visiblePosts.length >= matches.length;
    }
  }

  function resetAndRender() {
    state.visible = pageSize;
    render();
  }

  function loadNextPage() {
    var matches = filteredPosts();
    if (state.visible >= matches.length) return;
    state.visible += pageSize;
    render();
  }

  if (search) {
    search.addEventListener('input', function () {
      state.query = search.value.trim().toLowerCase();
      resetAndRender();
    });
  }

  if (toolbar) {
    toolbar.addEventListener('submit', function (event) {
      event.preventDefault();
    });
  }

  if (year) {
    year.addEventListener('change', function () {
      state.year = year.value;
      populateMonths();
      resetAndRender();
    });
  }

  if (month) {
    month.addEventListener('change', function () {
      state.month = month.value;
      resetAndRender();
    });
  }

  if (tag) {
    tag.addEventListener('change', function () {
      state.tag = tag.value;
      resetAndRender();
    });
  }

  categoryButtons.forEach(function (button) {
    button.addEventListener('click', function () {
      state.category = button.getAttribute('data-category-filter') || 'All';
      updateCategoryButtons();
      resetAndRender();
    });
  });

  jumpButtons.forEach(function (button) {
    button.addEventListener('click', function () {
      state.category = button.getAttribute('data-category-jump') || 'All';
      updateCategoryButtons();
      resetAndRender();
      var explorer = document.getElementById('explore');
      if (explorer) explorer.scrollIntoView({ behavior: 'smooth', block: 'start' });
    });
  });

  if ('IntersectionObserver' in window && sentinel) {
    var observer = new IntersectionObserver(function (entries) {
      if (!entries[0] || !entries[0].isIntersecting) return;
      loadNextPage();
    }, { rootMargin: '220px 0px' });
    observer.observe(sentinel);
  } else if (sentinel) {
    window.addEventListener('scroll', function () {
      if (sentinel.hidden) return;
      var rect = sentinel.getBoundingClientRect();
      if (rect.top <= window.innerHeight + 220) {
        loadNextPage();
      }
    }, { passive: true });
  }

  populateYears();
  populateMonths();
  populateTags();
  updateCategoryButtons();
  render();
})();