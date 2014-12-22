:Namespace BuildCertDir

    base64←{⎕IO ⎕ML←0 1             ⍝ Base64 encoding and decoding as used in MIME.
   
      chars←'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
      bits←{,⍉(⍺⍴2)⊤⍵}                   ⍝ encode each element of ⍵ in ⍺ bits,
                                       ⍝   and catenate them all together
      part←{((⍴⍵)⍴⍺↑1)⊂⍵}                ⍝ partition ⍵ into chunks of length ⍺
   
      0=2|⎕DR ⍵:2∘⊥∘(8∘↑)¨8 part{(-8|⍴⍵)↓⍵}6 bits{(⍵≠64)/⍵}chars⍳⍵
                                       ⍝ decode a string into octets
   
      four←{                             ⍝ use 4 characters to encode either
        8=⍴⍵:'=='∇ ⍵,0 0 0 0           ⍝   1,
        16=⍴⍵:'='∇ ⍵,0 0               ⍝   2
        chars[2∘⊥¨6 part ⍵],⍺          ⍝   or 3 octets of input
      }
      cats←⊃∘(,/)∘((⊂'')∘,)              ⍝ catenate zero or more strings
      cats''∘four¨24 part 8 bits ⍵
    }

  split←{1↓¨(⍺=⍺,⍵)⊂⍺,⍵}

  ∇ r←CopyCertificationChainFromStore(cert path);trustroot;trustca;rix;iix;⎕IO;foundroot;current
⍝ Follow certificate chain from "cert" until a root certificate is found,
⍝ Writing CER files for each cert in chain to "path"
   
    ⎕IO←1
   
    trustroot←DRC.X509Cert.ReadCertFromStore'root'
    trustca←DRC.X509Cert.ReadCertFromStore'CA'
    current←cert
   
    :Repeat
      :If foundroot←(⍴trustroot)≥rix←trustroot.Formatted.Subject⍳⊂current.Formatted.Issuer
   ⍝ we have found the root cert
        (rix⊃trustroot)SaveAsCER path
   
      :ElseIf (⍴trustca)≥iix←trustca.Formatted.Subject⍳⊂current.Formatted.Issuer
   ⍝ we have found an intermediate  cert
        (current←iix⊃trustca)SaveAsCER path
      :Else
        'Unable to reach a root certificate'⎕SIGNAL 999
      :EndIf
   
    :Until foundroot
   
  ∇

  ∇ r←items GetDN DN;secs
    secs←'='split¨','split DN
    r←2⊃¨(secs,⊂'' '')[(1⊃¨secs)⍳items]
   
  ∇

  ∇ r←cert SaveAsCER path;data;tn;name;filename
⍝ Save a X509 certificate as a CER file
   
    name←⊃(⊂,'CN')GetDN cert.Formatted.Subject
    filename←path,name,'.cer'
    data←⊃,/('X509 CERTIFICATE'{pre←{'-----',⍺,' ',⍵,'-----'} ⋄ (⊂'BEGIN'pre ⍺),⍵,⊂'END'pre ⍺}↓64{s←(⌈(⍴⍵)÷⍺),⍺ ⋄ s⍴(×/s)↑⍵}base64 cert.Cert),¨⊂⎕UCS 10 13
⍝ remember to create the directory
    tn←filename ⎕NCREATE 0
    data ⎕NAPPEND tn 80
    ⎕NUNTIE tn
   
  ∇

  ∇ dir BuildCertChain url;server;port;r;pc
  ⍝ dir - the folder in which to save the server's public certificate chain
  ⍝ url - the URL:port for the server (do not prepend http://)
    'DRC'⎕CY'conga'
    DRC.Init''
    server port←2↑'' '443'{⍵,(⍴⍵)↓⍺}':'split url
    :Trap 0
      #.Files.MkDir dir
      'Unable to find or create folder'⎕SIGNAL(~#.Files.DirExists dir)/22
    :Else
      ↑⎕DM
      →0
    :EndTrap
    port←2⊃⎕VFI⍕port
⍝ this should give us a secure connection to the server but 32 means that the server certificate is not validated
    DRC.Clt'C1'server port('X509'(⎕NEW DRC.X509Cert))('SSLValidation' 32)
⍝ get the server certificate
    r←DRC.GetProp'C1' 'PeerCert'
    pc←1⊃2⊃r    ⍝ lets take the first of the two certificates
⍝ Close connection
    DRC.Close'C1'
    CopyCertificationChainFromStore pc dir
   
    ⎕←'Remember to provide "',dir,'" as the RootCertPath argument.'
  ∇

:EndNamespace