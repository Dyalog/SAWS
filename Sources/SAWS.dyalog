:Namespace SAWS
⍝ === VARIABLES ===

  URL←Service←LastCallRequest←LastCallResponse←AltResponse←AltRequest←LastRunRequest←LastRunResponse←''
  SILENT←DEBUG←TRACE←0

  _←⍬
  _,←,⊂'<style type="text/css">    '
  _,←,⊂'        BODY { color: #000000; background-color: white; font-family: Verdana; margin-left: 0px; margin-top: 0px; }'
  _,←,⊂'        #content { margin-left: 30px; font-size: .70em; padding-bottom: 2em; }'
  _,←,⊂'        A:link { color: #336699; font-weight: bold; text-decoration: underline; }'
  _,←,⊂'        A:visited { color: #6699cc; font-weight: bold; text-decoration: underline; }'
  _,←,⊂'        A:active { color: #336699; font-weight: bold; text-decoration: underline; }'
  _,←,⊂'        A:hover { color: cc3300; font-weight: bold; text-decoration: underline; }'
  _,←,⊂'        P { color: #000000; margin-top: 0px; margin-bottom: 12px; font-family: Verdana; }'
  _,←,⊂'        pre { background-color: #e5e5cc; padding: 5px; font-family: Courier New; font-size: x-small; margin-top: -5px; border: 1px #f0f0e0 solid; }'
  _,←,⊂'        td { color: #000000; font-family: Verdana; font-size: .7em; }'
  _,←,⊂'        h2 { font-size: 1.5em; font-weight: bold; margin-top: 25px; margin-bottom: 10px; border-top: 1px solid #003366; margin-left: -15px; color: #003366; }'
  _,←,⊂'        h3 { font-size: 1.1em; color: #000000; margin-left: -15px; margin-top: 10px; margin-bottom: 10px; }'
  _,←,⊂'        ul { margin-top: 10px; margin-left: 20px; }'
  _,←,⊂'        ol { margin-top: 10px; margin-left: 20px; }'
  _,←,⊂'        li { margin-top: 10px; color: #000000; }'
  _,←,⊂'        font.value { color: darkblue; font: bold; }'
  _,←,⊂'        font.key { color: darkgreen; font: bold; }'
  _,←,⊂'        font.error { color: darkred; font: bold; }'
  _,←,⊂'        .heading1 { color: #ffffff; font-family: Tahoma; font-size: 26px; font-weight: normal; background-color: #003366; margin-top: 0px; margin-bottom: 0px; margin-left: -30px; padding-top: 10px; padding-bottom: 3px; padding-left: 15px; width: 105%; }'
  _,←,⊂'        .button { background-color: #dcdcdc; font-family: Verdana; font-size: 1em; border-top: #cccccc 1px solid; border-bottom: #666666 1px solid; border-left: #cccccc 1px solid; border-right: #666666 1px solid; }'
  _,←,⊂'        .frmheader { color: #000000; background: #dcdcdc; font-family: Verdana; font-size: .7em; font-weight: normal; border-bottom: 1px solid #dcdcdc; padding-top: 2px; padding-bottom: 2px; }'
  _,←,⊂'        .frmtext { font-family: Verdana; font-size: .7em; margin-top: 8px; margin-bottom: 0px; margin-left: 32px; }'
  _,←,⊂'        .frmInput { font-family: Verdana; font-size: 1em; }'
  _,←'        .intro { margin-left: -15px; }           ' ' </style>' ''
  STYLE←_

  ⎕ex '_'

