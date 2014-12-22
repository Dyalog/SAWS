:Namespace Samples
⍝ === VARIABLES ===

TestCertificates←''


⍝ === End of variables definition ===

(⎕IO ⎕ML ⎕WX)←1 0 3

∇ r←CertPath;droptail;exists;file;ws
                    ⍝ Return the path to the certificates
     
 file←'server/localhost-server-cert.pem' ⍝ Search for this file
 droptail←{(-⌊/(⌽⍵)⍳'\/')↓⍵}
 exists←{0::0 ⋄ 1{⍺}⎕NUNTIE ⍵ ⎕NTIE 0}
     
 :If exists(r←{⍵,('/'≠¯1↑⍵)/'/'}{(-'\'=¯1↑⍵)↓⍵}TestCertificates),file
 :ElseIf exists(r←'/TestCertificates/',⍨ws←droptail ⎕WSID),file
 :ElseIf exists(r←'/TestCertificates/',⍨ws←droptail ws),file
 :ElseIf exists(r←'../TestCertificates/'),file
 :ElseIf exists(r←'/TestCertificates/',⍨droptail 2 ⎕NQ'.' 'GetEnvironment' 'Dyalog'),file
 :Else
   ('Unable to locate file ',file)⎕SIGNAL 22
 :EndIf
∇

∇ cert←ReadCert relfilename;certpath;fn
 ss←{⎕ML←1                           ⍝ Approx alternative to xutils' ss.
   srce find repl←,¨⍵              ⍝ source, find and replace vectors.
   mask←find⍷srce                  ⍝ mask of matching strings.
   prem←(⍴find)↑1                  ⍝ leading pre-mask.
   cvex←(prem,mask)⊂find,srce      ⍝ partitioned at find points.
   (⍴repl)↓∊{repl,(⍴find)↓⍵}¨cvex  ⍝ collected with replacements.
 }
 certpath←CertPath
 fn←certpath,relfilename,'-cert.pem'
 cert←⊃##.DRC.X509Cert.ReadCertFromFile fn
 cert.KeyOrigin←{(1⊃⍵)(ss(2⊃⍵)'-cert' '-key')}cert.CertOrigin
∇

 ss←{⎕ML←1                           ⍝ Approx alternative to xutils' ss.
   srce find repl←,¨⍵              ⍝ source, find and replace vectors.
   mask←find⍷srce                  ⍝ mask of matching strings.
   prem←(⍴find)↑1                  ⍝ leading pre-mask.
   cvex←(prem,mask)⊂find,srce      ⍝ partitioned at find points.
   (⍴repl)↓∊{repl,(⍴find)↓⍵}¨cvex  ⍝ collected with replacements.
 }

:EndNamespace 