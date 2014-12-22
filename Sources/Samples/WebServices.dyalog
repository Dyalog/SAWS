:Namespace WebServices
⍝ === VARIABLES ===

NL←(⎕ucs 13 10)


⍝ === End of variables definition ===

(⎕IO ⎕ML ⎕WX)←1 0 3

∇ lu←LU
 lu←'abcdefghijklmnopqrstuvwxyzàáâãåèéêëòóôõöøùúûäæü' 'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÅÈÉÊËÒÓÔÕÖØÙÚÛÄÆÜ'
∇

 beginsWith←{0∊l←⍴w←,⍵:1
   (l↑⍺)≡noCase w}

∇ r←extractXML(data method result);emsg;xml;rc;xmlmat
                     ⍝ extracts XML result from the output message for a method
 rc←1 ⋄ xmlmat←0 5⍴⊂⍬ ⋄ emsg←''
 :If 0≠⊃data
   emsg←'Invalid request'
 :ElseIf method≢2 1⊃data
   emsg←'Method not found'
 :ElseIf 0∊⍴xml←(2 2⊃data)getelement result
   emsg←'Result not found'
 :Else
   :Trap 0
     xmlmat←⎕XML xml
     rc←0 ⍝ success!
   :Else
     emsg←'Error pasring XML'
   :EndTrap
 :EndIf
 r←rc xmlmat emsg
∇

 getelement←{(⍺[;2]⍳⊂⍵)⊃⍺[;3],⊂''}

∇ r←xml gettag arg;⎕ML;element;kids;attrs;gotattrs;mask;kidmask
                     ⍝ returns tag(s) matching arg
                     ⍝ arg[1] - tag name to match
                     ⍝ arg[2] - Boolean indicating whether to include child tags (default - 0)
                     ⍝ arg[3] - attribute name/value pairs to match (default - none)
                     ⍝ xml - 4 or 5 column ⎕XML matrix
                     ⍝ r - vector of matching tags
 ⎕ML←1
 r←⍬
 :If 1=≡arg ⋄ arg←,⊂arg ⋄ :EndIf ⍝ only tag name supplied?
 element kids attrs←3↑arg,(⍴arg)↓'' 0 ''
 :If gotattrs←~0∊⍴attrs ⍝ if attrs is not empty
   :If (2=≡attrs)∧(1=⍴⍴attrs)∧0=2|¯1↑⍴attrs ⋄ attrs←((0.5××/⍴attrs),2)⍴attrs ⍝ attrs is a vector of name/value pairs
   :ElseIf 3=≡attrs ⋄ attrs←↑attrs ⍝ attrs is a vector of nested name/value pairs (('name1' 'value1')('name2' 'value2'))
   :EndIf
 :EndIf
 :If ∨/mask←xml[;2]≡¨⊂element ⍝ find matching tag names
   :If gotattrs ⋄ mask←mask\(⊂attrs){∧/∨⌿(4⊃⍵)∧.≡⍉⍺}¨↓mask⌿xml ⋄ :EndIf  ⍝ if attributes, match all supplied
   :If kids ⋄ mask←(mask/⍳⍴mask){(-⍴⍵)↑1,∧\(⍺⊃⍵)<⍺↓⍵}¨⊂xml[;1]
     r←mask⌿¨⊂xml
   :Else ⋄ r←1⊂[1]mask⌿xml
   :EndIf
 :EndIf
∇

∇ s←lCase s;b;⎕IO;i;n;l;u
 n←⍴↑l u←LU
 →(∨/b←n>i←u⍳s)↓⎕IO←0
 (b/s)←l[b/i]
∇

∇ r←removetags xml
 r←''
 :Trap 0
   r←¯2↓⊃,/(3⌷[2]⎕XML xml),¨⊂NL
 :Else
 :EndTrap
