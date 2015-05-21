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
                     ⍝ This Web Service has 3 methods, ListItems, GetItemInfo, and OrderItem
                     ⍝ ListItems has no arguments and returns a list of the items in the database
                     ⍝ GetItemInfo takes the name of an item and returns information about the item
                     ⍝ OrderItem takes an item name and a quantity and tries to process an order
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