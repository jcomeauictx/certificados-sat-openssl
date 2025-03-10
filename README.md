certificados-sat-openssl
========================

Manejo de certificados y sello digital SAT

- Permite crear archivos key.pem
- Permite crear archivos cer.pem
- Permite crear archivos .pfx
- Obtiene fecha de inicio del certificado
- Obtiene fecha de vigencia del certificado
- Obtiene numero de seria del certificado
- Permite verificar si un certificado no es una fiel
- Verifica que el certificado(.cer) sea pareja de la llave(.key)

# notes for English-speaking users

* I just grepped the openssl calls out of the php file and made a bash script
* The .pfx file is to import into gpgsm for signing. could also name as .p12
* If the password you gave SAT doesn't work, maybe they upcased or swapcased it
  (they swapcased mine; either that or the caps lock was on when I typed it,
   and I wasn´t allowed to see what I was typing)
* Typing `make` will do all that the php script does
* The results will be found in the directory where the original files from
  SAT were stored, e.g. /mnt/usb/FIEL_ABCD950505XY9_20250225093522/
* For use with PGP: <https://stackoverflow.com/a/62613267/493161>
* Parent certs for potential use with pgpsm signing can be found at 
  <http://omawww.sat.gob.mx/tramitesyservicios/Paginas/certificado_sello_digital.htm> and
  <https://www.cloudb.sat.gob.mx/TSP_MX.pdf>; these are now imported into gpgsm
  by default.
* Using detached signatures after finding that nothing can read signed txt
  files, and though browsers can mostly view signed PDFs they aren't able to
  detect nor verify the signatures.
* [Build complete chain in pfx/p12 file](https://serverfault.com/a/1011396/58945) (had to run `openssl rehash -compat .` inside sat.certs directory first).
* For use with Firefox and LibreOffice, first set up a separate profile
  (I called mine SAT) by starting firefox with the -ProfileManager option.
* In firefox, click "hamburger" icon at upper right for settings, then
  Privacy & Security | Certificates | View Certificates | Your Certificates | Import
  Locate the pfx file and import it; you will see it imports your key under
  Your Certificates, and *also* imports the SAT cert, and the self-signed
  Banco de Mexico root certificate, under Authorities.
  However, neither are yet trusted. You need to select BANCO DE MEXICO, then
  click the Edit Trust button, and enable it to identify both websites and
  email users. Do the same for SAT (AC DEL SERVICIO DE ADMINISTRACION
  TRIBUTARIA), except it only needs to verify email users.
  Click the OK button in Certificate Manager to close it.
* In loffice, select Tools | Options | LibreOffice | Security | Certificate,
  and choose the firefox:SAT profile you just made. Then, from
  File | Digital Signatures | Digital Signatures, you can sign a PDF document.
  It will show that the signature is valid.
* [Signing from command line](https://help.libreoffice.org/latest/he/text/shared/guide/pdf_params.html), [and more details](https://vmiklos.hu/blog/pdf-convert-to.html)
