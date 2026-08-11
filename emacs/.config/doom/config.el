;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;;; ============================================================================
;;; GENERAL SETTINGS
;;; ============================================================================

(setq confirm-kill-emacs nil)
(setq display-line-numbers-type t)
(setq-default line-spacing 2)

;;; ============================================================================
;;; KEYBINDINGS
;;; ============================================================================

;; Evil escape
(setq evil-escape-key-sequence "jk")
(map! :i (kbd "C-[") #'evil-normal-state)
(map! :i (kbd "C-]") #'evil-normal-state) ; overshoot guard for C-[

;;; ============================================================================
;;; UI / APPEARANCE
;;; ============================================================================

;; Theme & fonts
(setq doom-theme 'doom-1337)
(setq doom-font (font-spec :family "SF Mono" :size 14)
      doom-variable-pitch-font (font-spec :family "SF Mono" :size 16))

;; Frame transparency
(add-to-list 'default-frame-alist '(alpha-background . 85))
(set-frame-parameter nil 'alpha-background 85)

;; Terminal transparency — clear bg in non-GUI frames
(defun on-after-init ()
  (unless (display-graphic-p (selected-frame))
    (set-face-background 'default "unspecified-bg" (selected-frame))
    (set-face-background 'minibuffer "unspecified-bg" (selected-frame))
    (set-face-background 'header-line "unspecified-bg" (selected-frame))))
;; (add-hook 'window-set
;;            p-hook #'on-after-init)

;; Centering / margins
(use-package! perfect-margin
  :config
  (after! doom-modeline
    (setq mode-line-right-align-edge 'right-fringe))
  (perfect-margin-mode t)
  (setq perfect-margin-visible-width 98))

;;; ============================================================================
;;; ORG MODE
;;; ============================================================================

;;; start scratch buffers in org mode by default
(setq initial-major-mode 'org-mode)
(setq doom-scratch-initial-major-mode 'org-mode)

;;; org-directory for agenda and stuff
(after! org
  (setq org-directory "~/Documents/org/")
  ;;(setq org-startup-with-latex-preview t)
  (setq org-preview-latex-default-process 'dvisvgm)
  (setq org-format-latex-options (plist-put org-format-latex-options :scale 0.5))
)
;; --- Agenda ------------------------------------------------------------------

(org-super-agenda-mode 1)
(setq org-agenda-files (list org-directory))

;; Global super-agenda groups — applies to TODO list, daily agenda, etc.
(setq org-super-agenda-groups
      '((:name "Overdue"
         :deadline past
         :face (:foreground "#ff5555" :weight bold))
        (:name "Upcoming Deadlines"
         :deadline future)
        (:name "Scheduled"
         :scheduled future)
        (:name "Next Actions"
         :todo "NEXT")
        (:name "Critical "
         :priority "A")
        (:name "Severe "
         :priority "B")
        (:name "High "
         :priority "C")
        (:name "Waiting"
         :todo "WAITING")
        (:name "Medium "
         :priority "D")
        (:name "Low "
         :priority<= "E")
        (:name "Other Items"
         :anything t)))

;; Clean prefix: category + relative date
(defun my/agenda-date-prefix ()
  "Return relative days until deadline or scheduled date."
  (let* ((dl (org-entry-get (point) "DEADLINE"))
         (sc (org-entry-get (point) "SCHEDULED"))
         (ts (or dl sc)))
    (if ts
        (let* ((days (- (org-time-string-to-absolute ts)
                        (org-today))))
          (cond ((< days 0)
                 (if (= (abs days) 1)
                     "1 day ago"
                   (format "%d days ago" (abs days))))
                ((= days 0) "Today")
                ((= days 1) "In 1 day")
                (t (format "In %d days" days))))
      "")))

(setq org-agenda-prefix-format
      '((agenda . " %i   %(my/agenda-date-prefix)   ")
        (todo   . " %i   %(my/agenda-date-prefix)   ")
        (tags   . " %i   %(my/agenda-date-prefix)   ")
        (search . " %i")))

;; Show deadline/scheduled info inline with the item
(setq org-agenda-deadline-leaders '("!!! " "In %2dd: " "%2dd ago: ")
      org-agenda-scheduled-leaders '("" "Sched.%2dx: "))

;; Cleaner agenda appearance
(setq org-agenda-block-separator "\n─────────────────────────────────────────────────────────────"
      org-agenda-tags-column -80
      org-agenda-compact-blocks t
      org-agenda-start-with-log-mode nil
      org-agenda-skip-unavailable-files t
      org-agenda-skip-scheduled-if-done t
      org-agenda-skip-deadline-if-done t
      org-agenda-include-deadlines t
      org-deadline-warning-days 14
      org-agenda-span 14
      org-agenda-start-on-weekday nil
      org-agenda-start-day nil)

;; Show scheduled events (non-TODO) in agenda views
(setq org-agenda-entry-types '(:deadline :scheduled :timestamp :sexp)
      org-agenda-todo-list-sublevels t)

;; "e" for Everything — like TODO view but includes non-TODO scheduled items
(setq org-agenda-custom-commands
      '(("e" "Everything (TODOs + Events)"
         ((alltodo ""
                   ((org-agenda-overriding-header "All Tasks")
                    (org-agenda-sorting-strategy '(deadline-up scheduled-up priority-down))))
          (tags "SCHEDULED>=\"<today>\""
                ((org-agenda-overriding-header "\nUpcoming Events (non-TODO)")
                 (org-agenda-sorting-strategy '(scheduled-up))
                 (org-agenda-skip-function
                  '(org-agenda-skip-entry-if 'todo '("TODO" "NEXT" "WAITING" "DONE" "CANCELLED")))))))))

;; --- Priorities (A–F) --------------------------------------------------------

(defface org-priority-face-a '((t :foreground "#ff5555" :weight bold)) "Priority A")
(defface org-priority-face-b '((t :foreground "#ffb86c" :weight bold)) "Priority B")
(defface org-priority-face-c '((t :foreground "#f1fa8c" :weight bold)) "Priority C")
(defface org-priority-face-d '((t :foreground "#50fa7b" :weight bold)) "Priority D")
(defface org-priority-face-e '((t :foreground "#8be9fd" :weight bold)) "Priority E")
(defface org-priority-face-f '((t :foreground "#6272a4" :weight bold)) "Priority F")

(after! org
  (setq org-priority-highest ?A
        org-priority-lowest  ?F
        org-priority-default ?D)

  (setq org-priority-faces
        '((?A . org-priority-face-a)
          (?B . org-priority-face-b)
          (?C . org-priority-face-c)
          (?D . org-priority-face-d)
          (?E . org-priority-face-e)
          (?F . org-priority-face-f)))

  (setq org-fontify-whole-heading-line t)

  ;; Make priority colors work in agenda view
  (setq org-agenda-fontify-priorities 'cookies))

;; Prevent Doom's theme from overriding priority colors
(custom-set-faces!
  '(org-priority :inherit nil :foreground nil)
  '(org-agenda-structure :inherit nil))

;; --- Org keybindings ---------------------------------------------------------

(map! :after org
      :map org-mode-map
      :localleader

      (:prefix ("p" . "priority")
       :desc "Critical"    "a" (lambda () (interactive) (org-priority ?A))
       :desc "Severe"      "b" (lambda () (interactive) (org-priority ?B))
       :desc "High"        "c" (lambda () (interactive) (org-priority ?C))
       :desc "Medium"      "d" (lambda () (interactive) (org-priority ?D))
       :desc "Minor"       "e" (lambda () (interactive) (org-priority ?E))
       :desc "Unimportant" "f" (lambda () (interactive) (org-priority ?F)))

      (:prefix ("j" . "jira size/effort")
       :desc "XS (Tiny)"     "x" (lambda () (interactive) (org-toggle-tag "XS"))
       :desc "S  (Small)"    "s" (lambda () (interactive) (org-toggle-tag "SM"))
       :desc "M  (Medium)"   "m" (lambda () (interactive) (org-toggle-tag "MD"))
       :desc "L  (Large)"    "l" (lambda () (interactive) (org-toggle-tag "LG"))
       :desc "XL (Epic)"     "X" (lambda () (interactive) (org-toggle-tag "XL"))
       :desc "XXL(Massive)"  "z" (lambda () (interactive) (org-toggle-tag "XXL"))))

;; --- Capture templates -------------------------------------------------------

(setq org-capture-templates
      '(("j" "Journal Entry"
         entry (file+datetree "~/Documents/org/Jounral.org")
         "* Event: %?\n\n  %i\n\n  From: %a"
         :empty-lines 1)))

;; --- Org packages ------------------------------------------------------------

(use-package! org-habit
  :after org
  :config
  (setq org-habit-following-days 1
        org-habit-preceding-days 3
        org-habit-show-habits t))

(use-package! org-modern
  :hook (org-mode . global-org-modern-mode)
  :custom
  (org-modern-keyword nil)
  (org-modern-priority nil)  ; let our custom priority faces apply
  (org-modern-tag t))        ; keep tag rendering, use theme's face
(with-eval-after-load 'org (global-org-modern-mode))

;;; ============================================================================
;;; PROJECT MANAGEMENT
;;; ============================================================================

(after! projectile
  (add-to-list 'projectile-ignored-projects "~/")
  (add-to-list 'projectile-ignored-projects (expand-file-name "~")))

;;; ============================================================================
;;; AI / LLM
;;; ============================================================================

;; Shared API key for OpenCode Zen/Go (https://opencode.ai/docs/zen/):
;; OPENCODE_API_KEY env var first, then the credential the opencode CLI itself
;; uses (~/.local/share/opencode/auth.json), then the legacy credential store
;; (~/.config/opencode/service.json, "password" field).
(defun my/gptel-opencode-api-key ()
  "Return the OpenCode Zen/Go API key for gptel requests."
  (require (quote json))
  (let ((env-key (getenv "OPENCODE_API_KEY")))
    (or (and env-key (not (string-empty-p env-key)) env-key)
        (when-let* ((file (expand-file-name "~/.local/share/opencode/auth.json"))
                    (json (ignore-errors (json-read-file file)))
                    (entry (or (map-elt json 'opencode-go)
                               (map-elt json "opencode-go")))
                    (key (or (map-elt entry 'key)
                             (map-elt entry "key"))))
          (and key (not (string-empty-p key)) key))
        (when-let* ((file (expand-file-name "~/.config/opencode/service.json"))
                    (json (ignore-errors (json-read-file file))))
          (or (map-elt json 'password)
              (map-elt json "password"))))))

(use-package! gptel
  :config
  (setq! gptel-api-key (getenv "OPENAI_API_KEY"))
  (gptel-make-anthropic "Personal Claude"
    :stream t
    :key (getenv "CLAUDE_KEY"))
  (gptel-make-gh-copilot "Copilot")
  ;; OpenCode Go subscription (https://opencode.ai/docs/go/)
  ;; OpenAI-compatible endpoint. gpt-5.6-luna (responses API) and the
  ;; Qwen/MiniMax models (Anthropic-format endpoint) are not registered here.
  (gptel-make-openai "OpenCode Go"
    :host "opencode.ai"
    :endpoint "/zen/go/v1/chat/completions"
    :stream t
    :key #'my/gptel-opencode-api-key
    :models '(grok-4.5
              glm-5.2 glm-5.1
              kimi-k3 kimi-k2.7-code kimi-k2.6
              deepseek-v4-pro deepseek-v4-flash
              mimo-v2.5 mimo-v2.5-pro
              hy3))
  ;; OpenCode Zen - pay-per-use gateway (https://opencode.ai/docs/zen/),
  ;; same key as Go. Paid models bill against the Zen balance (requests fail
  ;; with a 401 auth error until credits are added); the free models
  ;; (deepseek-v4-flash-free, mimo-v2.5-free, ...) are free but their data may
  ;; be used for model training. Deprecated (glm-5, kimi-k2.5, minimax-m2.5)
  ;; and non-chat-completions models (GPT/Grok responses API, Claude/Qwen/
  ;; Gemini messages API) are not registered here.
  (gptel-make-openai "Zen"
    :host "opencode.ai"
    :endpoint "/zen/v1/chat/completions"
    :stream t
    :key #'my/gptel-opencode-api-key
    :models '(deepseek-v4-pro deepseek-v4-flash
              minimax-m3 minimax-m2.7
              glm-5.2 glm-5.1
              kimi-k3 kimi-k2.7-code kimi-k2.6
              big-pickle
              deepseek-v4-flash-free mimo-v2.5-free
              laguna-s-2.1-free ling-3.0-tiny-free
              longcat-2.0-free north-mini-code-free nemotron-3-ultra-free)))
;;(setq doom-emoji-font (font-spec :family "Segoe UI Emoji"))

;;;;
;;;; Kasane teto ASCII braile banner 
;;;;

(defun my-weebery-is-always-greater ()
  (let* ((banner '("⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠎⡼⢹⠃⠀⠀⠀⠀⠀⠀⣀⣠⡴⠾⠛⠛⠒⠈⠉⠑⠒⠒⠭⣿⠀⠀⠀⠀⠙⢄⠀⠀⠀⠀⠀⢸⠀⠀⢀⣀⣀⠀⠀⣀⣀⣀⣀⠀⠀⠀"
                   "⠀⠀⠀⠀⠀⠀⠀⠀⠀⡜⣸⠁⣾⠀⠀⢀⣠⡴⠚⠉⠈⠁⠀⠀⠀⠀⣀⣠⣤⣤⣀⡀⠀⠈⣇⠀⠐⠮⢢⡈⢦⡀⠀⠀⢀⣾⠾⠽⠓⠒⠒⠀⠀⠐⠒⠒⠚⢯⠹⡆"
                   "⠀⠀⠀⠀⠀⠀⠀⠀⢰⠃⣏⠀⡏⣠⢔⡽⠋⠀⠀⠀⠀⠀⠀⠀⠐⠉⠀⠀⠀⠀⠀⠉⠙⠲⣜⢦⣀⡀⠀⠑⡞⢹⠀⣠⠞⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡼⠞⣻"
                   "⠀⠀⠀⠀⠀⠀⠀⠀⠘⢦⣘⢦⡺⡵⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⣄⠈⠉⠑⢷⣻⡉⠁⠀⠀⠀⠀⠀⠀⢀⣀⡠⠴⢒⣋⣁⣀⢤⡇"
                   "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣨⢛⣿⠿⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠏⣳⡀⠀⠀⢣⢧⠀⠀⠀⠀⠀⠀⠈⠉⠉⠉⢁⣀⣀⣀⣼⣸⠀"
                   "⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⢣⠞⠁⠀⠀⠀⢤⠀⠀⠀⠀⠀⠀⠀⠐⡄⠀⠀⠀⠀⠀⠀⢀⣤⣺⠵⠚⠁⠹⣄⠀⠈⣿⠀⣀⣀⣤⣤⡤⠀⠀⠀⠋⠉⠛⠳⣶⢤⡄⠀"
                   "⠀⠀⠀⣀⡠⠤⠔⠒⠚⣿⠋⠀⠀⠀⠀⠀⢸⡀⠀⠀⠀⠀⠀⠀⠀⢹⡀⠀⣀⣤⡄⣠⠞⠁⠀⠀⠀⠀⠱⣜⣆⠀⢹⢫⠟⠋⠉⠀⠀⠀⠀⢀⣀⡠⠤⠔⠓⢻⠄⠀"
                   "⠤⠒⠉⠁⠀⠀⠀⠀⠐⡏⠀⠀⠀⠀⠀⠀⠀⣇⠀⠀⠀⠀⠀⣀⣠⠤⣷⣯⢟⡽⠋⠁⠀⠀⠀⠀⠀⠀⠀⠈⢿⣧⠘⡏⡇⠀⠀⠀⠀⠀⠀⠉⠛⠒⠒⠒⠲⡞⡆⠀"
                   "⠀⠀⠀⠀⠀⠀⠀⠀⠀⡷⣄⢀⣀⣀⣀⣀⣀⣿⡤⠴⠒⠚⣉⡥⠔⠊⠹⡌⠻⢄⡀⠀⢤⣀⠀⠀⠀⠀⠀⠀⠀⠳⡀⡇⢧⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣸⡇⠀"
                   "⠀⠀⠀⠀⠀⣀⡄⠀⠀⣇⣄⣀⣀⣀⣀⣠⡴⣾⠻⡖⠒⠋⠁⠀⠀⠀⠀⢹⡉⢀⣿⣷⣦⣬⣝⣻⣖⡶⠦⠤⠴⢶⣿⡇⠸⢖⣲⠶⠆⠀⠀⠀⠀⠀⠙⠫⢕⣦⡁⠀"
                   "⠀⠀⣠⠔⠊⠁⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⡞⠀⠜⢦⡠⣀⠀⠀⠀⠀⠈⢣⠸⡟⣿⢀⣤⡟⠻⡿⡇⠀⠀⠀⣏⡜⡇⠀⢸⡆⠀⠀⠀⠀⠀⠀⠀⢀⣀⣠⠷⠇⠀"
                   "⣰⣿⠓⠀⠀⠀⠀⠀⠀⣇⠀⢲⠀⠀⠀⠀⣰⢧⣷⣾⣿⣿⣾⢷⣦⢤⣀⣀⣈⣧⠀⠸⣌⣻⡧⣤⡷⣷⠀⠀⠀⣟⠀⡇⠀⠘⡇⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⣏⡳⠀"
                   "⡏⢧⠀⠀⠀⠀⠀⠀⠀⢸⠀⢸⠀⠀⠀⢠⣿⣿⠟⢹⠀⣾⡞⣇⠀⠀⠀⠀⠀⠀⠀⠀⠙⠛⠛⠉⠀⡟⠀⠀⢠⡏⢠⠃⠀⠀⢷⡠⣤⣀⡀⠀⠀⢀⣠⡤⠤⣽⠀⠀"
                   "⢱⠈⢆⠀⠀⠀⠀⠀⠀⢸⠀⡞⠀⠀⢀⠞⢿⢿⣄⠸⣄⠽⢵⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣽⠀⠀⣼⡠⠃⠀⠀⠀⠀⡞⠉⠁⠀⠀⠀⠀⠀⠹⣽⠀⠀⠀"
                   "⠀⢧⠘⡄⣀⣤⣴⡶⠆⣿⣼⠁⢀⡴⠋⠀⠈⢧⠉⠓⠈⠛⠛⠁⠀⠀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠿⢹⠀⢠⡿⠁⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠶⣟⡀⠀⠀"
                   "⠀⢸⡰⡫⣷⠟⠁⠀⠀⠟⢻⠴⠋⢻⡀⠀⠀⠈⣧⠀⠀⠀⠀⠀⠀⠀⠈⠑⠀⠀⠀⠀⡀⠀⠀⠀⠀⢸⠀⢸⠹⡀⠀⠀⠀⠀⠀⠛⠒⠦⠤⢤⣀⠀⠀⢀⡴⠃⠀⠀"
                   "⠀⠀⠘⡔⣇⠀⠀⠀⠀⠀⠀⠀⢛⠯⣷⡀⠀⠀⢹⣆⠀⠀⠀⠀⠀⠀⠀⣀⢀⣀⠤⠚⠁⠀⠀⠀⠀⢸⣀⡏⠀⠱⡄⠀⠀⠀⠀⠀⠀⠀⠀⣠⣞⠥⠖⠚⠁⠀⠀⠀"
                   "⠀⠀⠀⠘⡞⡆⠀⣀⠀⠀⠀⠀⠈⣆⣸⡳⣄⠀⠀⢟⠦⡀⠀⠀⠀⠀⠀⠉⠉⠀⠀⠀⠀⠀⠀⠀⡰⢻⡾⠑⠦⣄⣙⢦⡀⠀⠀⠀⠀⢀⡾⠋⠀⠀⠀⠀⠀⠀⠀⠀"
                   "⠀⠀⠀⠀⢹⠷⣪⠋⠀⠀⠀⠀⠀⠁⢠⠃⠈⠣⡀⠘⡆⠈⠓⢤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⠁⠈⣇⡀⠀⠀⠈⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
                   "⠀⠀⠀⠀⠀⠀⢳⠀⠀⠀⠀⣀⡤⠤⠞⠃⠀⠀⠈⠳⢼⣄⠀⠀⠀⠉⢓⣲⡤⠤⣄⣀⡴⠊⠀⠀⠀⣀⡽⠋⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
                   "⠀⠀⠀⠀⠀⠀⠈⣧⡠⠤⠤⠭⠭⠶⣤⡀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⡿⣝⣓⣒⡒⠒⢖⠲⣖⣚⣩⠥⠖⠋⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
                   "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠉⠉⢹⡀⡇⢠⢤⣴⣶⣷⠈⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
                   "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⠛⠉⠉⠛⠓⠶⣾⣿⣹⣭⣿⣧⣀⡀⠀⠀⠀⠀⡇⣇⠘⠛⠛⠋⣁⡠⣿⡲⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀" ;
                   "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡼⠋⠀⠀⠀⠀⠀⠀⠀⣸⠁⠸⣿⣷⠀⠀⠉⠙⠓⠒⠒⠳⣟⠶⣖⠋⠉⢀⣴⣿⠿⢭⣷⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
                   "⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣰⠟⠁⠀⠀⠀⠀⠀⠀⠀⢠⠇⠀⠀⢻⣿⡄⠀⠀⠀⠀⠀⣀⣴⣿⣷⣮⣙⣶⣿⠟⠁⠀⠀⢸⠈⠛⡶⠤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀"))
         (longest-line (apply #'max (mapcar #'length banner))))
    (insert 
     (propertize
      (mapconcat (lambda (line)
                   (+doom-dashboard--center
                    +doom-dashboard--width
                    (concat line (make-string (max 0 (- longest-line (length line))) 64))))
                 banner "\n")
      'face 'doom-dashboard-banner
      'line-height 0.8))))

(setq +doom-dashboard-ascii-banner-fn #'my-weebery-is-always-greater) 

(add-hook '+doom-dashboard-mode-hook
          (lambda ()
            (setq line-spacing 0)))

(setq unicode-fonts-generated-fontset-cache nil unicode-fonts-block-font-mapping nil)

(defun on-after-init ()
  (unless (display-graphic-p (selected-frame))
    (set-face-background 'default "unspecified-bg" (selected-frame))))
(add-hook 'window-setup-hook #'on-after-init)


;; [[https://stackoverflow.com/questions/19054228/emacs-disable-theme-background-color-in-terminal/33298750#33298750][Emacs: disable theme background color in terminal - Stack Overflow]]
(defun on-frame-open (&optional frame)
  "If the FRAME created in terminal don't load background color."
  (unless (display-graphic-p frame)
    (set-face-background 'default "unspecified-bg" frame)))
(add-hook 'after-make-frame-functions #'on-frame-open)

;; --- agent-shell + pi (pi-acp) integration ---
(require 'acp)
(require 'agent-shell)
(require 'agent-shell-pi)
(setq agent-shell-pi-acp-command '("pi-acp"))
(setq agent-shell-preferred-agent-config (agent-shell-pi-make-agent-config))

;; --- agent-shell evil-mode tweaks (from agent-shell README) ---
(evil-define-key 'insert agent-shell-mode-map (kbd "RET") #'newline)
(evil-define-key 'normal agent-shell-mode-map (kbd "RET") #'comint-send-input)
(add-hook 'diff-mode-hook
          (lambda ()
            (when (string-match-p "\\*agent-shell-diff\\*" (buffer-name))
              (evil-emacs-state))))

;; --- agent-shell: ACP elicitation support (pi ask_user freeform answers) ---
;; pi-acp (patched fork) asks freeform questions via ACP `elicitation/create'
;; (UNSTABLE protocol feature). Upstream agent-shell does not handle it yet,
;; so bridge it here: prompt in the minibuffer, respond accept/decline/cancel.
(defun my/agent-shell--prompt-elicitation-property (name prop-schema &optional context)
  "Prompt for elicitation property NAME using PROP-SCHEMA.
When CONTEXT is non-nil, prepend it to the prompt."
  (let* ((type (map-elt prop-schema 'type))
         (base (or (map-elt prop-schema 'title) (symbol-name name)))
         (prompt (format "%s%s: " (if context (concat context " — ") "") base))
         (enum (map-elt prop-schema 'enum))
         (default (map-elt prop-schema 'default)))
    (cond
     (enum (completing-read prompt enum nil nil nil nil default))
     ((equal type "boolean") (yes-or-no-p prompt))
     ((member type '("number" "integer")) (read-number prompt default))
     ((equal type "array") (read-string prompt (when (and default (listp default))
                                                 (string-join default ","))))
     (t (read-string prompt default)))))

(defun my/agent-shell--handle-elicitation (acp-request state)
  "Handle ACP ELICITATION-REQUEST with STATE via minibuffer prompts."
  (let* ((params (map-elt acp-request 'params))
         (mode (map-elt params 'mode))
         (message (map-elt params 'message))
         (schema (map-elt params 'requestedSchema))
         (client (map-elt state :client))
         (request-id (map-elt acp-request 'id))
         (respond (lambda (result)
                    (acp-send-response
                     :client client
                     :response (list (cons :request-id request-id)
                                     (cons :result result))))))
    (condition-case err
        (if (not (equal mode "form"))
            (funcall respond (list (cons 'action "decline")))
          (let* ((properties (map-elt schema 'properties))
                 (first (car properties))
                 (content
                  (mapcar (lambda (prop-entry)
                            (cons (car prop-entry)
                                  (my/agent-shell--prompt-elicitation-property
                                   (car prop-entry) (cdr prop-entry)
                                   (and (eq prop-entry first) message))))
                          properties)))
            (funcall respond (list (cons 'action "accept")
                                   (cons 'content content)))))
      (quit
       (funcall respond (list (cons 'action "cancel")))))))

(defun my/agent-shell--on-request-around (orig-fn &rest args)
  "Handle `elicitation/create' requests in ARGS; otherwise call ORIG-FN."
  (let ((acp-request (plist-get args :acp-request)))
    (if (equal (map-elt acp-request 'method) "elicitation/create")
        (my/agent-shell--handle-elicitation acp-request (plist-get args :state))
      (apply orig-fn args))))

(advice-add 'agent-shell--on-request :around #'my/agent-shell--on-request-around)

;;; ============================================================================
;;; LEETCODE
;;; ============================================================================

(use-package! leetcode
  :config
  (setq leetcode-prefer-language "rust")
  (setq leetcode-prefer-sql "mysql")
  (setq leetcode-save-solutions t)
  (setq leetcode-directory "~/Projects/lc-solves"))
