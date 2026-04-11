(function () {
  var form = document.querySelector('[data-listmonk-form]');
  if (!form) return;

  var status = form.querySelector('[data-newsletter-status]');
  var submit = form.querySelector('button[type="submit"]');
  var url = (form.getAttribute('data-listmonk-url') || '').replace(/\/$/, '');
  var listUuid = form.getAttribute('data-listmonk-list') || '';

  function setStatus(message) {
    if (status) status.textContent = message || '';
  }

  if (!url || !listUuid) {
    if (submit) {
      submit.disabled = true;
      submit.setAttribute('aria-disabled', 'true');
    }
    setStatus('Newsletter signup will go live once the Listmonk URL and list UUID are configured.');
    return;
  }

  form.addEventListener('submit', async function (event) {
    event.preventDefault();

    var name = (form.elements.name.value || '').trim();
    var email = (form.elements.email.value || '').trim();

    if (!email) {
      setStatus('Please enter your email address.');
      return;
    }

    if (submit) {
      submit.disabled = true;
      submit.setAttribute('aria-disabled', 'true');
    }
    setStatus('Subscribing...');

    try {
      var response = await fetch(url + '/api/public/subscription', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: email,
          name: name,
          list_uuids: [listUuid]
        })
      });

      if (!response.ok) {
        throw new Error('Subscription failed');
      }

      form.reset();
      setStatus('Thanks for subscribing. Please check your inbox for confirmation if double opt-in is enabled.');
    } catch (error) {
      setStatus('Subscription could not be completed right now. Please try again later or use email instead.');
    } finally {
      if (submit) {
        submit.disabled = false;
        submit.removeAttribute('aria-disabled');
      }
    }
  });
})();