:Namespace WebServer
⍝ === VARIABLES ===

HOME←''

NL←(⎕ucs 13 10)

stop←1


⍝ === End of variables definition ===

(⎕IO ⎕ML ⎕WX)←1 0 3

∇ z←FromRaw z;⎕IO
 :If 82=⊃⎕DR' '
   ⎕IO←0
   z←⎕AV[(⎕NXLATE 0)⍳8 uns z]
 :Else
   z←⎕UCS 8 uns z ⍝ 8-but unsigned integers
 :EndIf
∇

∇ r←GetAnswer(CMD BUF);URL;I;Status;Content
                    ⍝ Default file handler.
                    ⍝ Needs to return:
                    ⍝  [1] - (charvec) HTTP status code.         This can be 0 to just mean standard success.
                    ⍝  [2] - (charvec) Additional HTTP headers.  If none, just set to ''.
                    ⍝  [3] - (charvec) HTTP content.             If none, just set to ''.
 :If (⊂##.HTTPUtils.lc(I←CMD⍳' ')↑CMD)∊'get ' 'post '
   URL←I↓CMD
   URL←(¯1+URL⍳' ')↑URL
   :If 'http:'≡##.HTTPUtils.lc 5↑URL ⍝ Drop leading server address
     URL←(¯1+(+\'/'=URL)⍳3)↓URL
   :EndIf
   URL←('/'=1↑URL)↓URL
   :If 0=⍴Content←GetFile HOME,URL,(0=⍴URL)/'index.htm'
     Status←'404 File Not Found'
   :Else
     Status←0
   :EndIf
 :Else
   Status←'500 Invalid command: ',CMD ⋄ Content←''
 :EndIf
 r←Status''Content
∇

∇ R←GetFile NAME
 :Trap 0
   NAME ⎕NTIE ¯1
   R←⎕NREAD ¯1(⎕DR'A'),2↑⎕NSIZE ¯1
   ⎕NUNTIE ¯1
 :Else
   R←''
 :EndTrap
∇

∇ ns HandleRequest arg;FindFirst;obj;buf;pos;I;z;hdr;req;CMD;status;content;rarg;Answer;conns;eoh
                    ⍝ Handle a Web Server Request
     
 FindFirst←{(⍺⍷⍵)⍳1}
 conns←⍎ns ⍝ get a reference to the namespace for the connection
 obj buf←arg
 buf←FromRaw buf
     
 :If 0=conns.⎕NC'Buffer'
   conns.Buffer←⍬
 :EndIf
 conns.Buffer,←buf
 conns.Handler←{6::conns.Handler←'<env>'≡5↑conns.Buffer ⋄ conns.Handler}⍬ ⍝ are we serving as a mapping handler?
 eoh←(1+conns.Handler)⊃(NL,NL)('</env>') ⍝ end of header marker
 pos←(¯1+⍴eoh)+eoh FindFirst conns.Buffer
     
 :If pos>⍴conns.Buffer ⍝ Have we got everything ?
   :Return
 :ElseIf pos>I←(z←NL[2],'content-length:')FindFirst hdr←##.HTTPUtils.lc pos↑conns.Buffer
 :AndIf (⍴conns.Buffer)<pos+↑2⊃⎕VFI(¯1+z⍳NL[1])↑z←(¯1+I+⍴z)↓hdr
   :Return ⍝ a content-length was specified but we haven't yet gotten what it says to ==> go back for more
 :EndIf
     
 :If conns.Handler  ⍝ if we're running as a mapping handler
   (req conns.Buffer)←MakeHTTPRequest conns.Buffer ⍝ fake MiServer out by building an HTTP request from what we've got
 :Else
   req←pos↑conns.Buffer
   conns.Buffer←pos↓conns.Buffer
 :EndIf
     
     
     
 CMD←(¯1+req⍳NL[1])↑req
     
                    ⍝ The function called is reponsible for returning:
                    ⍝  [1] - (charvec) HTTP status code.         This can be 0 to just mean standard success.
                    ⍝  [2] - (charvec) Additional HTTP headers.  If none, just set to ''.
                    ⍝  [3] - (charvec) HTTP content.             If none, just set to ''.
     
 :Trap 0/0 ⍝ be sure to cover any problems during ⍎ and cover a possibly-bogus result from it
   (status hdr content)←⍎HOME,' (cmd←##.HTTPUtils.DecodeCmd req) conns'
 :Else
   ##.SAWS_Error←⎕TS ⎕LC ⎕XSI ⎕DM
   (status hdr content)←'500 Internal Server Error' '' ''
 :EndTrap
 :If status≡'200 OK' ⋄ :AndIf 1∊'text/xml'⍷hdr ⋄ content←conns.Buffer ##.ResolveNamespaces content ⋄ :EndIf
     
 rarg←req conns.Buffer ⍝ (<rarg> is for HOME to utilize, e.g. HOME≡'##.SOAP.CongaSOAP rarg'
 :If 0≡status ⋄ status←'200 OK' ⋄ :EndIf
 :If 0≠⍴hdr ⋄ hdr←(-+/∧\(⌽hdr)∊NL)↓hdr ⋄ :EndIf
 :If ##.DEBUG ##.bit 2 ⋄ :AndIf 0<⍴##.AltResponse ⋄ content←##.AltResponse ⋄ :EndIf ⍝ if directed to substitute message, do so
 :If ##.DEBUG ##.bit 1 ⋄ ##.LastRunResponse←content ⋄ :EndIf ⍝ if directed to save last transaction, do so
 :If ##.TRACE ##.bit 0
   1 ##.Output'>>> WebServer.HandleRequest <<<'
   1 ##.Output'status:  ',##.terse status~⎕UCS 10
   1 ##.Output'hdr:     ',##.terse hdr~⎕UCS 10
   1 ##.Output'content: ',##.terse content~⎕UCS 10
 :EndIf
     
 Answer←((1+conns.Handler)⊃'HTTP/1.0 ' 'Status: '),status,NL,'Content-Length: ',(⍕⍴content),NL,hdr,NL,NL
 Answer←Answer,content
     
 Answer←ToRaw Answer
 :If ~0=1⊃z←##.DRC.Send obj Answer 1 ⍝ Send response and close connection
   ##.Output'Closed socket ',obj,' due to error: ',⍕z
 :EndIf
 {}⎕EX ns ⍝ erase the namespace after the connection is closed
∇

∇ r←{path}HttpsRun arg;Common;cmd;name;port;wres;ref;nspc;sink;HOME;stop;certpath;flags;z;cert;secargs;secure;rc;objname;command;data
               ⍝ Ultra simple HTTPS (Web) Server
               ⍝ Assumes Conga available in ##.DRC
     
 :If 0=⎕NC'path' ⋄ certpath←##.Samples.CertPath,'ca' ⍝ if no certificate path specified, use sample
 :ElseIf 0∊⍴path ⋄ certpath←##.Samples.CertPath,'ca' ⍝ or if certificat path is empty, use sample
 :Else ⋄ certpath←path                          ⍝ otherwise use supplied path
 :EndIf
 certpath,←('/\'∊⍨¯1↑certpath)↓'/'
     
 {}##.DRC.Init''
 HOME port name cert flags←5↑arg,(⍴arg)↓'' 445 'HTTPSRV'(⎕NEW ##.DRC.X509Cert)0
 secure←{0::0 ⋄ 1<cert.IsCert}⍬
 secargs←⍬
 :If secure
   {}##.DRC.SetProp'.' 'RootCertDir'certpath
   secargs←('X509'cert)('SSLValidation'flags)
 :EndIf
 →(0≠1⊃r←##.DRC.Srv name''port'Raw' 10000,secure/secargs)⍴0
 ##.Output(4×secure)↓'Non-Secure Web server ''',name,''' started on port ',⍕port
 ##.Output'Handling requests using ',HOME
 Common←⎕NS'' ⋄ stop←0
 :While ~stop
   wres←##.DRC.Wait name 10000 ⍝ Tick every 10 secs
   rc objname command data←4↑wres,(⍴wres)↓0 '' '' ''
   :Select rc
   :Case 0 ⍝ Good data from RPC.Wait
     :Select command
     :Case 'Error'
       :If name≡2⊃wres ⋄ stop←1 ⋄ :EndIf
       ##.Output'Error ',(⍕4⊃wres),' on ',2⊃wres
       ⎕EX SpaceName 2⊃wres
     :CaseList 'Block' 'BlockLast'
       :If 'BlockLast'≡command
         ⎕EX nspc
       :Else ⋄ r←nspc HandleRequest&objname data ⍝ Run page handler in new thread
       :EndIf
     :Case 'Connect'
       nspc←SpaceName 2⊃wres ⋄ nspc ⎕NS''
       :If secure ⋄ (⍎nspc).PeerCert←2⊃##.DRC.GetProp(2⊃wres)'PeerCert' ⋄ :EndIf
     :Else ⋄ ##.Output'Error ',⍕wres
     :EndSelect
   :Case 100 ⍝ Time out
   :Case 1010 ⍝ Object Not found
     ##.Output'Object ''',name,''' has been closed - Web Server shutting down'
     :Return
   :Else
     ##.Output'#.DRC.Wait failed:'
     ##.Output wres
     ∘ ⍝ intentional error
   :EndSelect
   :If 0<⎕NC'##.STOP'
     :If ##.STOP≡1
       stop←1
     :EndIf
   :EndIf
 :EndWhile
 {}##.DRC.Close name
 ##.Output'Web server ''',name,''' stopped '
∇

∇ r←MakeHTTPRequest req;x;v;s;p;l;m;n;i;c;q
     ⍝ kludge to get by ampersands in a POST - will be fixed when we build proper requests from MiServerCGI

 c←''
 :If (⍴req)≥i←1⍳⍨'>tsop<'⍷⌽req
   i←(⍴req)-i+5
   c←¯13↓(i+6)↓req
   req←(i↑req),'</env>'
 :EndIf
     
 :Trap 11
   x←⎕XML req
 :Else
   ∘∘∘
 :EndTrap
 v←'var'∘≡¨x[;2]
 v←↑{⎕ML←3 ⋄ (~<\'='=⍵)⊂⍵}¨v/x[;3]
 m l p s n q←v∘{3::2⊃⍵ ⋄ ⍺[;2]⊃⍨⍺[;1]⍳⊂1⊃⍵}¨↓'REQUEST_METHOD' 'CONTENT_LENGTH' 'PATH_INFO' 'SERVER_PROTOCOL' 'SERVER_NAME' 'QUERY_STRING',[1.1]'GET' '0' '' 'HTTP/1.0' 'localhost' ''
 l←⍕⍴c
     ⍝ p←p↓⍨¯5×'.saws'≡#.SAWS.HTTPUtils.lc ¯5↑p ⍝ drop off .saws
 r←(m,' ',p,((' '∨.≠q)/'?',q),' ',s,NL,'Host: ',n,NL,'Content-Length: ',l,NL,NL)c
∇

∇ r←Run arg;HOME;port;name;Common;stop;rc;objname;command;data;nspc;wres
                    ⍝ Ultra simple HTTP (Web) Server
                    ⍝ Assumes Conga available in ##.DRC
 {}##.DRC.Init''
 HOME port name←3↑arg,(⍴arg)↓'' 8080 'HTTPSRV'
 →(0≠1⊃r←##.DRC.Srv name''port'Raw' 10000)⍴0 ⍝
 ##.Output'Web server ''',name,''' started on port ',⍕port
 ##.Output'Handling requests using ',HOME
 Common←⎕NS'' ⋄ stop←0
 :While ~stop
   wres←##.DRC.Wait name 10000 ⍝ Tick every 10 secs
   rc objname command data←4↑wres,(⍴wres)↓0 '' '' ''
   :Select rc
   :Case 0 ⍝ Good data from RPC.Wait
     :Select command
     :Case 'Error'
       :If name≡objname ⋄ stop←1 ⋄ :EndIf
       ##.Output'Error ',(⍕data),' on ',objname
       ⎕EX SpaceName objname
     :CaseList 'Block' 'BlockLast'
       :If 0=⎕NC nspc←SpaceName objname ⋄ nspc ⎕NS'' ⋄ :EndIf ⍝ create namespace for command
       :If 'BlockLast'≡command ⍝ if we got a blocklast, the connection has been closed...
         ⎕EX nspc ⍝ just cleanup the namespace
       :Else ⋄ r←nspc HandleRequest&objname data ⍝ Run page handler in new thread
       :EndIf
     :Case 'Connect' ⍝ Ignore
     :Else ⋄ ##.Output'Error ',⍕wres
     :EndSelect
   :Case 100 ⍝ Time out - put any "housekeeping" code here
   :Case 1010 ⍝ Object Not found
     ##.Output'Object ''',name,''' has been closed - Web Server shutting down'
     :Return
   :Else
     ##.Output'#.DRC.Wait failed:'
     ##.Output wres
     ∘ ⍝ intentional error
   :EndSelect
   :If 0<⎕NC'##.STOP'
     :If ##.STOP≡1
       stop←1
     :EndIf
   :EndIf
 :EndWhile
 {}##.DRC.Close name
 ##.Output'Web server ''',name,''' stopped '
∇

∇ r←SpaceName cmd
                    ⍝ Generate namespace name from rpc command name
 r←'Common.C',Subst(2⊃{1↓¨('.'=⍵)⊂⍵}'.',cmd)'-=' '_∆'
∇

∇ r←Subst arg;i;m;str;c;rep
                    ⍝ Substictute character c in str with rep
 str c rep←arg
 i←c⍳str
 m←i≤⍴c
 (m/str)←rep[m/i]
 r←str
∇

∇ r←TimeServer(CMD BUF);t
                    ⍝ Example function for "RPC Server".
     
                    ⍝ Needs to return:
                    ⍝  [1] - (charvec) HTTP status code.         This can be 0 to just mean standard success.
                    ⍝  [2] - (charvec) Additional HTTP headers.  If none, just set to ''.
                    ⍝  [3] - (charvec) HTTP content.             If none, just set to ''.
     
 :If (⊂##.HTTPUtils.lc CMD.Command)∊'get' 'post'
   t←,'ZI2,<:>,ZI2,<:>,ZI2'⎕FMT 1 3⍴3↓⎕TS
   r←0 ''('The time is ',t,' and you asked for the page:',CMD.Page)
     
 :Else
   r←('500 Invalid command: ',CMD.Command)'' ''
 :EndIf
∇

∇ z←ToRaw z;⎕IO
 :If ⊃80≠⎕DR' '
   ⎕IO←0
   z←(⎕NXLATE 0)[⎕AV⍳z]
 :Else
   z←8 int ⎕UCS z ⍝ 8-bit signed integers
 :EndIf
∇

 int←{ ⍝ Signed from unsigned integer.
   ↑⍵{(⍺|⍵+⍺⍺)-⍵}/2*⍺-0 1
 }

 uns←{ ⍝ Unsigned from signed integer.
   (2*⍺)|⍵
 }

:EndNamespace 