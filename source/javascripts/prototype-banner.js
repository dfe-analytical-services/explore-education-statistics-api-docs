(function () {
  const h1 = document.querySelector('h1');

  const banner = document.createElement('div');

  banner.innerHTML =
'<div class="govuk-notification-banner" role="region" aria-labelledby="prototype-banner-title">' +
  '<div class="govuk-notification-banner__header">' +
    '<h2 class="govuk-notification-banner__title" id="prototype-banner-title">' +
      'Warning' +
    '</h2>' +
  '</div>' +
  '<div class="govuk-notification-banner__content">' +
    '<p class="govuk-notification-banner__heading">' +
      'This documentation is under development and should not be used.' +
    '</p>' +
    '<p>If you\'re interested in using the API in the future, please contact ' +
      '<a href="mailto:explore.statistics@education.gov.uk">explore.statistics@education.gov.uk</a>.' +
    '</p>' +
  '</div>' +
'</div>';

  h1.insertAdjacentElement('afterend', banner);
})();
