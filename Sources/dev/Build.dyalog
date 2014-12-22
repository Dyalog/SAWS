 Build;path
⍝ Build distribution workspace containing unsalted classes and namespaces

 (⎕IO ⎕ML)←1 1
 ⎕EX ⎕NL 9
 path←(1-⌊/(⌽⎕WSID)⍳'\/')↓⎕WSID

 ⎕←⎕SE.SALT.Load'⍵\Sources\SAWS -target=# -source=no -nolink'
 ⎕←⎕SE.SALT.Load'⍵\Sources\HTTPUtils -target=#.SAWS -source=no -nolink'
 ⎕←⎕SE.SALT.Load'⍵\Sources\SOAP -target=#.SAWS -source=no -nolink'
 ⎕←⎕SE.SALT.Load'⍵\Sources\WebServer -target=#.SAWS -source=no -nolink'
 ⎕←⎕SE.SALT.Load'⍵\Sources\Files -target=# -source=no -nolink'
 ⎕←⎕SE.SALT.Load'⍵\Sources\BuildCertDir -target=# -source=no -nolink'
 ⎕←⎕SE.SALT.Load'⍵\Sources\Samples -target=#.SAWS -source=no -nolink'
 ⎕←⎕SE.SALT.Load'⍵\Sources\Samples\MyWebService -target=# -source=no -nolink'

 ⎕←'SAWS.Version set to:'
 ⎕←SAWS.Version←'Version built at ',,'ZI4,<->,ZI2,<->,ZI2,< >,ZI2,<:>,ZI2,<:>,ZI2'⎕FMT 1 6⍴⎕TS

 ⎕LX←''
 ⎕←'⍝ Now:'
 ⎕←'      )WSID "',⎕WSID←path,'Distribution\SAWS.dws"'
 ⎕←'      )erase Build Clear Dev Load'
 ⎕←'      )SAVE'