⍝ === End of variables definition ===

  (⎕IO ⎕ML ⎕WX)←1 3 3

  ∇ r←larg Call rarg;service;method;arg;ok;cmd;port;req;hdr;z;page;protocol;host;lchost;req2send;mask;tmp;ss;http;body;resp;soapaction;xmlns;cert;secure;ssl;length;t;m;certdir;chunked;chunk;buffer;chunklength;done;data;datalen;header;wr;getchunklen;h2d;len
               ⍝ Invoke a Web Service
   
               ⍝ larg[1] - host name
               ⍝ larg[2] - port number (defaults to 80 for http, 443 for https)
               ⍝ larg[3] - page name (defaults to service name)
               ⍝ larg[4] - soapaction (if empty, we build a default value)
               ⍝ larg[5] - Client certificate OR 1 to run securely
               ⍝ larg[6] - SSLValidation flags (see Conga documentation)
               ⍝ larg[7] - Root certificate directory
   
               ⍝ rarg takes one of two forms:
               ⍝  1) a simple character vector representing the entire SOAP over HTTP message; OR
               ⍝  2) a 3 item nested vector containing:
               ⍝     [1] service - web service name
               ⍝     [2] method - web service method to execute
               ⍝     [3] arg which can take two forms:
               ⍝          1) a simple character vector representing the entire SOAP message (we build the HTTP part); OR
               ⍝          2) the arguments to the web service method in one of the following forms:
               ⍝             ('name' 'value' {'name2' 'value2' ... 'nameN' 'valueN'})
               ⍝             (N,2)⍴'name' 'value' ... 'nameN' 'valueN'
               ⍝             (('name' 'value'){('name2' 'value2')...('nameN' 'valueN')})
               ⍝             (N,3)⍴ level 'name' 'value' ... levelN 'nameN' 'valueN'
   
               ⍝ r[1] return code (0=no error, 1=SOAP Fault, 2=Conga Error, 3=HTTP Error, ¯1=could not understand request)
               ⍝  [2] details if an error, or the result of the SOAP call
   
    :If 0=⎕NC'DRC' ⋄ 'DRC'⎕CY'conga' ⋄ :EndIf
   
    :If 0≠1⊃z←DRC.Init'' ⋄ r←2 z ⍝ flag Conga error
      :GoTo exit
    :EndIf
   
    h2d←{⎕IO←0 ⋄ 16⊥'0123456789abcdef'⍳U.lc ⍵} ⍝ hex to decimal
    getchunklen←{¯1=len←¯1+⊃(NL⍷⍵)/⍳⍴⍵:¯1 ¯1 ⋄ chunklen←h2d len↑⍵ ⋄ (⍴⍵)<len+chunklen+4:¯1 ¯1 ⋄ len chunklen}
   
    :If 1=≡larg ⋄ larg←,⊂larg ⋄ :EndIf ⍝ if only host name supplied nest it
    larg←7↑larg,(⍴,larg)↓''⍬'' '' '' 32 ''
    host port page soapaction cert ssl certdir←larg
    :If cert≡1 ⋄ cert←⎕NEW DRC.X509Cert ⋄ :EndIf
    secure←IsSecure cert
   
    lchost←HTTPUtils.lc host
      ⍝ Try to figure out protocol
    :If 'http://'≡7↑lchost ⋄ protocol←'http://' ⋄ host←7↓host
    :ElseIf 'https://'≡8↑lchost ⋄ protocol←'https://' ⋄ host←8↓host ⋄ secure←1
    :Else ⋄ protocol←'http',(~secure)↓'s://' ⍝ default to HTTP{S}
    :EndIf
   
    :If secure ⋄ {}DRC.SetProp'RootCertDir'certdir ⋄ :EndIf
   
    :If 1=≡rarg ⋄ req2send←rarg ⍝ if simple vector supplied, it's the entire SOAP over HTTP message
    :Else
      service method arg←rarg ⍝ otherwise, decompose right argument
   
      :If 0∊⍴,port ⋄ port←(1+protocol≡'https://')⊃80 443 ⋄ :EndIf ⍝ if port isn't supplied, use 80 or 443 if using SSL
      :If 0∊⍴,page ⋄ page←service ⋄ :EndIf ⍝ default page is the same as the service name
      :If 0∊⍴,host ⋄ host←'localhost' ⋄ :EndIf ⍝ default host is localhost
   
      :If 0∊⍴arg ⋄ arg←'' '' ⍝ arg is empty, supply default of no parameters for method
      :ElseIf (2=≡arg)∧(1=⍴⍴arg)∧0=2|¯1↑⍴arg ⋄ arg←((0.5××/⍴arg),2)⍴arg ⍝ arg is a vector of name/value pairs
      :ElseIf (3=≡arg)∧1=⍴⍴arg ⋄ arg←⊃arg ⍝ arg is a vector of nested name/value pairs (('name1' 'value1')('name2' 'value2'))
      :EndIf
   
      :If 1<≡arg
        :If 2=¯1↑⍴arg ⋄ arg←1,((¯2↑1,⍴arg)⍴arg),⊂⍬
        :Else ⋄ arg←4↑[2]arg,⊂⍬
        :EndIf⍝ 0 2⍴0 ⍝ Make correctly formed "MLS"
      :EndIf
   
      service,←(0≠⍴service)/'/'
      method xmlns←method{((⍵-1)↑⍺)(⍵↓⍺)}1⍳⍨' xmlns='⍷method
      :If 0∊⍴xmlns ⋄ xmlns←'xmlns="',protocol,host,((0≠⍴service)/'/',service),'"' ⋄ :EndIf
   
      :If 1=≡arg ⋄ req←arg ⍝ if arg is simple vector, use it as the SOAP message
      :Else
        req←1 SOAP.EncodeRequest(method,' ',xmlns)arg ⍝ SOAP-encoded request
      :EndIf
   
      host←(-'/'=¯1↑host)↓host
      :If 0∊⍴soapaction ⋄ soapaction←' '~⍨'"',protocol,host,'/',service,method,'"' ⋄ :EndIf
   
      hdr←'POST /',page,' HTTP/1.1',NL
      hdr,←'Host: ',host,NL
      hdr,←'SOAPAction: ',soapaction,NL
      hdr,←'Content-Type: text/xml; charset=utf-8',NL
      hdr,←'Content-Length: ',⍕⍴req
   
      req2send←hdr,NL,NL,req
    :EndIf
   
    :If DEBUG bit 1 ⋄ LastCallRequest←req2send ⋄ :EndIf
    :If DEBUG bit 2 ⋄ :AndIf 0<⍴AltRequest ⋄ req2send←AltRequest ⋄ :EndIf
   
    :If TRACE bit 0
      ss←(1+∨/NL⍷req2send)⊃(⎕UCS 13 13)(NL,NL)
      1 Output'>>> SAWS.Call <<<'
      1 Output'hdr= ',terse((~mask←∨\ss⍷req2send)/req2send)~⎕UCS 10
      1 Output'req= ',terse tmp←(⍴ss)↓mask/req2send
      1 Output'xml= ',terse ⎕XML ⎕XML tmp
    :EndIf
   
    ok cmd←2↑z←DRC.Clt''host port'Text',secure/('X509'cert)('SSLValidation'ssl) ⍝ Connect to server
    :If 0≠ok ⋄ r←2 z ⍝ flag Conga error
      :GoTo exit
    :EndIf
   
    :If 0≠1⊃z←DRC.Send cmd req2send
      r←2 z ⍝ Send it (flag Conga error, if any)
      :GoTo exit
    :EndIf
   
    resp←'' ⍝ initialize the response
    length←0
    chunked chunk buffer chunklength←0 '' '' 0
    done data datalen header←0 ⍬ 0(0 ⍬)
    :Repeat
      :If ~done←0≠1⊃wr←DRC.Wait cmd 5000            ⍝ Wait up to 5 secs
        :If wr[3]∊'Block' 'BlockLast'             ⍝ If we got some data
          :If chunked
            chunk←4⊃wr
          :ElseIf 0<⍴data,←4⊃wr
          :AndIf 0=1⊃header
            header←HTTPUtils.DecodeHeader data
            :If 0<1⊃header
              data←(1⊃header)↓data
              :If chunked←∨/'chunked'⍷(2⊃header)HTTPUtils.GetValue'Transfer-Encoding' ''
                chunk←data
                data←''
              :Else
                datalen←1⊃((2⊃header)HTTPUtils.GetValue'Content-Length' 'Numeric'),¯1 ⍝ ¯1 if no content length not specified
              :EndIf
            :EndIf
          :EndIf
        :Else
          r←2 wr ⍝ Error?
          {}DRC.Close cmd
          :GoTo exit
        :EndIf
        :If chunked
          buffer,←chunk
          :While done<¯1≠1⊃(len chunklength)←getchunklen buffer
            :If (⍴buffer)≥4+len+chunklength
              data,←chunklength↑(len+2)↓buffer
              buffer←(chunklength+len+4)↓buffer
              :If done←0=chunklength ⍝ chunked transfer can add headers at the end of the transmission
                header[2]←⊂(2⊃header)⍪2⊃HTTPUtils.DecodeHeader buffer
              :EndIf
            :EndIf
          :EndWhile
        :Else
          done←done∨'BlockLast'≡3⊃wr                        ⍝ Done if socket was closed
          :If datalen>0
            done←done∨datalen≤⍴data ⍝ ... or if declared amount of data rcvd
          :Else
            done←done∨':Envelope>'{⍺≡(-⍴⍺)↑⍵}data
          :EndIf
        :EndIf
      :EndIf
    :Until done
    resp←data
