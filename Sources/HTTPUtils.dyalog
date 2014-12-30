:Namespace HTTPUtils
⍝ === VARIABLES ===

  HTTPStatusCodes←40 2⍴100 'Continue' 101 'Switching Protocols' 200 'OK' 201 'Created' 202 'Accepted' 203 'Non-Authoritative Information' 204 'No Content' 205 'Reset Content' 206 'Partial Content' 300 'Multiple Choices' 301 'Moved Permanently' 302 'Found' 303 'See Other' 304 'Not Modified' 305 'Use Proxy' 307 'Temporary Redirect' 400 'Bad Request' 401 'Unauthorized' 402 'Payment Required' 403 'Forbidden' 404 'Not Found' 405 'Method Not Allowed' 406 'Not Acceptable' 407 'Proxy Authorization Required' 408 'Request Timeout' 409 'Conflict' 410 'Gone' 411 'Length Required' 412 'Precondition Failed' 413 'Request Entity Too Large' 414 'Request-URI Too Long' 415 'Unsupported Media Type' 416 'Requested Range Not Satisfiable' 417 'Expectation Failed' 500 'Internal Server Area' 501 'Not Implemented' 502 'Bad Gateway' 503 'Service Unavailable' 504 'Gateway Timeout' 505 'HTTP Version Not Supported'

  NL←(⎕ucs 13 10)


⍝ === End of variables definition ===

  (⎕IO ⎕ML ⎕WX)←1 0 3

  ∇ HTTPCmd←DecodeCmd req;buf;input;args;z
                    ⍝ Decode an HTTP command line: get /page&arg1=x&arg2=y
                    ⍝ Return namespace containing:
                    ⍝ Command: HTTP Command ('get' or 'post')
                    ⍝ Headers: HTTP Headers as 2 column matrix or name/value pairs
                    ⍝ Page:    Requested page
                    ⍝ Arguments: Arguments to the command (cmd?arg1=value1&arg2=value2) as 2 column matrix of name/value pairs
   
    input←1⊃,req←2⊃##.HTTPUtils.DecodeHeader req
    'HTTPCmd'⎕NS'' ⍝ Make empty namespace
    HTTPCmd.Input←input
    HTTPCmd.Headers←{(0≠⊃∘⍴¨⍵[;1])⌿⍵}1 0↓req
    HTTPCmd.Command buf←' 'split input
    buf z←'http/'split buf
    HTTPCmd.Page args←'?'split buf
    HTTPCmd.Arguments←(args∨.≠' ')⌿↑'='∘split¨{1↓¨(⍵='&')⊂⍵}'&',args ⍝ Cut on '&'
  ∇

  ∇ r←DecodeHeader buf;len;d
                    ⍝ Decode HTML Header
   
    len←(¯1+⍴NL,NL)+⊃{((NL,NL)⍷⍵)/⍳⍴⍵}buf
    :If len>0
      d←(⍴NL)↓¨{(NL⍷⍵)⊂⍵}NL,len↑buf
      d←↑':'∘split¨d
      d[;1]←lc¨d[;1]
    :Else
      d←⍬
    :EndIf
    r←len d
  ∇

  ∇ code←Encode strg;raw;rows;cols;mat;alph
                    ⍝ Base64 Encode
    raw←⊃,/11∘⎕DR¨strg
    cols←6
    rows←⌈(⊃⍴raw)÷cols
    mat←rows cols⍴(rows×cols)↑raw
    alph←'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    alph,←'abcdefghijklmnopqrstuvwxyz'
    alph,←'0123456789+/'
    code←alph[⎕IO+2⊥⍉mat],(4|-rows)⍴'='
  ∇

  ∇ r←header GetValue(name type);i;h
                    ⍝ Extract value from HTTP Header structure returned by DecodeHeader
   
    :If (1↑⍴header)<i←header[;1]⍳⊂lc name
      r←⍬ ⍝ Not found
    :Else
      r←⊃header[i;2]
      :If 'Numeric'≡type
        r←1⊃2⊃⎕VFI r
      :EndIf
    :EndIf
  ∇

  ∇ r←port HostPort host;z
                    ⍝ Split host from port
   
    :If (⍴host)≥z←host⍳':'
      port←1⊃2⊃⎕VFI z↓host ⋄ host←(z-1)↑host  ⍝ Use :port if found in host name
    :EndIf
   
    r←host port
  ∇

  ∇ HTTPResponse←ParseHTTPResponse(body header);status;rest;tmp;version;reason;code;headers;body
                    ⍝ Parses an HTTP response
                    ⍝ resp is a character vector HTTP response
    status←(⊂1 1)⊃header
    version tmp←' 'split status
    code reason←' 'split tmp
    headers←1↓header
    'HTTPResponse'⎕NS''
    HTTPResponse.HTTPVersion←version
    HTTPResponse.StatusCode←⊃(//)⎕VFI code
    HTTPResponse.Reason←reason
    HTTPResponse.Headers←headers
    HTTPResponse.MessageBody←body
  ∇

  ∇ r←{options}Table data;NL
                    ⍝ Format an HTML Table
   
    NL←⎕AV[4 3]
    :If 0=⎕NC'options' ⋄ options←'' ⋄ :EndIf
   
    r←,∘⍕¨data                     ⍝ make strings
    r←,/(⊂'<td>'),¨r,¨⊂'</td>'     ⍝ enclose cells to make rows
    r←⊃,/(⊂'<tr>'),¨r,¨⊂'</tr>',NL ⍝ enclose table rows
    r←'<table ',options,'>',r,'</table>'
  ∇

  ∇ r←lc x;t
    t←⎕AV ⋄ t[⎕AV⍳⎕A]←'abcdefghijklmnopqrstuvwxyz'
    r←t[⎕AV⍳x]
  ∇

  split←{p←(⍺⍷⍵)⍳1 ⋄ ((p-1)↑⍵)((p+(⍴,⍺)-⎕IO)↓⍵)}

  spliton←{⎕ML←0 ⋄ b←m←⍵⍷⍺ ⋄ b[⎕IO]←1 ⋄ ((b/m)×⍴,⍵)↓¨b⊂⍺}

:EndNamespace