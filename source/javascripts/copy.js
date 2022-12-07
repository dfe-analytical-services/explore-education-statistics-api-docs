(function () {
  function Copy($module) {
    this.$module = $module
  }

  Copy.prototype.init = function () {
    var $module = this.$module

    if (!$module) {
      return
    }

    // Bail if no clipboard support (e.g. IE11)
    if (!navigator.clipboard) {
      return;
    }

    var $button = document.createElement('button')
    $button.className = 'app-copy-button js-copy-button'
    $button.setAttribute('aria-live', 'assertive')
    $button.textContent = 'Copy code'

    $module.insertAdjacentElement('beforebegin', $button)

    $button.addEventListener('click', this.handleCopy)
  }

  Copy.prototype.handleCopy = function (event) {
    var target = event.target.nextElementSibling;

    navigator.clipboard.writeText(target.textContent)
      .then(function () {
        event.target.textContent = 'Code copied';

        setTimeout(function () {
          event.target.textContent = 'Copy code';
        }, 5000);
      })
      .catch(function (err) {
        console.error(err);
      })
  }

  document.querySelectorAll('pre.highlight')
    .forEach(function ($el) {
      new Copy($el).init();
    });
})();
