;;;; relocate-page.el -- move a page, adjusting (local) URLs in it
;;; Time-stamp: <2005-01-18 12:05:56 john>

(provide 'relocate-page)
(require 'cl)
(require 'page-attributes)
(require 'webmaster-macros)

(defun webmaster:absolutize-urls ()
  "Make all URLs on this page absolute.
This does not write the page to file, since the original use of this
function is to prepare a page for being moved within its tree, and so
it will be written elsewhere as a copy."
  (interactive)
  (webmaster:apply-to-urls-in-current-page nil '(webmaster:absolute-url)))

(defun webmaster:relativize-urls ()
  "Make urls on this page relative where possible."
  (webmaster:apply-to-urls-in-current-page nil '(webmaster:relative-url)))

;;;###autoload
(defun webmaster:relocate-page (whither)
  "Relocate the current page into WHITHER."
  (interactive "FFile to relocate page into: ")
  (let ((original-url webmaster:page-url))
    (when (file-directory-p whither)
      (setq whither (expand-file-name (file-name-nondirectory (buffer-file-name)) whither)))
    (webmaster:absolutize-urls)
    (write-file whither)
    (webmaster:find-file-hook)		; sets up website<-->directory variables
    (webmaster:relativize-urls)
    (webmaster:rewrite-reference-throughout-tree webmaster:page-site-homepage-directory-name
						 original-url
						 webmaster:page-url)))

(defun webmaster:rewrite-reference (reference old-url new-url)
  "Expand REFERENCE into an absolute URL and if it matches OLD-URL return a relativized NEW-URL else nil."
  (let ((full-ref (webmaster:absolute-url reference)))
    (if (string= full-ref old-url)
	(webmaster:relative-url new-url)
      nil)))

;;;###autoload
(defun webmaster:rewrite-reference-throughout-page (old-url new-url)
  "Change all references to OLD-URL in the page to NEW-URL."
  (interactive "sRewrite old URL: 
sRewrite %s to new URL: ")
  (webmaster:apply-to-urls-in-current-page nil (list 'webmaster:rewrite-reference) (list old-url new-url)))

;;;###autoload
(defun webmaster:rewrite-reference-throughout-tree (tree old-url new-url &optional record)
  "Throughout TREE rewrite all references to OLD-URL to be NEW-URL.
This is done throughout all .html and .shtml files in the tree.
If given a file for TREE, do the rewriting of that file."
  (interactive "fWeb directory tree: 
sOld URL: 
sNew URL: ")
  (webmaster:apply-throughout-tree
   tree
   'webmaster:rewrite-reference-throughout-page
   (list old-url new-url)))

;;;###autoload
(defun webmaster:rewrite-regexp-reference (reference old-url-pattern new-url-template)
  "Expand REFERENCE into an absolute URL and if it matches OLD-URL-PATTERN return a relativized url based on NEW-URL-TEMPLATE else nil.
NEW-URL-TEMPLATE is processed using replace-match (which see)."
  (let ((full-ref (webmaster:absolute-url reference)))
    (if (string-match old-url-pattern full-ref)
	(webmaster:relative-url (replace-match new-url-template t nil full-ref))
      nil)))

;;;###autoload
(defun webmaster:rewrite-regexp-reference-throughout-page (old-url-pattern new-url-template)
  "Change all references to OLD-URL-PATTERN in the page to NEW-URL-TEMPLATE, using replace-match (which see)."
  (interactive "sRewrite old URL pattern: 
sRewrite %s to new URL template: ")
  (webmaster:apply-to-urls-in-current-page nil (list 'webmaster:rewrite-regexp-reference) (list old-url-pattern new-url-template)))

;;;###autoload
(defun webmaster:rewrite-regexp-reference-throughout-tree (tree old-url-pattern new-url-template &optional record)
  "Throughout TREE rewrite all references to OLD-URL-PATTERN to be based on NEW-URL-PATTERN using replace-match (which see).
This is done throughout all .html and .shtml files in the tree.
If given a file for TREE, do the rewriting of that file."
  (interactive "fWeb directory tree: 
sOld URL pattern: 
sNew URL template: ")
  (webmaster:apply-throughout-tree
   tree
   'webmaster:rewrite-regexp-reference-throughout-page
   (list old-url-pattern new-url-template)))

;;; sample big move
(defun dothemove ()
  (interactive)
  (let ((fromdir  "$COMMON/www.acedb.org/Development/")
        (todir "$COMMON/www.acedb.org/Downloads/release-notes/"))
    (dolist (page (directory-files fromdir nil "release.notes.*.shtml" t))
      (when (string-match "release.notes.\\(......\\).shtml" page)
	(let* ((usedname (substring page (match-beginning 1) (match-end 1)))
	       (tofile (expand-file-name (format "19%s-%s-%s.shtml"
						 (substring usedname 0 2)
						 (substring usedname 2 4)
						 (substring usedname 4 6))
					 todir))
	       (fromfile (expand-file-name page fromdir)))
	  (when (yes-or-no-p (format "move %s to %s?" fromfile tofile))
	    (save-window-excursion
	      (find-file fromfile)
	      (webmaster:relocate-page tofile)
	      (message "moved %s to %s" fromfile tofile))))))))

(defun move-release-notes-again ()
  (interactive)
  (let ((fromdir "$COMMON/www.acedb.org/htdocs/Downloads/release-notes/")
        (todir "$COMMON/www.acedb.org/htdocs/Software/Downloads/release-notes/"))
    (dolist (page (directory-files fromdir nil ".shtml$" t))
      (let ((fromfile (expand-file-name page fromdir))
	    (tofile (expand-file-name page todir)))
	(message "%s: %s-->%s" page fromfile tofile)
	(save-window-excursion
	  (find-file fromfile)
	  (webmaster:relocate-page tofile))))))

;;; end of relocate-page.el