⍝    :Repeat
⍝      :If 0≠1⊃z←DRC.Wait cmd 5000              ⍝ Loop, collecting pieces of response
⍝        r←2 z ⍝ flag Conga error
⍝        {}DRC.Close cmd
⍝        :GoTo exit
⍝      :ElseIf z[3]∊'Block' 'BlockLast'
⍝        resp←resp,4⊃z
⍝        :Trap 0
⍝          :If length=0
⍝          :AndIf ∨/m←(NL,NL)⍷resp
⍝          :AndIf ~0∊⍴t←(2⊃HTTPUtils.DecodeHeader resp)HTTPUtils.GetValue'content-length' 'Numeric'
⍝            length←t+3+m⍳1
⍝          :EndIf
⍝        :EndTrap
⍝      :EndIf
⍝    :Until ('BlockLast'≡3⊃z)∨(length≤⍴resp)∨':Envelope>'{⍺≡(-⍴⍺)↑⍵}resp   ⍝ Until error or all data received
   
    {}DRC.Close cmd
    :If DEBUG bit 1 ⋄ LastCallResponse←resp ⋄ :EndIf
    r←¯1 'Empty response from host'
    :If ~0∊⍴resp
      http←HTTPUtils.ParseHTTPResponse(resp(2⊃header)) ⍝ build http struct and split off body
      :If 200≠http.StatusCode
        r←3((http.(StatusCode Reason)),⊂resp) ⍝ flag HTTP error
        :GoTo exit
      :EndIf
      r←SOAP.DecodeResponse http.MessageBody ⍝ if no error
      r[1]←(0 1 ¯1,r[1])[1 0 ¯1⍳r[1]] ⍝ adjust result to return 0 for no error
    :EndIf
   exit:
  ∇

  ∇ r←host DefineService arg;service;page;mask;ref;api;ns;expfns;pvm;wsdl;svcname;port;url
                          ⍝ Builds the web service definition
                          ⍝ host - host name and port, used to get the port for the service
                          ⍝
                          ⍝ arg[1] - page name for the service
                          ⍝ arg[2] - Service (namespace name or reference to namespace containing the service)
                          ⍝ If arg[2]≡'', we search for a namespace matching the supplied page name
                          ⍝ arg[3] - root URL for the service (in the form 'HTTP{S}://...')
                          ⍝
                          ⍝ r[1] - return code (0-success, 1-failure)
                          ⍝ r[2] - service definition (success), or '' (failure)
                          ⍝        [1] API
                          ⍝        [2] ExportedFns
                          ⍝        [3] ServiceName
                          ⍝        [4] WSDL
                          ⍝        [5] namespace
    page service url←arg
    :If 'http'≢HTTPUtils.lc 4↑url ⋄ url←'http://',url ⋄ :EndIf
    :If 0∊⍴host ⋄ port←'80'  ⍝ default to port 80 (HTTP)
    :Else ⋄ port←1↓(∨\':'=host)/host ⍝ otherwise try to extract port
      :If 0∊⍴port ⋄ port←'80' ⍝ if no port specificed, default to port 80 (HTTP)
      :EndIf
    :EndIf
   
    r←1 '' ⍝ initialize result
   
    :If ~0∊⍴service ⍝ if service namespace name supplied
      ns←service ⍝ use it
    :Else
      ns←MatchNamespace page ⍝ otherwise, try to find namespace matching the page name
    :EndIf
   
    :If ~0∊⍴ns
      mask←'API' 'ExportedFns' 'ServiceName' 'WSDL' 'BuildAPI'∊(ref←⍎ns).⎕NL ¯2 ¯3
      :If ∧/4↑mask ⍝ are all components defined?
        r←0((ref.(API ExportedFns ServiceName WSDL)),⊂ns)  ⍝ use them
      :ElseIf mask[5] ⍝ do we have BuildAPI?
        svcname←ns~'#' ⋄ ((svcname='.')/svcname)←'/' ⋄ svcname←('/'=⍬⍴svcname)↓svcname
        api←ref.BuildAPI
        expfns←2⊃¨,¨1⊃¨api ⍝ exported functions based on the API
        pvm←0 2⍴⊂''
        pvm←pvm⍪'name'svcname
        pvm←pvm⍪'serviceURL'(url,':',port,'/',svcname,'/') ⍝ where the SOAP method calls are actually sent to
        pvm←pvm⍪'wsdlURL'(url,':',port,'/',svcname,'?WSDL/') ⍝ location of the WSDL XML document
        wsdl←SOAP.PrepareWSDL api pvm ⍝ build the WSDL
        r←0(api expfns svcname wsdl ns)
      :EndIf
    :EndIf
  ∇

  ∇ R←HandleRequest(cmd session);method;arg;ok;type;res;status;hdr;mpvm;TIME;buffer;name;ns;api;wsdl;expfns;WSDL;ServiceName;ExportedFns;API;rc;svc;ServiceNS;host
                    ⍝ Web Service handler build for embedding in the Conga sample Web Server
                    ⍝ Return HTTP return code, HTTP headers, HTTP body
                    ⍝ buffer is ignored, entire input expected to be in "cmd"
   
    buffer←session.Buffer
    :If DEBUG bit 1 ⋄ LastRunRequest←buffer ⋄ :EndIf
    :If TRACE bit 0
      1 Output'>>> SAWS.HandleRequest <<<'
      1 Output'Command: ',terse(cmd.Command~⎕UCS 10)
      1 Output'Page:    ',terse(cmd.Page~⎕UCS 10)
      1 Output'buffer:  ',terse(buffer~⎕UCS 10)
      TIME←⎕AI[2]
    :EndIf
   
    host←cmd.Headers HTTPUtils.GetValue('host' '') ⍝ get the host name
    rc svc←host DefineService cmd.Page Service URL ⍝ build the service definition (Service and URL are defined in SAWS.Run)
   
    :If 0≠rc ⍝ failed to define service?
      type←¯1 ⋄ res←'Service.Invalid' 'The Web Service definition is not valid'
      status←'500 Internal Server Error'
      res←type SOAP.EncodeResponse res
      hdr←'content-type: text/xml'
    :Else
      API ExportedFns ServiceName WSDL ServiceNS←svc
      name←HTTPUtils.lc ServiceName
   
      :If ('get /',name,'?wsdl')≡(10+⍴name)↑cmd.Input ⋄ :AndIf ' /'∨.=1↑(10+⍴name)↓cmd.Input ⍝ Display WSDL?
        res←WSDL ⋄ status←'200 OK'
        hdr←'content-type: text/xml'
      :ElseIf ('get /',name)≡(5+⍴name)↑cmd.Input
      :OrIf (('post /',name,'/')≡(7+⍴name)↑cmd.Input)∧~(⊂'soapaction')∊cmd.Headers[;1]
        res status←ServiceHTML(cmd buffer)
        hdr←'content-type: text/html'
      :Else
                        ⍝ Since our WSDL (based on our API) says to use 'document/literal', no
                        ⍝ datatyping will be passed in the SOAP, so we need to pass the global API
                        ⍝ in order to describe to DecodeRequest how to datatypize everything.
        (ok res)←API SOAP.DecodeRequest buffer
   
        :If ok ⍝ success in decoding?
          (method arg mpvm)←res
   
          :If (⊂method)∊ExportedFns           ⍝ Is the call allowed?
            :Trap (~DEBUG bit 0)/0
              (type res)←⍎ServiceNS,'.',method,' arg'
              :If type≠¯1 ⋄ res←method res mpvm ⋄ :EndIf
            :Else
              res←'Server.Unexpected' 'The Web Service generated an unexpected error.'(¯2↓∊⎕DM,¨⊂NL)
              type←¯1
            :EndTrap
          :Else                               ⍝ Not in list of allowed methods
            res←'Client.Permission' 'The method call is not allowed.'method
            type←¯1
          :EndIf
   
        :Else ⍝ bad request
          type←¯1
        :EndIf
   
        status←(1+type≠¯1)⊃'500 Internal Server Error' '200 OK'
        res←type SOAP.EncodeResponse res
        hdr←'content-type: text/xml'
      :EndIf
    :EndIf
    R←status hdr res
  ∇

  ∇ {r}←{a}Init w
         ⍝ Initialize SAWS
         ⍝ w - dummy for consistency with Conga, SQAPL, etc
         ⍝ a - 1=hard initialization, 0=soft initialization
    a←{0::⍵ ⋄ a}1
    :If 0=⎕NC'DRC' ⋄ 'DRC'⎕CY'conga' ⋄ :EndIf
    :If a=1
      ⎕TKILL ⎕TNUMS     ⍝ Kill any existing threads
      r←¯1 DRC.Init'' ⍝ Initialize CONGA
    :EndIf
    URL←Service←LastCallRequest←LastCallResponse←AltResponse←AltRequest←LastRunRequest←LastRunResponse←''
    SILENT←DEBUG←TRACE←0
  ∇

  ∇ r←IsSecure cert;IsCert;ind;⎕ML
               ⍝ tests if cert contains a valid certificate
    ⎕ML←1
    r←{0::0 ⋄ (⎕CLASS DRC.X509Cert)≡⎕CLASS ⍵}cert
  ∇

  ∇ r←MatchNamespace page;db;ind;chunk;nss;mask;nsslc;⎕IO;⎕ML;fns;root
                    ⍝ Finds namespace matching the page name for the web service
                    ⍝ Will find nested namespaces (e.g. /webservices/service1 maps to #.WebServices.Service1)
                    ⍝ Note: Because page names are case insensitive we treat namespaces as case insensitive (#.Foo ≡ #.foo)
                    ⍝  page - page (service name) possibly with a method name as well (/WebServices/Service1/Method1)
                    ⍝  root - the root to search from
                    ⍝  r - namespace name where the service is defined, or '' if not found
                    ⍝
    ⎕ML ⎕IO←1
    page←HTTPUtils.lc page
    db←{(+/∧\' '=⍵)↓⍵}
    page←⌽db⌽db page ⍝ remove any leading or trailing blanks
    ((page='/')/page)←'.' ⍝ replace '/' with '.'
    r←''
    root←'#'⍝ start with root namespace
    :While ~0∊⍴page
      page←('.'=⍬⍴page)↓page ⍝ drop off leading '.'
      chunk←(¯1+ind←page⍳'.')↑page ⍝ grab
      nsslc←HTTPUtils.lc¨nss←(⍎root).⎕NL ¯9.1 ⍝
      mask←nsslc≡¨⊂chunk
      :Select +/mask
      :Case 0 ⍝ namespace not found, could be a method name
        :If '.'∊ind↓page ⋄ :Return
        :Else ⋄ r←root ⋄ :Return
        :EndIf
      :Case 1 ⍝ 1 namespace found
        root,←'.',⊃mask/nss
        page←ind↓page
      :Else ⍝ more than 1 namespace found (i.e. #.FOO and #.foo)
        :Return
      :EndSelect
    :EndWhile
    r←root
  ∇

  ∇ r←NL ⍝ return newline (CRLF)
    r←⎕UCS 13 10
  ∇

  ∇ {trace}Output msg
                  ⍝ Simple output function, all output to the session should be funneled through here
    :If SILENT≤{0::0 ⋄ ⍎⍵}'trace'
      ⎕←msg
    :EndIf
  ∇

  ∇ r←ParseHTTP stream;ind;http;body;httpstruct
                   ⍝ parses an HTTP message
                   ⍝
    ind←¯1+((NL,NL)⍷stream)⍳1
    http←(ind⌊⍴stream)↑stream
    httpstruct←⎕NS''
    body←(4+ind)↓stream
  ∇

  ∇ r←request ResolveNamespaces response;xmlresp;nsdefs;nsrefs;refs;ancinds;i;defs;found;⎕ML;xmlreq;reqdefs;missing;mask;hit;updated
                    ⍝ resolves any missing namespace references in the response
    ⎕ML←1
    nsdefs←{⍵{⍵/6↓⍺}'xmlns:'≡6↑⍵} ⍝ namespace definitions
    nsrefs←{{((':'∊⍵)∧'xmlns:'≢6↑⍵)/(∧\':'≠⍵)/⍵}(∧\'='≠⍵)/⍵}
    xmlresp←⎕XML response
    ancinds←ancestors xmlresp[;1]
    defs←nsdefs¨¨1⌷[2]¨xmlresp[;4]
                    ⍝ find any unresolved namespace references
    refs←((⊂¨nsrefs¨xmlresp[;2]),¨nsrefs¨¨1⌷[2]¨xmlresp[;4])~¨⊂⊂''
    updated←0
    :For i :In ⍳⊃⍴xmlresp
      :If 0∊found←(i⊃refs)∊⊃,/(i⊃ancinds)⊃¨⊂defs ⍝ any unresolved?
        :If 0=⎕NC'xmlreq'
          xmlreq←⎕XML request
          reqdefs←nsdefs¨¨1⌷[2]¨xmlreq[;4]
        :EndIf
        :For missing :In (~found)/i⊃refs
          mask←missing∊¨¨reqdefs  ⍝ this is dangerous, should match up tags
          :Select +/hit←1∊¨mask
          :Case 0 ⍝ not found, just skip it and hope
          :Case 1 ⍝ got a match, add the namespace reference to the Envelope element
            xmlresp[1;4]←⊂((⊂1 4)⊃xmlresp)⍪(⊃hit/mask)⌿⊃hit⌿xmlreq[;4]
            refs←((⊂¨nsrefs¨xmlresp[;2]),¨nsrefs¨¨1⌷[2]¨xmlresp[;4])~¨⊂⊂''
            updated←1
          :Else ⍝ got more than one match, ambiguousness!
            'Ambiguous namespace reference'⎕SIGNAL 701
          :EndSelect
        :EndFor
      :EndIf
    :EndFor
    :If updated
      r←('whitespace' 'preserve'⎕XML xmlresp)~NL
    :Else
      r←response
    :EndIf
  ∇

  ∇ {r}←{svc}Run arg;thread;srvname;port
                    ⍝ Run a Web Service using the Conga Demo WebServer
                    ⍝ svc - name of or reference to the namespace containing the service definition
                    ⍝ arg[1] - port to run on (default 8080)
                    ⍝ arg[2] - run in a separate thread? (default 0)
                    ⍝ arg[3] - server name (default 'HTTPSRV')
                    ⍝ arg[4] - url for host (default 'localhost')
                    ⍝
                    ⍝ If Service is supplied, the server runs only that Web Service with the supplied port and server name
                    ⍝ Note: Multiple Web Services can be run simultaneously provided that each one is run in a separate thread
                    ⍝       and has a separate port and server name
                    ⍝
                    ⍝ If Service is not supplied, SAWS searchs for a namespace corresponding to the Web Service name
                    ⍝ effectively allowing multiple Web Services to be run from a single server
                    ⍝
    :If 0=⎕NC'DRC' ⋄ 'DRC'⎕CY'conga' ⋄ :EndIf
    {}DRC.Init''
    ⎕EX'STOP' ⍝ remove STOP flag
    port thread srvname URL←4↑arg,(⍴,arg)↓8080 0 'HTTPSRV' 'localhost'
    :If 0∊⍴srvname ⋄ srvname←'HTTPSRV' ⋄ :EndIf
    :If 0∊⍴URL ⋄ URL←'localhost' ⋄ :EndIf
    :If 0=⎕NC'svc' ⋄ Service←''
    :Else ⋄ Service←⍕svc
    :EndIf
    :If thread
      r←WebServer.Run&'##.HandleRequest'port srvname
    :Else
      r←WebServer.Run'##.HandleRequest'port srvname
    :EndIf
  ∇

  ∇ {r}←{svc}RunSecure arg;thread;srvname;port;certpath;cert
                    ⍝ Run a Secure Web Service using the Conga WebServer
                    ⍝ svc - name of or reference to the namespace containing the service definition
                    ⍝ arg[1] - port to run on (default 8080)
                    ⍝ arg[2] - run in a separate thread? (default 0)
                    ⍝ arg[3] - server name (default 'HTTPSRV')
                    ⍝ arg[4] - root URL for service
                    ⍝ arg[5] - path for certificates, if empty or non-existent, use path from #.Samples.CertPath
                    ⍝ arg[6] - server certificate (DRC.X509Cert instance) or empty/non-existent if not using certificate
                    ⍝
                    ⍝ If Service is supplied, the server runs only that Web Service with the supplied port and server name
                    ⍝ Note: Multiple Web Services can be run simultaneously provided that each one is run in a separate thread
                    ⍝       and has a separate port and server name
                    ⍝
                    ⍝ If Service is not supplied, SAWS searchs for a namespace corresponding to the Web Service name
                    ⍝ effectively allowing multiple Web Services to be run from a single server
                    ⍝
    :If 0=⎕NC'DRC' ⋄ 'DRC'⎕CY'conga' ⋄ :EndIf
    {}DRC.Init''
    ⎕EX'STOP' ⍝ remove STOP flag
    port thread srvname URL certpath cert←6↑arg,(⍴,arg)↓445 0 'HTTPSRV' 'localhost' ''(⎕NEW DRC.X509Cert)
    :If 0∊⍴srvname ⋄ srvname←'HTTPSRV' ⋄ :EndIf
    :If 0∊⍴URL ⋄ URL←'localhost' ⋄ :EndIf
    :If 0=⎕NC'svc' ⋄ Service←''
    :Else ⋄ Service←⍕svc
    :EndIf
    :If thread
      r←certpath WebServer.HttpsRun&'##.HandleRequest'port srvname cert
    :Else
      r←certpath WebServer.HttpsRun'##.HandleRequest'port srvname cert
    :EndIf
  ∇

  ∇ (res status)←ServiceHTML(cmd buffer);⎕IO;method;post;inmls;intxt;innames;outmls;outtxt;outnames;i;dec;replace;f;name;lcname;len;svc;svcmls;ind;ismls
                         ⍝ simple HTML interface for methods
    ⎕IO←1
    replace←{ ⍝ inefficent but functional replacement function
      ⎕IO←1 ⋄ ⍺←'' ⋄ txt start end←,¨⍵
      0=⍴txt:⍺
      s←⍴start
      start≢s↑txt:(⍺,1↑txt)∇(1↓txt)start end
      n←{⍬≡0⍴⍵:⍵ ⋄ s+(s↓txt)⍳⍵}end
      (⍺,⍺⍺(n↑txt))∇(n↓txt)start end
    }
    dec←{  ⍝ hex string → integer
      ⎕ML ⎕IO←0
      16⊥16|'0123456789abcdef0123456789ABCDEF'⍳⍵
    }
    len←⍴lcname←HTTPUtils.lc ServiceName
   
    :If ('post /',lcname)≡(6+len)↑cmd.Input
      method←{(∧\⍵≠' ')/⍵}(7+len)↓cmd.Input
      post←1
    :ElseIf ('get /',lcname)≡(5+len)↑cmd.Input
      method←{(∧\⍵≠' ')/⍵}{('/'=1↑⍵)↓⍵}(5+len)↓cmd.Input
      :If (⍴method)≥i←method⍳'?' ⍝ parameters passed in URL?
        buffer←i↓method ⍝ if so, make it look like a post operation
        method←(i-1)↑method
        post←1
      :Else
        post←0
      :EndIf
    :Else
      :GoTo NOTFOUND
    :EndIf
   
    :If method∧.=' ' ⍝ No method named
      res←'<html><head>',(1⊃,,/STYLE,¨⎕UCS 13),'<title>',ServiceName,'</title></head>'
      res,←'<body>'
      res,←'<div id="content"><p class="heading1">',ServiceName,'</p><br/>'
      res,←'<p class="intro">The following operations are supported.  For a formal definition, please review the <a href="../',ServiceName,'?WSDL" target="_blank">Service Description</a>. </p>'
      res,←'<ul>'
      :For f :In ExportedFns
        res,←'<li><a href="/',ServiceName,'/',f,'">',f,'</a></li>'
      :EndFor
      res,←'</ul></div></body></html>'
      status←'200 OK'
      :Return
    :EndIf
   
    :If (1+⍴API)=i←(HTTPUtils.lc¨ExportedFns)⍳⊂method
      :GoTo NOTFOUND
    :EndIf
    method←i⊃ExportedFns
   
    svc inmls outmls←(i⊃API)      ⍝ the API give MLS input and output
                         ⍝⍝ we just need to fill the value fields now
    svcmls←4⊃,svc
    :If post
                             ⍝ Get values from a POST operation on the generated HTML page.
                             ⍝ It relies on the order of the html inputs to be the same as the API description.
                             ⍝ PS : the last one is the submit button, ignore it.
                             ⍝ Syntax of buffer : name1=value1&name2=value2&...
      intxt←(↑⍴inmls)↑{(⍵⍳'=')↓⍵}¨{(⍵≠'&')⊂⍵}buffer
                             ⍝ replace '+' by '%20'
      intxt←{{'%20'}replace ⍵'+' 1}¨intxt
                             ⍝ decode percent-encoded values
      intxt←{{⎕UCS dec 2↑1↓⍵}replace ⍵'%' 3}¨intxt
                             ⍝ decode unicode characters, but only for input to function
                             ⍝ the html text will keep the &#NNNN; pattern
      inmls[;3]←{{⎕IO←1 ⋄ ⎕UCS 2⊃⎕VFI 2↓¯1↓⍵}replace ⍵'&#' ';'}¨intxt
   
      inmls←2⊃inmls #.SAWS.SOAP.SOAP2Data inmls
   
      :Trap (~DEBUG bit 0)/0         ⍝ Are we in debug mode?
        (ismls outmls)←⍎ServiceNS,'.',method,' inmls'
      :Else
        res←'The Web Service generated an unexpected error:',NL,(¯2↓∊⎕DM,¨⊂NL)
        :GoTo ERROR
      :EndTrap
   
      :If ismls=¯1
        res←,⍕outmls
        :GoTo ERROR
      :ElseIf 0=ismls ⍝ if the result is not an MLS (meaning it's APL data), fake it for the HTTP interface
        outmls←1 4⍴1 'Result'outmls(0 2⍴⊂'')
      :EndIf
    :Else
                             ⍝ default input value
      intxt←inmls[;3]
    :EndIf
    outtxt←,∘⍕¨outmls[;3]
   
                         ⍝ replace unicode with HTML pattern &#NNNN;
    outtxt←{{128>⎕UCS ⍵:⍵ ⋄ '&#',(⍕⎕UCS ⍵),';'}replace ⍵'' 1}¨outtxt
                         ⍝ replace newlines with <br/>
    outtxt←{{'<br/>'}replace ⍵ NL(⍴NL)}¨outtxt
   
    res←'<html><head>',(1⊃,,/STYLE,¨⊂NL),'<title>',ServiceName,': ',method,'</title></head>'
    res,←'<body>'
    res,←'<div id="content"><p class="heading1">',ServiceName,': ',method,'</p><br/>'
    :If (⍬⍴⍴svcmls)≥ind←svcmls[;1]⍳⊂'documentation'
      res,←'<h3>',method,': ',((⊂ind,2)⊃svcmls),'</h3>'
    :EndIf
    res,←'<p><form name="saws_',method,'_form" method="post" action="',method,'">'
   
    innames outnames←(inmls[;2])(outmls[;2]) ⍝ names of variables
   
    :If ~0∊⍴innames
      res,←'<p class="intro">Please enter the input parameter',(1=⍬⍴⍴innames)↓'s for the ',method,' method:</p>'
      res,←'<table>'
      res,←↑,/innames{'<tr><td>',⍺,'</td><td><input type="text" name="',⍺,'" value="',⍵,'"> </td></tr>'}¨intxt
      res,←'</table>'
    :EndIf
   
    res,←'<p> <input type="submit" name="Submit" value="Submit"> </p>'
   
    :If post ⍝ We should have results?
      res,←'<table border=1>'
      :If 0∊⍴outnames
        res,←'<tr><td>No Result</td></tr>'
      :Else
        res,←↑,/outnames{'<tr><td>',⍺,'</td><td>',⍵,'</td></tr>'}¨outtxt
      :EndIf
      res,←'</table>'
    :EndIf
   
    res,←'</form>'
    res,←'<p><a href="/',ServiceName,'">Return to main page</a></p>',NL
    res,←'</body></div></html>'
    status←'200 OK'
    :Return
   
   ERROR:
    status←'500 Internal Server Error'
    :Return
   
   NOTFOUND:
    status←'404 Not Found'
    res←'Error 404 : page not found.'
    :Return
  ∇

  ∇ {r}←Stop srvname
                     ⍝ Stop the Web Service server
                     ⍝ srvname - name of the server to stop (defaults to 'HTTPSRV' if srvname≡'')
                     ⍝ r[1] - 0 (success), otherwise error code
                     ⍝ r[2] - error name if r[1]≠0
                     ⍝ r[3] - error description if r[1]≠0
    :If 0∊⍴srvname ⋄ r←DRC.Close¨DRC.Names'.'
    :Else ⋄ r←DRC.Close srvname
    :EndIf
  ∇

  ∇ {address}Test close;Start;i;n;Time;r;port
                    ⍝ Start Web Service and make some calls to it
                    ⍝ address - web server address (defaults to 'localhost')
                    ⍝ close - =0 just start Web Service, =1 run test, =¯1 service already started, just run test
   
    port←8080
    :If 0=⎕NC'address' ⋄ address←'localhost' ⋄ :EndIf
   
    :If close≠¯1
      Init
      #.MyWebService Run port 1 ⍝ Start Server
      ⎕DL 1           ⍝ Give it time to wake up
    :EndIf
   
    :If close=0
      Output'Server ''HTTPSRV'' still running... To stop it, type:' ⋄ ''
      Output'SAWS.Stop '''''
      →0
    :EndIf
   
    Output'Running'(n←100)'tests...'
    Start←3⊃⎕AI
   
    :For i :In ⍳n
      r←address port Call'MyWebService' 'Regression'('Data' '2 4 6 8.1' 'Degree' 1 'Factor' 1000)
    :EndFor
   
    Time←(3⊃⎕AI)-Start
    Output i'calls in'Time'msec ='(1⍕÷Time÷1000×n)'calls/sec'
    Output'Response:'r
   
    :If close=1 ⋄ Stop'' ⋄ :EndIf ⍝ Server should shut down
  ∇

  ∇ {address}TestSecure close;Start;i;n;Time;r;port;clientcert;servercert
                    ⍝ Start Web Service and make some calls to it
                    ⍝ address - web server address (defaults to 'localhost')
                    ⍝ close - =0 just start Web Service, =1 run test, =¯1 service already started, just run test
   
    port←8080
    :If 0=⎕NC'address' ⋄ address←'localhost' ⋄ :EndIf
    :If close≠¯1
      Init''
      servercert←Samples.ReadCert'server/server'  ⍝ read the server certificate
      clientcert←Samples.ReadCert'client/client'  ⍝ read the client certificate
      #.MyWebService RunSecure port 1 '' '' ''servercert 96  ⍝ Start Server
      ⎕DL 1           ⍝ Give it time to wake up
    :EndIf
   
    :If close=0
      Output'Server ''HTTPSRV'' still running... To stop it, type:' ⋄ ''
      Output'SAWS.Stop '''''
      →0
    :EndIf
   
    Output'Running'(n←100)'tests using client certificate'
    Start←3⊃⎕AI
   
    :For i :In ⍳n
      r←address port'' ''clientcert 16 Call'MyWebService' 'Regression'('Data' '2 4 6 8.1' 'Degree' 1 'Factor' 1000)
      :If 0=10|i ⋄ Output i ⋄ :EndIf
    :EndFor
   
    Time←(3⊃⎕AI)-Start
    Output i'calls in'Time'msec ='(1⍕÷Time÷1000×n)'calls/sec'
    Output'Response:'r
   
    Output'Running'(n←100)'tests using blank client certificate'
    Start←3⊃⎕AI
   
    :For i :In ⍳n
      r←address port'' ''(⎕NEW DRC.X509Cert)32 Call'MyWebService' 'Regression'('Data' '2 4 6 8.1' 'Degree' 1 'Factor' 1000)
      :If 0=10|i ⋄ Output i ⋄ :EndIf
    :EndFor
   
    Time←(3⊃⎕AI)-Start
    Output i'calls in'Time'msec ='(1⍕÷Time÷1000×n)'calls/sec'
    Output'Response:'r
    :If close=1 ⋄ Stop'' ⋄ :EndIf ⍝ Server should shut down
  ∇

  ∇ r←ancestors v;bv;i;inds;mask;plens;scope;where;⎕IO
    ⎕IO←1
    r←(⍴v)⍴⊂⍬
    where←{⍵/⍳⍴⍵}
    plens←{⍵{⍵-⍨1↓⍵,1+⍴⍺}(where ⍵)}
    :For i :In 0,⍳⌈/v
      mask←i=v
      scope←i<v
      bv←mask∨scope
      (bv/r)←(bv/r),¨(plens bv/mask)/where mask
    :EndFor
  ∇

    bit←{⎕IO←0
      0=⍺:0 ⍝ all bits turned off
      ¯1=⍺:1 ⍝ all bits turned on
      ⍵⊃⌽((1+⍵)⍴2)⊤⍺}

  terse←{(((65⌊⍴⍵)⌈(⍴⍵)×~TRACE bit 1)↑⍵),((65<⍴⍵)∧TRACE bit 1)/'...'}

:EndNamespace