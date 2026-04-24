(function () {
  try {
    var host = window.location.hostname || "";
    var path = window.location.pathname || "";
    var isYouTubeHost =
      /(^|\.)youtube\.com$/.test(host) || /(^|\.)youtube-nocookie\.com$/.test(host);
    if (!isYouTubeHost || path.indexOf("/embed/") !== 0) {
      return;
    }
    if (window.__netlessYouTubeLayoutFixInstalled) {
      return;
    }

    window.__netlessYouTubeLayoutFixInstalled = true;

    var enableLogging = __ENABLE_LOGGING__;
    var isActive = true;
    var debounceTimer = 0;
    var resizeObserver = null;
    var domObserver = null;
    var boundVideo = null;
    var observedPlayer = null;
    var lastAppliedLogSignature = "";
    var lastAppliedLogAt = 0;
    var repeatedLogInterval = 1500;
    var videoEvents = ["loadedmetadata", "loadeddata", "canplay", "playing"];

    function log(action, payload) {
      try {
        if (!enableLogging) {
          return;
        }
        if (payload) {
          console.log(
            "[WhiteYTLayoutFix]",
            JSON.stringify({ action: action, payload: payload })
          );
        } else {
          console.log("[WhiteYTLayoutFix]", action);
        }
      } catch (_error) {}
    }

    function getPlayer() {
      return document.querySelector(".html5-video-player");
    }

    function getVideo() {
      return document.querySelector("video.video-stream.html5-main-video");
    }

    function round(value) {
      return Math.round(value);
    }

    function teardown(reason) {
      if (!isActive) {
        return;
      }
      isActive = false;
      if (debounceTimer) {
        window.clearTimeout(debounceTimer);
        debounceTimer = 0;
      }
      if (resizeObserver) {
        resizeObserver.disconnect();
        resizeObserver = null;
      }
      if (domObserver) {
        domObserver.disconnect();
        domObserver = null;
      }
      if (boundVideo) {
        videoEvents.forEach(function (eventName) {
          boundVideo.removeEventListener(eventName, onVideoEvent);
        });
        boundVideo = null;
      }
      observedPlayer = null;
      log("teardown", { reason: reason });
    }

    function getExpectedBox(player, video) {
      var playerWidth = player.clientWidth || player.getBoundingClientRect().width;
      var playerHeight = player.clientHeight || player.getBoundingClientRect().height;
      var videoWidth = video.videoWidth;
      var videoHeight = video.videoHeight;
      if (!playerWidth || !playerHeight || !videoWidth || !videoHeight) {
        return null;
      }

      var playerRatio = playerWidth / playerHeight;
      var videoRatio = videoWidth / videoHeight;
      var width = 0;
      var height = 0;
      var left = 0;
      var top = 0;

      if (videoRatio >= playerRatio) {
        width = playerWidth;
        height = playerWidth / videoRatio;
        left = 0;
        top = (playerHeight - height) / 2;
      } else {
        width = playerHeight * videoRatio;
        height = playerHeight;
        left = (playerWidth - width) / 2;
        top = 0;
      }

      return {
        width: round(width),
        height: round(height),
        left: round(left),
        top: round(top),
        playerWidth: round(playerWidth),
        playerHeight: round(playerHeight),
        videoWidth: round(videoWidth),
        videoHeight: round(videoHeight),
      };
    }

    function getActualBox(player, video) {
      var playerRect = player.getBoundingClientRect();
      var videoRect = video.getBoundingClientRect();
      return {
        width: round(videoRect.width),
        height: round(videoRect.height),
        left: round(videoRect.left - playerRect.left),
        top: round(videoRect.top - playerRect.top),
      };
    }

    function boxNeedsCorrection(actual, expected) {
      return (
        Math.abs(actual.width - expected.width) > 2 ||
        Math.abs(actual.height - expected.height) > 2 ||
        Math.abs(actual.left - expected.left) > 2 ||
        Math.abs(actual.top - expected.top) > 2
      );
    }

    function applyCorrection(reason) {
      if (!isActive) {
        return false;
      }

      var player = getPlayer();
      var video = getVideo();
      if (!player || !video || !player.isConnected || !video.isConnected) {
        return false;
      }

      var expected = getExpectedBox(player, video);
      if (!expected) {
        return false;
      }

      var actual = getActualBox(player, video);
      if (!boxNeedsCorrection(actual, expected)) {
        return false;
      }

      video.style.width = expected.width + "px";
      video.style.height = expected.height + "px";
      video.style.left = expected.left + "px";
      video.style.top = expected.top + "px";

      var logSignature = [
        actual.width,
        actual.height,
        actual.left,
        actual.top,
        expected.width,
        expected.height,
        expected.left,
        expected.top,
        expected.playerWidth,
        expected.playerHeight,
        expected.videoWidth,
        expected.videoHeight,
      ].join("|");
      var now = Date.now();

      if (
        logSignature !== lastAppliedLogSignature ||
        now - lastAppliedLogAt > repeatedLogInterval
      ) {
        lastAppliedLogSignature = logSignature;
        lastAppliedLogAt = now;
        log("applied", {
          reason: reason,
          actual: actual,
          expected: {
            width: expected.width,
            height: expected.height,
            left: expected.left,
            top: expected.top,
          },
          player: {
            width: expected.playerWidth,
            height: expected.playerHeight,
          },
          video: {
            width: expected.videoWidth,
            height: expected.videoHeight,
          },
        });
      }

      return true;
    }

    function schedule(reason) {
      if (!isActive) {
        return;
      }
      if (debounceTimer) {
        window.clearTimeout(debounceTimer);
      }
      debounceTimer = window.setTimeout(function () {
        debounceTimer = 0;
        applyCorrection(reason);
      }, 500);
    }

    function onVideoEvent() {
      schedule("video-event");
    }

    function bindVideo(video) {
      if (!isActive) {
        return;
      }
      if (boundVideo === video) {
        return;
      }
      if (boundVideo) {
        videoEvents.forEach(function (eventName) {
          boundVideo.removeEventListener(eventName, onVideoEvent);
        });
      }
      boundVideo = video;
      if (!boundVideo) {
        return;
      }
      videoEvents.forEach(function (eventName) {
        boundVideo.addEventListener(eventName, onVideoEvent);
      });
    }

    function ensureObservers() {
      if (!isActive) {
        return;
      }

      var player = getPlayer();
      var video = getVideo();
      bindVideo(video);

      if (!player || !video) {
        startDomObserver();
        return;
      }

      if (domObserver) {
        domObserver.disconnect();
        domObserver = null;
      }

      if (resizeObserver && observedPlayer !== player) {
        resizeObserver.disconnect();
        resizeObserver = null;
        observedPlayer = null;
      }

      if (!resizeObserver && window.ResizeObserver) {
        observedPlayer = player;
        resizeObserver = new ResizeObserver(function () {
          schedule("player-resize");
        });
        resizeObserver.observe(document.documentElement);
        if (document.body) {
          resizeObserver.observe(document.body);
        }
        resizeObserver.observe(player);
      }

      schedule("bootstrap");
    }

    function startDomObserver() {
      if (
        !isActive ||
        domObserver ||
        !window.MutationObserver ||
        !document.documentElement
      ) {
        return;
      }
      domObserver = new MutationObserver(function () {
        ensureObservers();
      });
      domObserver.observe(document.documentElement, {
        childList: true,
        subtree: true,
      });
    }

    function onControlMessage(event) {
      var data = event.data;
      if (!data || typeof data !== "object") {
        return;
      }
      var payload = data.__netlessYouTubeLayoutFixControl;
      if (!payload || typeof payload !== "object") {
        return;
      }
      if (payload.type === "teardown") {
        teardown(payload.reason || "parent-message");
      }
    }

    window.addEventListener("message", onControlMessage);
    window.addEventListener(
      "resize",
      function () {
        schedule("window-resize");
      },
      { passive: true }
    );
    window.addEventListener("pagehide", function () {
      teardown("pagehide");
    });
    window.addEventListener("unload", function () {
      teardown("unload");
    });

    ensureObservers();
  } catch (error) {
    try {
      console.warn(
        "[WhiteYTLayoutFix] init-failed",
        error && error.message ? error.message : String(error)
      );
    } catch (_error) {}
  }
})();
