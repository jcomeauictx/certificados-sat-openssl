SHELL := /bin/bash
SATDIR ?= $(word 1, $(wildcard $(HOME)/FIEL_* $(HOME)/*/FIEL_* /mnt/FIEL_* \
 /mnt/*/FIEL_*))
KEYFILE ?= $(wildcard $(SATDIR)/Claveprivada_FIEL_*.key)
CERTFILE ?= $(wildcard $(SATDIR)/*.cer)
# you can edit the following to use your actual password
# or better, from command line, type a space (to keep plaintext out of
# history file), then: export SATPASS=MySecretPassword
# NOTE: don't actually use MySecretPassword! type your own instead!
# and when you're done with your SAT files, `unset SATPASS`
SATPASS ?= pUtPa55w0rDh3rE
TRUSTLIST ?= $(HOME)/.gnupg/trustlist.txt
REALLY_DELETE ?= false
SUBJECT := $(shell openssl x509 -in $(CERTFILE) -noout -subject \
	 -nameopt RFC2253 | sed 's/^subject=//')
ifeq ($(SHOWENV),)
 export KEYFILE CERTFILE SATPASS
else
 export
endif
# recipes begin here
all: initialize
advanced: all importcerts trust test
initialize: $(KEYFILE).pfx
trust: trustlist.txt
	while read line; do \
	 if [ -e $(TRUSTLIST) ] && grep -q "$$line" $(TRUSTLIST); then \
	  echo $$line already trusted >&2; \
	 else echo $$line >>$(TRUSTLIST) && echo $$line now trusted >&2; \
	 fi; \
	done < $<
test: /tmp/test.txt.sig /tmp/test.txt.verify /tmp/test.signed.pdf
importcerts: $(KEYFILE).pfx
	@echo 'Just hit the <ENTER> key at passphrase prompt' >&2
	gpgsm --import $<
unimportcerts:
	# NOTE: disabled by default!
	# it will delete all gpgsm certificates and private keys!
	$(REALLY_DELETE)  # NOTE: set this true at your peril!
	gpgsm --delete-keys $$(gpgsm --list-keys \
	 | awk '$$1 ~ /^ID:/ {print $$2}')
/tmp/test.txt:
	echo testing, testing, one two three... > $@
%.txt.sig: %.txt
	gpgsm --detach-sign $< >$@
%.pdf.sig: %.pdf
	gpgsm --detach-sign $< >$@
%.txt.verify: %.txt.sig %.txt
	gpgsm --verify $+
%.txt.verifyonly: %.txt
	# won't recreate sig even if original has changed
	# for testing that verify fails on changed txt file
	gpgsm --verify $<.sig $<
%.signed.pdf: %.pdf
	soffice --invisible --convert-to 'signed.pdf:draw_pdf_Export:{\
	  "SignPDF":{"type":"boolean","value":"true"},\
	  "SignCertificateSubjectName":{"type":"string","value":"$(SUBJECT)"}\
	 }' --outdir ${@D} $<
%.signed.pdf: %.txt
	soffice --invisible --convert-to 'signed.pdf:draw_pdf_Export:{\
	  "SignPDF":{"type":"boolean","value":"true"},\
	  "SignCertificateSubjectName":{"type":"string","value":"$(SUBJECT)"}\
	 }' --outdir ${@D} $<
%.pdf.verify: %.pdf.sig %.pdf
	gpgsm --verify $+
certclean:
	rm -f $(KEYFILE).pem $(CERTFILE).pem $(KEYFILE).pfx $(KEYFILE).p12
clean: certclean
	rm -f /tmp/test.txt*
ls:
	ls $(dir $(KEYFILE))
env:
ifeq ($(SHOWENV),)
	$(MAKE) SHOWENV=1 $@
else
	$@
endif
pemfiles: $(KEYFILE).pem $(CERTFILE).pem
# openssl creates empty output file when it fails, so remove it
$(KEYFILE).pem: $(KEYFILE)
# make it prompt for password if one wasn't set
ifeq ($(SATPASS),MySecretPassword)
	@echo $(SATPASS) is not a valid password! >&2
	@$(MAKE) SATPASS= $@
else ifeq ($(SATPASS),pUtPa55w0rDh3rE)
	@echo $(SATPASS) is not a valid password! >&2
	@$(MAKE) SATPASS= $@
else ifneq ($(SATPASS),)
	openssl pkcs8 -inform DER -in $< -out $@ -passin pass:$(SATPASS) || \
	 (\
	  rm -f $@; \
	  echo $(SATPASS) was not accepted as the password. >&2; \
	  $(MAKE) SATPASS= $@ \
	 )
else  # prompt for password
	openssl pkcs8 -inform DER -in $< -out $@ || \
	 (rm -f $@; false)
endif
$(CERTFILE).pem: $(CERTFILE)
	openssl x509 -inform DER -outform PEM -in $< -pubkey -out $@ || \
	 (rm -f $@; false)
$(KEYFILE).pfx: $(KEYFILE).pem $(CERTFILE).pem
	modcert=$$(openssl x509 -noout -modulus -in $(word 2, $+)); \
	modkey=$$(openssl rsa -noout -modulus -in $<); \
	if [ -n "$$modcert" ]; then \
		if [ "$$modcert" = "$$modkey" ]; then \
			echo certificate and key match >&2; \
		else \
			echo certificate and key do not match >&2; \
			exit 1; \
		fi; \
	else \
		echo could not find modulus of certificate and/or key >&2; \
		exit 1; \
	fi
	@# generate pkcs12 combined cert and key for gpgsm
	@# https://stackoverflow.com/a/62613267/493161
	@# https://serverfault.com/a/1011396/58945
	@echo location of files: $(SATDIR) >&2
	@echo key file: $(KEYFILE) >&2
	@echo certificate file: $(CERTFILE) >&2
	@echo password: $(SATPASS) >&2
	openssl verify -verbose -show_chain -CApath sat.certs $(CERTFILE).pem
	openssl pkcs12 -export -inkey $< -in $(word 2, $+) \
	 -out $@ -passout pass: -legacy -chain -CApath sat.certs
push:
	git push origin
	git push githost
info:
	openssl x509 -in $(CERTFILE).pem -noout -serial
	openssl x509 -in $(CERTFILE).pem -noout -startdate
	openssl x509 -in $(CERTFILE).pem -noout -enddate
	openssl x509 -in $(CERTFILE).pem -noout -subject
serial:
	@command -v xxd >/dev/null || (echo Requires installing xxd >&2; false)
	@echo -n 'real (unhexlified) serial number is '
	@openssl x509 -in $(CERTFILE).pem -noout -serial | \
	 awk -F= '$$1 == "serial" {print $$2}' | xxd -r -p
	@echo  # send newline, since xxd did not