∇

 tonum←{⎕ML←1 ⋄ t←⍵ ⋄ z←(('-'=t)/t)←'¯' ⋄ ⊃(//)⎕VFI t}

∇ s←uCase s;b;⎕IO;i;n;l;u
 n←⍴↑l u←LU
 →(∨/b←n>i←l⍳s)↓⎕IO←0
 (b/s)←u[b/i]
∇

 noCase←{(lCase ⍺)⍺⍺ lCase ⍵}


:Namespace APLData
(⎕IO ⎕ML ⎕WX)←1 0 3

∇ r←BuildAPI
     
∇

:EndNamespace 
:Namespace PriceCheck
⍝ === VARIABLES ===

DataBase←4 3⍴'Apple' 15 6.99 'Ball' 3 14.99 'Cactus' 0 9.99 'Daisy' 19 2.49


⍝ === End of variables definition ===

(⎕IO ⎕ML ⎕WX)←1 0 3

∇ api←BuildAPI;method;arg;result;⎕ML
                     ⍝ Construct the API for the PriceCheck Web Service
                     ⍝ api - vector of method definitions, one element per method in the Web Service
                     ⍝       [1] method description
                     ⍝       [2] argument(s) description
                     ⍝       [3] result(s) description
                     ⍝
                     ⍝ This Web Service has 2 methods, ListItems and GetItemInfo
                     ⍝ ListItems has no arguments and returns a list of the items in the database
                     ⍝ GetItemInfo takes the name of an item and returns information about the item
 ⎕ML←1
 api←0⍴⊂''
                    ⍝ ListItems method definition
 method←1 4⍴1 'ListItems' ''(1 2⍴'documentation' 'List the items available via this service.')
 result←arg←0 4⍴0 ⍝ initialize the ListItems method's argument and result descriptions
 arg⍪←1 'BeginsWith' ''(↑('minimum' 1)('maximum' 1)('datatype' 'string')) ⍝ Argument is string to search
 result⍪←1 'ItemList' ''(↑('minimum' 1)('maximum' 1)) ⍝ there is exactly 1 ItemList result...
 result⍪←2 'ItemName' ''(↑('datatype' 'string')('minimum' 0)) ⍝ ...which contains 0 or more ItemNames
 api,←⊂method arg result ⍝ append the ListItems method definition
                    ⍝ GetItemInfo method definition
 method←1 4⍴1 'GetItemInfo' ''(1 2⍴'documentation' 'Get information about an item')
 result←arg←0 4⍴0 ⍝ initialize the GetItemInfo method's argument and result descriptions
 arg⍪←1 'ItemName' ''(↑('datatype' 'string')('minimum' 1)('maximum' 1)) ⍝ the argument is an ItemName
 result⍪←1 'ItemInfo' ''(↑('minimum' 1)('maximum' 1)) ⍝ the result an ItemInfo which contains...
 result⍪←2 'ItemName' ''(↑('datatype' 'string')('minimum' 1)('maximum' 1)) ⍝ 1 ItemName
 result⍪←2 'ItemQty' ''(↑('datatype' 'integer')('minimum' 1)('maximum' 1)) ⍝ 1 ItemQty
 result⍪←2 'ItemPrice' ''(↑('datatype' 'double')('minimum' 1)('maximum' 1)) ⍝ and 1 ItemPrice
 api,←⊂method arg result ⍝ append the GetItemInfo method definition
                    ⍝ OrderItem method definition
 method←1 4⍴1 'OrderItem' ''(1 2⍴'documentation' 'Orders an item')
 result←arg←0 4⍴0 ⍝ initialize the GetItemInfo method's argument and result descriptions
 arg⍪←1 'ItemName' ''(↑('datatype' 'string')('minimum' 1)('maximum' 1)) ⍝ 1st argument is an ItemName
 arg⍪←1 'Qty' ''(↑('datatype' 'integer')('minimum' 1)('maximum' 1)) ⍝ 2nd argument is quantity to order
 result⍪←1 'OrderInfo' ''(↑('minimum' 1)('maximum' 1)) ⍝ the result an ItemInfo which contains...
 result⍪←2 'ItemName' ''(↑('datatype' 'string')('minimum' 1)('maximum' 1))
 result⍪←2 'OrderQty' ''(↑('datatype' 'integer')('minimum' 0)('maximum' 1))
 result⍪←2 'OrderStatus' ''(↑('datatype' 'string')('minimum' 1)('maximum' 1))
 result⍪←2 'Message' ''(↑('datatype' 'string')('minimum' 0)('maximum' 1))
 result⍪←2 'OrderTotal' ''(↑('datatype' 'double')('minimum' 0)('maximum' 1))
 api,←⊂method arg result ⍝ append the GetItemInfo method definition
∇

∇ r←GetItemInfo arg;ind;name;qty;price;resp;noatt;result
                    ⍝ Implements the GetItemInfo method for the PriceCheck web service
                     ⍝ arg - 1 row Markup Language Structure (MLS)
                     ⍝      [;1] level (1)
                     ⍝      [;2] 'ItemName'
                     ⍝      [;3] character vector containing the name of the item to retrieve
                     ⍝      [;4] ⊂0 2⍴''  indicating there are no attributes
                     ⍝ r[1] - 1 (indicates r[2] is an MLS)
                     ⍝ r[2] - MLS containing the result
                     ⍝      [;1] - depth of nesting (origin 1)
                     ⍝      [;2] - element name
                     ⍝      [;3] - element value
                     ⍝      [;4] - 2 column attribute name/value pairs
                     ⍝ The result represents a 2 level nested structure of
                     ⍝  ItemInfo which contains information for the item equivalent to the XML:
                     ⍝ <ItemInfo>{Not }Found
                     ⍝   <ItemName>name</ItemName>
                     ⍝   <ItemQty>quantity</ItemName>
                     ⍝   <ItemPrice>price</ItemPrice>
                     ⍝ </ItemInfo>
 name←(arg[;2]⍳⊂'ItemName')⊃arg[;3],⊂'' ⍝ get the ItemName element
 ind←DataBase[;1]⍳⊂name ⍝ look the name up
 resp←'ItemName' 'ItemQty' 'ItemPrice',[1.5](DataBase⍪name ⍬ ⍬)[ind;] ⍝ look up item information
 noatt←0 2⍴⊂'' ⍝ no attributes
 result←1 4⍴1 'ItemInfo'('Not Found'↓⍨4×ind≤⍬⍴⍴DataBase)noatt ⍝ ItemInfo level
 result⍪←2,resp,⊂noatt ⍝ item details
 r←1 result
∇

∇ r←ListItems arg;result;noatt;mask;search
                     ⍝ Implements the ListItems method for the PriceCheck web service
                     ⍝ arg - 1 row MLS with string to filter items with
                     ⍝ r[1] - 1 (indicates r[2] is an MLS)
                     ⍝ r[2] - MLS containing the  result
                     ⍝      [;1] - depth of nesting (origin 1)
                     ⍝      [;2] - element name
                     ⍝      [;3] - element value
                     ⍝      [;4] - 2 column attribute name/value pairs
                     ⍝ The result represents a 2 level nested structure of
                     ⍝  ItemList which contains 0 or more ItemNames
                     ⍝   equivalent to the XML:
                     ⍝ <ItemList>
                     ⍝   <ItemName>First Item Name</ItemName>
                     ⍝   <ItemName>Second Item Name</ItemName>
                     ⍝   ...
                     ⍝ </ItemList>
 noatt←0 2⍴⊂'' ⍝ no attributes
 result←1 4⍴1 'ItemList' ''noatt ⍝ build the ItemList Level
 search←arg #.WebServices.getelement'BeginsWith'
 mask←DataBase[;1]#.WebServices.beginsWith¨⊂search
 result⍪←2,(⊂'ItemName'),(mask⌿DataBase[;,1]),⊂noatt ⍝ Add the ItemNames from the database
 r←1 result
∇

∇ r←OrderItem arg;ind;name;qty;price;resp;result;onhand
                    ⍝ Implements the OrderItem method for the PriceCheck web service
 result←0 3⍴0
 name←arg #.WebServices.getelement'ItemName' ⍝ get the ItemName element
 result⍪←1 'OrderInfo' ''
 result⍪←2 'ItemName'name
 ind←DataBase[;1]⍳⊂name ⍝ look the name up
 :If ind≤''⍴⍴DataBase ⍝ item found?
   :If ''≢qty←arg #.WebServices.getelement'Qty'
     qty←#.WebServices.tonum qty
     result⍪←2 'OrderQty'qty
     :If qty≤onhand←DataBase[ind;2]
       result⍪←2 'OrderStatus' 'Complete'
       result⍪←2 'OrderTotal'(qty×(ind,3)⌷DataBase)
     :Else
       result⍪←2 'OrderStatus' 'Not Processed'
       result⍪←2 'Message'(⍕'Only'onhand'available')
     :EndIf
   :Else
     result⍪←2 'OrderStatus' 'Not Processed'
     result⍪←2 'Message'('Order quantity not specified')
   :EndIf
 :Else ⍝ item not found
   result⍪←2 'OrderStatus' 'Not Processed'
   result⍪←2 'Message'('Item not found')
 :EndIf
 result,←⊂0 2⍴⊂''⍝ no attributes for any elements
 r←1 result
∇

:EndNamespace 
:Namespace Weather
(⎕IO ⎕ML ⎕WX)←1 0 3

∇ api←BuildAPI;method;arg;result;⎕ML
                     ⍝ API for the Weather Web Service
 ⎕ML←1
 api←0⍴⊂''
                    ⍝ What Should I Wear method
 method←1 4⍴1 'WhatShouldIWear' ''(2 2⍴'pattern' 2 'documentation' 'Recommends what to wear based on today''s maximum temperature')
 result←arg←0 4⍴0
 arg⍪←1 'ZipCode' ''(↑('datatype' 'string')('minimum' 1)('maximum' 1)) ⍝ takes 1 argument of a ZipCode
 result⍪←1 'WeatherInfo' ''(1 2⍴'minimum' 0) ⍝ returns a WeatherInfo structure which contains
 result⍪←2 'Status' ''(↑('datatype' 'string')('minimum' 1)('maximum' 1)) ⍝ a Status string
 result⍪←2 'ZipCode' ''(↑('datatype' 'string')('minimum' 0)('maximum' 1)) ⍝ the ZipCode string
 result⍪←2 'MaxTemp' ''(↑('datatype' 'double')('minimum' 0)('maximum' 1)) ⍝ the MaxTemp - maximum temperature
 result⍪←2 'WhatToWear' ''(↑('datatype' 'string')('minimum' 0)('maximum' 1)) ⍝ and a string describing what to wear
 api,←⊂method arg result
∇

∇ r←ClothingChoice temp
                    ⍝ returns clothing choice based on temperature
 r←(⎕IO+temp+.≥0 20 40 60 75 85)⊃(⊂'Don''t go outside'),(⊂'Wear a '),¨'Parka' 'Heavy coat' 'Light coat' 'Sweater' 'Tee-shirt' 'Swimsuit'
∇

∇ (rc xml emsg)←GetForecast latlong;svcURL;svcPort;svcPage;svcName;svcFn;lat;long;today;params;result
     ⍝ latlong - [1]latitude [2]longitude   (43.04 ¯77.69 is West Henrietta, NY)
     ⍝ rc - 0 if no error, non-0 otherwise
     ⍝ xml - ⎕XML'ed forecast data
     ⍝ emsg - error message if any errors
     
     ⍝ set up service parameters
 svcURL←'graphical.weather.gov'
 svcPort←80
 svcPage←'/xml/SOAP_server/ndfdXMLserver.php'
 svcName←'ndfdXML'
 svcFn←'NDFDgenByDay'
     
     ⍝ construct parameters for the call see http://graphical.weather.gov/xml/  for more information
 lat long←{{('-',⍵)[('¯',⍵)⍳⍵]}⍕⍵}¨latlong ⍝ format latlong (use - instead of ¯)
 today←,'I4,<->,ZI2,<->,ZI2'⎕FMT 1 3⍴⎕TS
 params←'latitude'lat'longitude'long'startDate'today'numDays' '1' 'Unit' 'e' 'format' '24 hourly'
     
 result←svcURL svcPort svcPage #.SAWS.Call svcName svcFn params ⍝ get forecast information
     
 (rc xml emsg)←##.extractXML result'NDFDgenByDay' 'dwmlByDayOut' ⍝ grab the xml from the result
∇

∇ result←WhatShouldIWear arg;zip;emsg;xml;latlon;lat;lon;forecast;rc;resp;data;max;maxtemp;what;noatt
 zip←arg ##.getelement'ZipCode' ⍝ grab the zip code
 resp←'graphical.weather.gov' 80 '/xml/SOAP_server/ndfdXMLserver.php'#.SAWS.Call'ndfdXML' 'LatLonListZipCode'('zipCodeList'zip) ⍝ look up the lat/long for the zip code
 emsg←'' ⍝ initialize the error message
 noatt←0 2⍴⊂''
 result←1 4⍴1 'WeatherInfo' ''noatt ⍝ initialize result
 :If 0=⊃(rc xml emsg)←##.extractXML resp'LatLonListZipCode' 'listLatLonOut' ⍝ grab the xml with the lat/long elements
   :If 0∊⍴latlon←xml ##.getelement'latLonList' ⍝ grab the lat/long
     emsg←'Could not retrieve lat/lon'
   :Else
     lat lon←{1↓¨(⍵=⊃⍵)⊂⍵}',',latlon ⍝ split the lat and long
     data←'graphical.weather.gov' 80 '/xml/SOAP_server/ndfdXMLserver.php'#.SAWS.Call'ndfdXML' 'NDFDgenByDay'('latitude'lat'longitude'lon'startDate'(,'I4,<->,ZI2,<->,ZI2'⎕FMT⍉⍪3↑⎕TS)'numDays' '1' 'Unit' 'e' 'formatType' '24 hourly') ⍝ get forecast information
     :If 0=⊃(rc xml emsg)←##.extractXML data'NDFDgenByDay' 'dwmlByDayOut' ⍝ grab the xml from the forecast
       max←⊃xml ##.gettag'temperature' 1('type' 'maximum') ⍝ find the max temperature element
       maxtemp←##.tonum max ##.getelement'value' ⍝ get its value
       what←ClothingChoice maxtemp ⍝ determine what to wear based on temp
     :EndIf
   :EndIf
 :Else
   :Trap 0
     :If 'SERVER'≡2 1⊃resp
       emsg←##.removetags 2 4⊃resp
     :EndIf
   :Else
   :EndTrap
 :EndIf
 :If 0∊⍴emsg ⍝ if successful
   result⍪←2,(('Status' 'ZipCode' 'MaxTemp' 'WhatToWear'),[1.1]'Success'zip maxtemp what),⊂noatt ⍝ build the result structure
 :Else
   result⍪←2,(1 2⍴'Status'emsg),⊂noatt ⍝ otherwise return an the status/error message
 :EndIf
 result←1 result
∇

:EndNamespace 
:EndNamespace 