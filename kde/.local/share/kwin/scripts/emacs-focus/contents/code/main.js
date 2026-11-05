// The Emacs daemon creates a frame for emacsclient, so KWin cannot link the
// window to the launch and does not activate it.  Activate it here.
function activateEmacs(window) {
    if (window.resourceClass === "emacs" || window.desktopFileName === "emacs") {
        workspace.activeWindow = window;
    }
}

workspace.windowAdded.connect(activateEmacs);
