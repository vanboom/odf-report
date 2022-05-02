# Additions
1. Use a $ preceding a placeholder to cause a field to be processed with `number_to_currency`
1. Images may be added using a tag.  Presently, this is only used to include signatures from signature_pad.js, so it only supports SVG images 1.75" x 0.37" (a reasonable size for signatures in a printed doc).  The tag must contain the `SIGNATURE_` prefix, e.g. [SIGNATURE_12].  No image in the source template is required. 
