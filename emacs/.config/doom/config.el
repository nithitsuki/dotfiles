;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;;2 min experience review: I love it
(setq evil-escape-key-sequence "jk")
(map! :i (kbd "C-[") #'evil-normal-state)
;; I sometimes overshoot ctrl [ . Neeed to get a biggger keyboard
(map! :i (kbd "C-]") #'evil-normal-state)
 
;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
(setq doom-font (font-spec :family "SF Mono" :size 14)
      doom-variable-pitch-font (font-spec :family "SF Mono" :size 16))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; (setq doom-theme 'doom-acario-dark)
(load-theme 'base16-3024 t)

(set-frame-parameter nil 'alpha-background 30) ; For current frame
(add-to-list 'default-frame-alist '(alpha-background . 85)) ; For all new frames henceforth
(set-face-attribute 'default nil :height 130)
(setq confirm-kill-emacs nil)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Documents/life2/")
(setq org-agenda-span 48)
;; org configs
    ;; Improve org mode looks
    (setq-default org-startup-indented t
                  org-pretty-entities t
                  org-use-sub-superscripts "{}"
                  org-hide-emphasis-markers t
                  org-startup-with-inline-images t
                  org-image-actual-width '(300))

(setq-default line-spacing 2)

;;(add-hook 'org-mode-hook 'olivetti-mode)

;;Better Headers
;; (let* ((variable-tuple (cond ((x-list-fonts "SF Mono") '(:font "Source Sans Pro"))
;;                              ((x-list-fonts "Lucida Grande")   '(:font "Lucida Grande"))
;;                              ((x-list-fonts "Verdana")         '(:font "Verdana"))
;;                              ((x-family-fonts "Sans Serif")    '(:family "Sans Serif"))
;;                              (nil (warn "Cannot find a Sans Serif Font.  Install SF Mono."))))
       ;; (base-font-color     (face-foreground 'default nil 'default))
       ;; (headline           `(:inherit default :weight bold :foreground ,base-font-color)))



;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
  (use-package org-modern
    :hook
    (org-mode . global-org-modern-mode)
    :custom
    (org-modern-keyword nil)
    ;;(org-modern-checkbox nil)
    ;;(org-modern-table nil)
    ;;(org-modern--star nil)
    )
(with-eval-after-load 'org (global-org-modern-mode))
;;(add-hook 'org-mode-hook 'olivetti-mode)

;; (after! projectile (setq projectile-project-root-files-bottom-up (remove ".git"
;;           projectile-project-root-files-bottom-up)))

(use-package! perfect-margin
  :config
   (after! doom-modeline
     (setq mode-line-right-align-edge 'right-fringe))
  ;; (setq perfect-margin-only-set-left-margin t)
  (perfect-margin-mode t)
  (setq perfect-margin-visible-width 98)
)

(setq org-capture-templates '(
    ("j" "Journal Entry"
         entry (file+datetree "~/Documents/life2/Jounral.org")
         "* Event: %?\n\n  %i\n\n  From: %a"
         :empty-lines 1)
))

(use-package! org-habit
  :after org
  :config
  (setq org-habit-following-days 1
        org-habit-preceding-days 3
        org-habit-show-habits t))

;; gpt.el config
(use-package! gptel
 :config
 (setq! gptel-api-key (getenv "OPENAI_API_KEY"))
 (gptel-make-anthropic "Personal Claude";Any name you want
  :stream t                             ;Streaming responses
  :key (getenv "CLAUDE_KEY"))
 (gptel-make-gh-copilot "Copilot")
)

;; terminal transparency
(defun on-after-init ()
  (unless (display-graphic-p (selected-frame))
    (set-face-background 'default "unspecified-bg" (selected-frame))
    (set-face-background 'minibuffer "unspecified-bg" (selected-frame))
    (set-face-background 'header-line "unspecified-bg" (selected-frame))))
(add-hook 'window-setup-hook #'on-after-init)
