
(import test)
(import (chicken file))
(import (chicken load))

(load-relative "bootstrap-csi.scm")

;; Setup test environment
(define test-dir-name "csi-bootstrap-test-data")
(define test-blob-file (string-append test-dir-name "/blob-action.u8"))

(create-directory test-dir-name)
(delete-file* test-blob-file)

(test-group "Framework Verifications"
    (test-assert "Identify Chicken Scheme" (eq? wyrm.runtime 'csi))
)

(wyrm.include "test-wyrm-api.scm")
(wyrm.include "test-miniscm-all.scm")

(test-exit)
