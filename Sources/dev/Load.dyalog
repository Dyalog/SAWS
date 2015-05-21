 Load;path

 ⎕←⎕SE.SALT.Load'⍵\Sources\SAWS -target=#'
 ⎕←⎕SE.SALT.Load'⍵\Sources\HTTPUtils -target=#.SAWS'
 ⎕←⎕SE.SALT.Load'⍵\Sources\SOAP -target=#.SAWS'
 ⎕←⎕SE.SALT.Load'⍵\Sources\WebServer -target=#.SAWS'
 ⎕←⎕SE.SALT.Load'⍵\Sources\Files -target=#'
 ⎕←⎕SE.SALT.Load'⍵\Sources\BuildCertDir -target=#'
 ⎕←⎕SE.SALT.Load'⍵\Sources\WebServices -target=#'
 ⎕←'WebServiceSamples' ⎕NS ''
 ⎕←⎕SE.SALT.Load'⍵\Sources\WebServiceSamples\* -target=#.WebServiceSamples'
 path←(1-⌊/(⌽⎕WSID)⍳'\/')↓⎕WSID
 ⎕LX←''
 ⎕←'      )WSID "',⎕WSID←path,'SAWS"'