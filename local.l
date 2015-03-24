# local.l
#
# The MIT License (MIT)
#
# Copyright (c) 2015 Alexander Williams, Unscramble <license@unscramble.jp>

(local MODULE_INFO *Https *Buffer_size *Headers)
(local *NE_FEATURE_SSL *NE_FEATURE_ZLIB *NE_FEATURE_IPV6 *NE_FEATURE_LFS *NE_FEATURE_SOCKS)
(local *NE_FEATURE_TS_SSL *NE_FEATURE_I18N *NE_FEATURE_SSPI)
(local *NE_ABUFSIZ *NE_OK *NE_ERROR *NE_LOOKUP *NE_AUTH *NE_PROXYAUTH *NE_CONNECT)
(local *NE_TIMEOUT *NE_FAILED *NE_RETRY *NE_REDIRECT)

# ffi
(local ne-sock-init ne-version-string ne-has-support ne-get-error ne-uri-parse ne-uri-defaultport)
(local ne-add-request-header ne-session-create ne-ssl-trust-default-ca ne-request-create)
(local ne-begin-request ne-end-request ne-read-response-block ne-read-response-to-fd ne-set-request-body-buffer)
(local ne-request-destroy ne-close-connection ne-session-destroy ne-get-status ne-response-header-iterate)
(local ne-set-server-auth ne-forget-auth)

# internal
(local throw-error create-session-request create-session parse-uri get-port set-auth-credentials)
(local do-auth del-auth-credentials set-headers set-request-body request-dispatch download-file random-filename random-id)
(local process-body link-response-block pack-body parse-response get-headers end-request-session end-session)
(local begin-request end-request)
