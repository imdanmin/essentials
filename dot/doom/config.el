;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


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
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
(setq doom-font (font-spec :family "Iosevka Nerd Font" :size 16))
(setq doom-theme 'doom-nord-aurora)

;; Org Header Sizes
(after! org
  (custom-set-faces!
    '(org-level-1 :weight bold :slant italic :height 2.2 :foreground "#EE7733")
    '(org-level-2 :weight bold :slant italic :height 1.8 :foreground "#009E73")
    '(org-level-3 :weight bold :slant italic :height 1.4 :foreground "#0072B5")
    '(org-level-4 :weight bold :slant italic :height 1.1 :foreground "#D55E00")
    '(org-level-5 :weight bold :slant italic :height 1.05 :foreground "#CC79A7")
    '(org-level-6 :weight bold :slant italic :height 1.0 :foreground "#E69F00")
    '(org-level-7 :weight bold :slant italic :height 1.0 :foreground "#33BBEE")
    '(org-level-8 :weight bold :slant italic :height 1.0 :foreground "#BBBBBB")
    '(org-modern-date-active :height 1.6)
    '(org-modern-date-inactive :height 1.6)
    '(org-todo :inherit (org-todo org-modern-label) :height 1.6)
    '(org-special-keyword :underline t :height 1.6)))

;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Documents/org")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
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

;; Map 'jk' to exit insert mode, similar to vim
(after! evil-escape
  (setq evil-escape-key-sequence "jk")
  ;; (setq evil-escape-delay 0.1)
)

;; Open org directory
(defun +my/open-org-directory ()
  "Open org directory"
  (interactive)
  (dired "/home/dan/Documents/org"))

(map! :leader
      :desc "Open org-agenda file"
      "o a F" #'+my/open-org-directory)

;; Open org-agenda file
(defun +my/open-org-agenda-file ()
  "Open org-agenda file"
  (interactive)
  (find-file "/home/dan/Documents/org/agenda.org"))

(map! :leader
      :desc "Open org-agenda file"
      "o a f" #'+my/open-org-agenda-file)

;; org-agenda week-span
(setq org-agenda-span 21
      org-agenda-start-on-weekday nil
      org-agenda-start-day "-3d")

;; shell
(setq shell-file-name (executable-find "bash"))

;; Word Wrapping
(+global-word-wrap-mode +1)

;; Auto-Saving
(auto-save-visited-mode +1)
(setq auto-save-visited-interval 5)


;; Asclepius ASCII Art
(defun asclepius ()
(let* ((banner '(
"                ⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣠⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
"                ⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣈⣉⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
"                ⠀⠀⠀⠀⠀⢀⣶⣿⣿⣿⣿⣿⡷⢦⣤⣀⠀⠀⠀⠀⠀⠀⠀"
"                ⠀⠀⠀⠀⠀⢸⣿⣿⡏⠈⠙⠛⠿⠿⡿⠿⠃⢀⣀⣀⣀⣤⠀"
"                ⠀⠀⠀⠀⠀⠀⠙⠿⣿⠀⣿⣷⠀⡀⠀⠀⠀⠉⠉⠻⣏⠉⠀"
"                ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⢋⣠⣿⣦⠀⠀⠀⠀⠀⠉⠀⠀"
"                ⠀⠀⠀⠀⠀⠀⠀⢀⣴⣶⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀"
"                ⠀⠀⠀⠀⠀⠀⠀⢸⣿⠿⠛⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
"                ⠀⠀⠀⠀⠀⠀⠀⠀⠙⠀⣶⣿⠀⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀"
"                ⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣥⣤⣾⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀"
"                ⠀⠀⠀⠀⠀⠀⠀⠀⣾⡿⠿⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
"                ⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⢰⡆⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
"                ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢁⣸⡿⠂⠀⠀⠀⠀⠀⠀⠀⠀"
"                ⠀⠀⠀⠀⠀⠀⠀⠀⣴⠞⠛⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
"                ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
""
"   ⚕️⚕️️⚕️⚕️⚕️⚕️️⚕️️⚕️️⚕️⚕️⚕️⚕️️️⚕️⚕️⚕️⚕️️⚕️️⚕️️⚕️⚕️⚕️⚕️️️️"
                   ))
         (longest-line (apply #'max (mapcar #'length banner))))
    (put-text-property
     (point)
     (dolist (line banner (point))
       (insert (+doom-dashboard--center
                +doom-dashboard--width
                (concat line (make-string (max 0 (- longest-line (length line))) 32)))
               "\n"))
     'face 'doom-dashboard-banner)))

;; DOOM Dashboard Customization

;; Dashboard ASCII Art
(setq +doom-dashboard-ascii-banner-fn #'asclepius)

;; Remove "Loaded" and "Footer"
(remove-hook '+doom-dashboard-functions #'doom-dashboard-widget-loaded)
(remove-hook '+doom-dashboard-functions #'doom-dashboard-widget-footer)

;; Menu Items

;; Remove everything but org-agenda
(setq +doom-dashboard-menu-sections
        (cl-remove-if (lambda (section)
                (member (car section)
                        '("Recently opened files"
                                "Reload last session"
                                "Open project"
                                "Jump to bookmark"
                                "Open org-agenda"
                                "Open private configuration")))
                                +doom-dashboard-menu-sections))

;; Shortcut to open agenda file
(add-to-list '+doom-dashboard-menu-sections
             '("Open org-agenda file"
               :icon (nerd-icons-octicon "nf-oct-log" :face 'doom-dashboard-menu-title)
               :when (featurep! :lang org)
               ;; :face (:inherit (doom-dashboard-menu-title bold))
               :action +my/open-org-agenda-file))

;; Open org-agenda and show all agenda and all TODOs
(defun +my/org-agenda-all-todos ()
  "Open the org-agenda dispatcher and display all agenda and all TODOs"
  (interactive)
  (org-agenda nil "n"))

(add-to-list '+doom-dashboard-menu-sections
             '("Show all agenda & TODOs"
               :icon (nerd-icons-octicon "nf-oct-calendar" :face 'doom-dashboard-menu-title)
               :when (featurep! :lang org)
               :key "SPC o A n"
               ;; :face (:inherit (doom-dashboard-menu-title bold))
               :action +my/org-agenda-all-todos))

;; Open org-daily
;; (add-to-list '+doom-dashboard-menu-sections
;;              '("Open today's org-roam"
;;                :icon (nerd-icons-octicon "nf-oct-sun" :face 'doom-dashboard-menu-title)
;;                :when (featurep! :lang org +roam)
;;                ;; :face (:inherit (doom-dashboard-menu-title bold))
;;                :action org-roam-dailies-goto-today))

;; Footer
(add-hook! '+doom-dashboard-functions :append
  (insert "\n" (+doom-dashboard--center +doom-dashboard--width "Push Ups. Study Hard. Don't Stop.")))

;; Set wind chime sound when timer expires.
(setq org-clock-sound "~/Media/Sound/windchime.wav")

;; org-pomodoro
(after! org-pomodoro
  (setq org-pomodoro-length              50
        org-pomodoro-short-break-length  10
        org-pomodoro-long-break-length   30
        org-pomodoro-manual-break        t)

  (setq org-pomodoro-start-sound        "~/Media/Sound/windchime.wav"
        org-pomodoro-short-break-sound  "~/Media/Sound/windchime.wav"
        org-pomodoro-long-break-sound   "~/Media/Sound/windchime.wav"
        org-pomodoro-overtime-sound     "~/Media/Sound/windchime.wav"
        org-pomodoro-finished-sound     "~/Media/Sound/windchime.wav"
        org-pomodoro-killed-sound       "~/Media/Sound/windchime.wav"))

;; Set org drawers
(setq org-log-into-drawer t)
