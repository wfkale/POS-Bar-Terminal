(function () {
  var deployedVersion = typeof serviceWorkerVersion !== 'undefined' ? serviceWorkerVersion : null;
  var updateBannerShown = false;
  var pendingWorker = null;
  var reloadOnControllerChange = false;

  function showUpdateBanner(worker) {
    if (updateBannerShown) return;
    updateBannerShown = true;
    if (worker) pendingWorker = worker;
    var banner = document.getElementById('pwa-update-banner');
    if (banner) banner.classList.add('visible');
  }

  function applyUpdate() {
    reloadOnControllerChange = true;
    if (pendingWorker) {
      pendingWorker.postMessage('skipWaiting');
      return;
    }
    window.location.reload();
  }

  function bindUpdateButton() {
    var button = document.getElementById('pwa-update-reload');
    if (button) button.addEventListener('click', applyUpdate);
  }

  function watchServiceWorker(registration) {
    if (registration.waiting) showUpdateBanner(registration.waiting);

    registration.addEventListener('updatefound', function () {
      var worker = registration.installing;
      if (!worker) return;
      worker.addEventListener('statechange', function () {
        if (worker.state === 'installed' && navigator.serviceWorker.controller) {
          showUpdateBanner(registration.waiting);
        }
      });
    });
  }

  function checkRemoteVersion() {
    if (!deployedVersion || deployedVersion === '__SW_VERSION__') return;
    fetch('/version.json?_=' + Date.now(), { cache: 'no-store' })
      .then(function (response) { return response.ok ? response.json() : null; })
      .then(function (data) {
        if (data && data.version && data.version !== deployedVersion) {
          showUpdateBanner();
        }
      })
      .catch(function () {});
  }

  function pollForUpdates() {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.ready
        .then(function (registration) { return registration.update(); })
        .catch(function () {});
    }
    checkRemoteVersion();
  }

  bindUpdateButton();

  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.addEventListener('controllerchange', function () {
      if (reloadOnControllerChange) window.location.reload();
    });

    navigator.serviceWorker.ready.then(function (registration) {
      watchServiceWorker(registration);
      registration.update().catch(function () {});
    });

    document.addEventListener('visibilitychange', function () {
      if (!document.hidden) pollForUpdates();
    });

    setInterval(pollForUpdates, 5 * 60 * 1000);
  } else {
    setInterval(checkRemoteVersion, 5 * 60 * 1000);
  }

  checkRemoteVersion();
})();
