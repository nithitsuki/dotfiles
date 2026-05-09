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
(setq doom-theme 'fleury)
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

(use-package! gptel
  :config
  (setq! gptel-api-key (getenv "OPENAI_API_KEY"))
  (gptel-make-anthropic "Personal Claude"
    :stream t
    :key (getenv "CLAUDE_KEY"))
  (gptel-make-gh-copilot "Copilot"))
(setq doom-emoji-font (font-spec :family "Segoe UI Emoji"))

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

(after! unicode-fonts
  (push "DejaVu Sans Mono" 
        (cadr (assoc "Braille Patterns" unicode-fonts-block-font-mapping))))

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
