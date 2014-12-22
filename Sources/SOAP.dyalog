:Namespace SOAP
(⎕IO ⎕ML ⎕WX)←1 3 3

∇ R←pvm API2WSDL api;A;B;D;epvm;I;J;K;max;method;min;mpvm;name;request;response;rmls;rpvm;serviceURL;type;typesURL;wsdlURL;props;doc;mname;pattern;d
                           ⍝ Transform an "API" into a WSDL-MLS
                           ⍝ -----------------------------------------------------------------------------------
                           ⍝ SYNTAX:   R←API2WSDL api
                           ⍝
                           ⍝ DESCRIPTION:
                           ⍝  This is just a simple WSDL generator, given a simple API.
                           ⍝  It is NOT intended to accommodate some very general case of data descriptions
                           ⍝  involving domains, constraints, shapes, etc.
                           ⍝  It is involved only with basic structure (what you will see as described by
                           ⍝  columns 1 and 2 in the MLS) and also with datatypes.
                           ⍝
                           ⍝ ARGS/RESULT:
                           ⍝  api      - Application Programming Interface, described by a vector of method descriptions.
                           ⍝             EACH ELEMENT in this vector is 3 elements and each is defined as follows:
                           ⍝              [1] - method info. This is typically just the name of the method.
                           ⍝                    However, it may also be a 1-row MLS, e.g. 1 'MyMethod' '' PVM,
                           ⍝                    where the PVM element more fully specifies the method's nature.
                           ⍝                     ∘ 'pattern' - 1 - One-way  (input)
                           ⍝                                   2 - Request-response (input-output)
                           ⍝                                   3 - Solicit-response (output-input) - [NOT IMPLEMENTED YET]
                           ⍝                                   4 - Notification (output)
                           ⍝                        If the 'pattern' property is not specified, the nature of the method
                           ⍝                        will be determined based on elements 2 and 3 below as so:
                           ⍝                          [2]-non-empty, [3]-empty     ==> 'pattern' is assumed to 1
                           ⍝                          [2]-non-empty, [3]-non-empty ==> 'pattern' is assumed to 2
                           ⍝                          [2]-empty,     [3]-non-empty ==> 'pattern' is assumed to 4
                           ⍝                        To show that your method adheres to a 'pattern' of 3, the 'pattern'
                           ⍝                        has to be set to 3 in the PVM.
                           ⍝                     ∘ 'documentation' - charvec of associated documentation
                           ⍝              [2] - argument/request description, as an MLS
                           ⍝              [3] - result/response description, as an MLS
                           ⍝             Each MLS (those in elements 2 and 3 above) describes the allowable structure
                           ⍝             of the data (intended as the argument or result). It is a sort of model
                           ⍝             or prototype along with a few attributes to more fully describe it.
                           ⍝             So, the 1st and 2nd columns of the MLS look much like the real data would.
                           ⍝             The 3rd column, the content, is empty for now (perhaps it will be used
                           ⍝             later for something in the future, e.g. example data).
                           ⍝             The 4th column consists of PVMs where the following attributes are utilized:
                           ⍝              'datatype' - it can be one of the following: 'string' 'boolean' 'integer' 'double'
                           ⍝                           Default: '' ==> container element
                           ⍝                           It may also be a datatype defined by http://www.w3.org/TR/xmlschema-2/;
                           ⍝                           to specifically use one of those, use the "xsd:" prefix, e.g. 'xsd:dateTime'
                           ⍝                           Note: The datatypes listed above actually do correspond (same names exactly)
                           ⍝                                 with real xsd datatypes. However, it is intended that you are
                           ⍝                                 able to pass generic datatypes and these would get mapped
                           ⍝                                 to the appropriate ones should they ever vary from WSDL schema.
                           ⍝              'minimum'  - the minimum number of times that this element must occur, PER PARENT. Default: 0
                           ⍝              'maximum'  - the maximum number of times that this element must occur, PER PARENT. Default: ∆MV ==> unlimited
                           ⍝              'documentation' - charvec of associated documentation
                           ⍝              Note that minimum and maximum are not describing the minimum/maximum value
                           ⍝              of the content; they are describing the structure of the elements. They
                           ⍝              are commonly used for showing whether some element is single or multiple
                           ⍝              but they can be further utilized to describe requiredness or a maximum
                           ⍝              count of some element at some level.
                           ⍝              The following describes a single required element: ⊃('minimum' 1)('maximum' 1).
                           ⍝              The following describes an optional array of elements, of any length: 1 2⍴'minimum' 0
                           ⍝  pvm      - PVM containing the primary information about the Web Service
                           ⍝               name       - name of the Web Service
                           ⍝               serviceURL - URL/address of the Web Service. This is where the SOAP-XML
                           ⍝                            methods/requests are actually sent to.
                           ⍝               wsdlURL    - associated WSDL URL. This should be the URL of where to retrieve
                           ⍝                            the complete WSDL document, as XML (what this function is
                           ⍝                            generating the MLS for)
                           ⍝                            Default: <serviceURL>,'/wsdl'
                           ⍝  R        - an MLS that describes a formal WSDL, consisting of all of the methods.
                           ⍝             Running this through MLS2XML generates a WSDL document that is
                           ⍝             suitable for using in a Web Service.
                           ⍝
                           ⍝ EXAMPLE:
                           ⍝   api←0⍴⊂'' ⍝ initialize the right argument to API2WSDL
                           ⍝  ⍝ Describe the method for updating information on several people in one call.
                           ⍝   method←'UpdatePersons'
                           ⍝   arg←0 4⍴0
                           ⍝   arg←arg⍪1 'person'       '' (1 2⍴                     'minimum' 0)
                           ⍝   arg←arg⍪2   'lastname'   '' (⊃('datatype' 'string')  ('minimum' 1)('maximum' 1))
                           ⍝   arg←arg⍪2   'firstname'  '' (⊃('datatype' 'string')  ('minimum' 1)('maximum' 1))
                           ⍝   arg←arg⍪2   'dob'        '' (⊃('datatype' 'xsd:date')('minimum' 1)('maximum' 1))
                           ⍝   arg←arg⍪2   'phones'     '' (⊃                       ('minimum' 0)('maximum' 3))
                           ⍝   arg←arg⍪3     'phonenum' '' (⊃('datatype' 'string')  ('minimum' 1)('maximum' 1))
                           ⍝   arg←arg⍪3     'type'     '' (⊃('datatype' 'integer') ('minimum' 0)('maximum' 1))
                           ⍝   result←0 4⍴0
                           ⍝   result←result⍪1 'success' '' (⊃'datatype' 'boolean') ('minimum' 1)('maximum' 1))
                           ⍝   api←api,⊂method arg result
                           ⍝  ⍝ Describe the method for ...
                           ⍝   method←'...'
                           ⍝   arg←...
                           ⍝   result←...
                           ⍝   api←api,⊂method arg result
                           ⍝  ⍝ Describe the method for ...
                           ⍝   method←'...'
                           ⍝   arg←...
                           ⍝   result←...
                           ⍝   api←api,⊂method arg result
                           ⍝
                           ⍝   ... API2WSDL api ==>
                           ⍝
                           ⍝ SUBFNS:  ∆MV PVMGetVal PVMGetVals Parent
                           ⍝ -----------------------------------------------------------------------------------
 epvm←0 2⍴⊂''
     
 :If 0=⎕NC'pvm' ⋄ pvm←epvm ⋄ :EndIf
 serviceURL←'serviceURL' 'http://Unspecified/WebService/'PVMGetVal pvm
 serviceURL←serviceURL,('/'≠¯1↑serviceURL)/'/'
 props←''
 props←props,⊂'name' 'UnspecifiedWebService'
 props←props,⊂'wsdlURL'(serviceURL,'wsdl/')
 (name wsdlURL)←props PVMGetVals pvm
 :If '/'≠¯1↑wsdlURL ⋄ wsdlURL←wsdlURL,'/' ⋄ :EndIf
 typesURL←serviceURL,'schema/'
     
                           ⍝ For each method-part, get the method's name, pattern, documentation.
 :For I :In ⍳⍴api
   method←I 1⊃api
   :If B←1<≡method
     (mname mpvm)←method[1;2 4]
     (pattern doc)←'pattern'('documentation' '')PVMGetVals mpvm
   :Else
     mname←method
     doc←''
   :EndIf
   :If ~B ⋄ :OrIf pattern≡∆MV
     pattern←(1 2 4)[(1 0)(1 1)(0 1)⍳⊂×↑¨⍴¨(I⊃api)[2 3]]
   :EndIf
   ((I 1)⊃api)←mname pattern doc
 :EndFor
     
 pvm←epvm
 pvm←pvm⍪'name'name
 pvm←pvm⍪'targetNamespace'wsdlURL
 pvm←pvm⍪'xmlns:tns'wsdlURL
 pvm←pvm⍪'xmlns:mytypes'typesURL
 pvm←pvm⍪'xmlns' 'http://schemas.xmlsoap.org/wsdl/'
 pvm←pvm⍪'xmlns:xsd' 'http://www.w3.org/2001/XMLSchema'
 pvm←pvm⍪'xmlns:soap' 'http://schemas.xmlsoap.org/wsdl/soap/'
 pvm←pvm⍪'xmlns:soapenc' 'http://schemas.xmlsoap.org/soap/encoding/'
 pvm←pvm⍪'xmlns:http' 'http://schemas.xmlsoap.org/wsdl/http/'
 pvm←pvm⍪'xmlns:mime' 'http://schemas.xmlsoap.org/wsdl/mime/'
     
 R←1 4⍴1 'definitions' ''pvm
     
                           ⍝ Types:
 R←R⍪2 'types' ''epvm
 R←R⍪3 'xsd:schema' ''(2 2⍴'targetNamespace'typesURL'elementFormDefault' 'qualified')
 :For I :In ⍳⍴api
   (method request response)←I⊃api
   mname←1⊃method
   :For J :In ⍳2
     :If 0∊rmls←J⊃request response ⋄ :Continue ⋄ :EndIf
     :If J=2 ⋄ mname←mname,'Response' ⋄ :EndIf
     R←R⍪4 'xsd:element' ''(1 2⍴'name'mname)
     R←R⍪5 'xsd:complexType' ''epvm
     R←R⍪6 'xsd:sequence' ''epvm
     
     rmls←0 '' ''epvm⍪rmls ⍝ (just so we can have a parent for the top-level nodes too because, in the general case, we have to look to the parent to see what depth we should start at)
     D←(↑⍴rmls)⍴7 ⍝ starting depths
     :For K :In 1↓⍳↑⍴rmls
       d←D[K Parent rmls[;1]]
       (type min max doc)←('datatype' '')('minimum' 0)('maximum' 'unbounded')('documentation' '')PVMGetVals((⊂K 4)⊃rmls)
       rpvm←⊃('name'((⊂K 2)⊃rmls))('minOccurs'min)('maxOccurs'max)
                                ⍝:IF min=0 ⋄ rpvm←rpvm⍪'nillable' 'true' ⋄ :ENDIF ⍝ *** - ???
       :If 0<⍴doc ⋄ doc←1 4⍴(d+1)'documentation'doc epvm ⋄ :Else ⋄ doc←0 4⍴0 ⋄ :EndIf
     
       :If 0≠⍴type
         :If ~':'∊type
                                        ⍝type←('string' 'boolean' 'integer' 'double'⍳⊂type)⊃'string' 'boolean' 'integer' 'double' ⍝ don't have to run this since the mapping is a noop
           type←'xsd:',type
         :EndIf
         rpvm←rpvm⍪'type'type
         R←R⍪(d'xsd:element' ''rpvm)⍪doc
       :Else
         R←R⍪(d'xsd:element' ''rpvm)⍪doc
         R←R⍪⊃((d+1)'xsd:complexType' ''epvm)((d+2)'xsd:sequence' ''epvm)
         D[K]←d+3
       :EndIf
     :EndFor
   :EndFor
 :EndFor
     
                    ⍝ Messages:
 :For I :In ⍳⍴api
   (mname pattern)←2↑I 1⊃api
   :If pattern<4
     R←R⍪2 'message' ''(1 2⍴'name'(mname,'MessageIn'))
     R←R⍪3 'part' ''(2 2⍴'name' 'parameters' 'element'('mytypes:',mname)) ⍝ (we'll use 'parameters' as the name simply because that's what .NET uses)
   :EndIf
   :If pattern>1
     R←R⍪2 'message' ''(1 2⍴'name'(mname,'MessageOut'))
     R←R⍪3 'part' ''(2 2⍴'name' 'parameters' 'element'('mytypes:',mname,'Response'))
   :EndIf
 :EndFor
     
                    ⍝ Operations:
 R←R⍪2 'portType' ''(1 2⍴'name'(name,'_PortType'))
 :For I :In ⍳⍴api
   (mname pattern doc)←I 1⊃api
   R←R⍪3 'operation' ''(1 2⍴'name'mname)
   :If 0<⍴doc
     R←R⍪4 'documentation'doc epvm
   :EndIf
   :If pattern<4
     R←R⍪4 'input' ''(1 2⍴'message'('tns:',mname,'MessageIn'))
   :EndIf
   :If pattern>1
     R←R⍪4 'output' ''(1 2⍴'message'('tns:',mname,'MessageOut'))
   :EndIf
 :EndFor
     
                    ⍝ Bindings:
 R←R⍪2 'binding' ''(2 2⍴'name'(name,'_Binding')'type'('tns:',name,'_PortType'))
 R←R⍪3 'soap:binding' ''(2 2⍴'style' 'document' 'transport' 'http://schemas.xmlsoap.org/soap/http')
                    ⍝A←5 'soap:body' '' (3 2⍴'use' 'literal' 'encodingStyle' 'http://schemas.xmlsoap.org/soap/encoding/' 'namespace' ('urn:',name))
 A←5 'soap:body' ''(1 2⍴'use' 'literal') ⍝ for the "wrapped" convention, you are NOT supposed to include or 'encodingStyle' or 'namespace'
 :For I :In ⍳⍴api
   (mname pattern)←2↑I 1⊃api
   R←R⍪3 'operation' ''(1 2⍴'name'mname)
   R←R⍪4 'soap:operation' ''(1 2⍴'soapAction'mname)
   :If pattern<4
     R←R⍪4 'input' ''epvm
     R←R⍪A
   :EndIf
   :If pattern>1
     R←R⍪4 'output' ''epvm
     R←R⍪A
   :EndIf
 :EndFor
     
                    ⍝ Service:
 R←R⍪2 'service' ''(1 2⍴'name'name)
 R←R⍪3 'port' ''(2 2⍴'name'(name,'_Port')'binding'('tns:',name,'_Binding'))
 R←R⍪4 'soap:address' ''(1 2⍴'location'serviceURL)
∇

∇ R←APL2SOAP rarg;tree;I;stypes;B;⍙mv;applyB;nullB;atomsB;inds;tags;inherit
                    ⍝ Transform some arbitrary APL data into a SOAP-MLS
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←APL2SOAP rarg
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  rarg     - any APL data
                    ⍝  R        - SOAP-MLS
                    ⍝
                    ⍝ SUBFNS:   ∆MV WHERE ⍙APL2SOAP_Recurse ConcatMats
                    ⍝ -----------------------------------------------------------------------------------
     
 ⍙mv←∆MV ⍝ initialize for globals use
 tree←1 ⍙APL2SOAP_Recurse rarg ⍝ normalize the data, via recursion, to make it easy to transform hereafter
 atomsB←0≠tree[;4] ⍝ atoms (have data; they're not just containers)
 applyB←0<tree[;5] ⍝ need a datatype applied to them (not represented by their respective parent's datatype)
 nullB←¯1=tree[;5] ⍝ need special xsi:null="1" applied to them
 inherit←(applyB/⍳↑⍴tree)[+\applyB]
     
                    ⍝ Initialize the result.
 R←((↑⍴tree),4)⍴'a' ⋄ R[;1 3]←tree[;1 2] ⋄ R[;4]←⊂0 2⍴⊂''
     
                    ⍝ Map to the SOAP datatypes (be sure to use 'double', not 'float', since APL "float" is 64-bit, not 32-bit).
 stypes←(4⍴⊂'xsd:string'),(3⍴⊂'xsd:int'),'xsd:double' 'xsd:boolean' 'xsd:ur-type' 'SOAP-ENC:Array' '' ⍝ (the '' at the end is for tree[;5] being 0)
 stypes←stypes[inds←82 80 160 320 83 163 323 645 11 807 326⍳tree[;5]] ⍝ important: these now are either the datatype of self or, if a container, the datatype of the children
 tags←(4 3 1 1 1 1 1/'string' 'integer' 'double' 'boolean' 'ur-type' 'array' '')[inds[inherit]]
     
                    ⍝ Plug in the appropriate PVM for atoms of basic datatypes.
 I←WHERE applyB∧atomsB
 R[I;4]←(⊂1 2)⍴¨⊂[2](⊂'xsi:type'),[1.5]stypes[I]
 I←WHERE atomsB
 R[I;2]←tags[I]
     
                    ⍝ The containers have 2 attribute values:  xsi:type="SOAP-ENC:Array" SOAP-ENC:arrayType="xsd:DATATYPE[n,m...]"
 I←WHERE applyB>atomsB
 R[I;2]←⊂'array' ⍝ (this is just a convention, as is the child 'a' initialized in <R> up above)
 R[I;4]←(⊂1 2⍴'xsi:type' 'SOAP-ENC:Array')⍪¨⊂[2](⊂'SOAP-ENC:arrayType'),[1.5]stypes[I],¨'[',¨(1↓¨∊¨',',¨¨⍕¨¨tree[I;3]),¨']'
     
                    ⍝ Plug in special attribute showing NULL (more rare so check for 1∊ up front)
 :If 1∊nullB
                        ⍝ Yes, this use of setting xsi:null="1" appears to be inconsistent.  Why not
                        ⍝ have 'xsd:null' up above with the other datatypes and then we wouldn't need to
                        ⍝ special case anything here? Regardless of that, it appears that we still do
                        ⍝ need xsd:null so that we can describe an array of nulls, e.g. 'xsi:null[2,3]'.
   I←WHERE nullB∧atomsB
   R[I;4]←⊂1 2⍴'xsi:null' 1
     
   I←WHERE nullB>atomsB
   R[I;4]←(⊂1 2⍴'xsi:type' 'SOAP-ENC:Array')⍪¨⊂[2](⊂'SOAP-ENC:arrayType'),[1.5](⊂'xsd:null'),¨'[',¨(1↓¨∊¨',',¨¨⍕¨¨tree[I;3]),¨']'
 :EndIf
     
                    ⍝ ===================================================================================
                    ⍝ We have to special case some types of APLish data.
                    ⍝ SOAP considers character vectors to be at the atomic level. No shape needs to be
                    ⍝ described for them. So, neither an APL character scalar nor a multi-dimensional
                    ⍝ character array has a real analog in SOAP since you cannot describe its shape unless
                    ⍝ you umbrella it with an 'array' tag which implies it is nested.
                    ⍝ Essentially, we just can't have the SOAP 'array' element serve double-duty
                    ⍝ (it can't serve the purpose of nestedness and an array-shape descriptor).
                    ⍝ We'll have to add our own special property in order to overcome this.
                    ⍝ This way, we will at least always ensure that the following is true for any data:
                    ⍝  data≡SOAP2APL APL2SOAP data
 :If 1∊B←¯1=tree[;4]
   I←WHERE B
   R[I;3]←,¨R[I;3]
   R[I;4]←R[I;4]⍪¨⊂[2](⊂'APL-ENC:shape'),[1.5]⍕¨tree[I;3]
 :EndIf
∇

∇ R←I Ancestors dv
                    ⍝ Return the indices of the ancestors for some specified index
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←I Ancestors dv
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  dv       - depth vector
                    ⍝  I        - index to find the ancestors of
                    ⍝  R        - indices of the ancestors, in ascending order
                    ⍝ -----------------------------------------------------------------------------------
 dv←dv+1-⌊/dv ⍝ normalize
 R←I-(⌽(I-1)↑dv)⍳⍳dv[I]-1
∇

∇ R←depth BeginDepth R
                    ⍝ Simple cover - begin the depth of an MLS with the value specified
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←depth BeginDepth mls
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  mls      - Markup Language Structure or any matrix where the first column is
                    ⍝             a depth vector
                    ⍝  depth    - integer depth to begin at
                    ⍝  R        - adjusted MLS
                    ⍝
                    ⍝ EXAMPLE:
                    ⍝  mls←0 4⍴''
                    ⍝  mls←mls⍪3 'this'  ...
                    ⍝  mls←mls⍪4 'that'  ...
                    ⍝  mls←mls⍪5 'other' ...
                    ⍝  mls←mls⍪4 'stuff' ...
                    ⍝  mls←mls⍪4 'more'  ...
                    ⍝  2 BeginDepth mls ==> 2 'this'  ...
                    ⍝                       3 'that'  ...
                    ⍝                       4 'other' ...
                    ⍝                       3 'stuff' ...
                    ⍝                       3 'more'  ...
                    ⍝ -----------------------------------------------------------------------------------
 R[;⎕IO]←R[;⎕IO]-(↑R)-depth
∇

 BeginsWith←{⍵≡(⍴⍵)↑⍺}

 Children←{dv←⍵+1-⌊/⍵ ⋄ res←¯1+(dv[⍺]<D←⍺↓dv)⍳0 ⋄ ⍺+((res↑D)=dv[⍺]+1)/⍳res}

∇ R←ConcatMats rarg;I;numrows;rows;C;cols;B
                    ⍝ Cover for ↑⍪/rarg where each element in rarg is non-empty. This function is faster for sufficiently large data.
                    ⍝ -----------------------------------------------------------------------------------
 rows←↑∘⍴¨rarg ⍝ recognized idiom
 numrows←+/rows
 R←(numrows,¯1↑⍴↑rarg)⍴↑,/,¨rarg ⍝ ,/PV is a recognized idiom
∇

∇ R←larg Data2SOAP R;isMLS;encoding
                    ⍝ Transform an MLS or arbitrary APL data into a SOAP-MLS
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←isMLS {encoding} Data2SOAP data
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  data     - APL data to be prepared
                    ⍝  isMLS    - whether the outer structure of <data> is intended as an MLS as opposed
                    ⍝             to just some arbitrary APL data. Note that, if an MLS, the content of
                    ⍝             any given row may itself still be arbitrary APL data. If an MLS were a
                    ⍝             real APL datatype, you wouldn't need to pass <isMLS>. When going from
                    ⍝             SOAP to APL, it can be determined if it is destined as an MLS or as
                    ⍝             arbitrary APL data by inspecting the top-level element's 'xsi:type'
                    ⍝             property.
                    ⍝  encoding - applies when <isMLS> is 1. See MLS2SOAP. Default: 1
                    ⍝  R        - SOAP-MLS
                    ⍝
                    ⍝ EXAMPLES:
                    ⍝  mls←⊃(1 'prop' 10 (0 2⍴⊂'')) (1 'prop2' (20 30) (0 2⍴⊂''))
                    ⍝  1) 0 Data2SOAP mls ==>
                    ⍝      1 'array' ''      (2 2⍴'xsi:type' 'SOAP-ENC:Array' 'SOAP-ENC:arrayType' 'xsd:ur-type[2,4]')
                    ⍝      2 'a'     1       (1 2⍴'xsi:type' 'xsd:boolean')
                    ⍝      2 'a'     'prop'  (1 2⍴'xsi:type' 'xsd:string')
                    ⍝      2 'a'     10      (1 2⍴'xsi:type' 'xsd:int')
                    ⍝      2 'array' ''      (2 2⍴'xsi:type' 'SOAP-ENC:Array' 'SOAP-ENC:arrayType' 'xsd:string[0,2]')
                    ⍝      3 'a'     ''      (0 2⍴⊂'')
                    ⍝      2 'a'     1       (1 2⍴'xsi:type' 'xsd:boolean')
                    ⍝      2 'a'     'prop2' (1 2⍴'xsi:type' 'xsd:string')
                    ⍝      2 'array' ''      (2 2⍴'xsi:type' 'SOAP-ENC:Array' 'SOAP-ENC:arrayType' 'xsd:int[2]')
                    ⍝      3 'a'     20      (0 2⍴⊂'')
                    ⍝      3 'a'     30      (0 2⍴⊂'')
                    ⍝      2 'array' ''      (2 2⍴'xsi:type' 'SOAP-ENC:Array' 'SOAP-ENC:arrayType' 'xsd:string[0,2]')
                    ⍝      3 'a'     ''      (0 2⍴⊂'')
                    ⍝  2) 1 Data2SOAP mls ==>
                    ⍝      1 'prop'  10 (1 2⍴'xsi:type' 'xsd:int')
                    ⍝      1 'prop2' '' (0 2⍴⊂'')
                    ⍝      2 'array' '' (2 2⍴'xsi:type' 'SOAP-ENC:Array' 'SOAP-ENC:arrayType' 'xsd:int[2]')
                    ⍝      3 'a'     20 (0 2⍴⊂'')
                    ⍝      3 'a'     30 (0 2⍴⊂'')
                    ⍝
                    ⍝ NOTES:
                    ⍝  - According to the SOAP specification (section 5.1), if a given element has
                    ⍝    non-empty content, it may not have subelements. For now, you must just be
                    ⍝    careful about passing such an MLS.
                    ⍝
                    ⍝ SUBFNS:   MLS2SOAP APL2SOAP
                    ⍝ -----------------------------------------------------------------------------------
 (isMLS encoding)←2↑larg,1
 :If isMLS ⋄ R←encoding MLS2SOAP R ⋄ :Else ⋄ R←APL2SOAP R ⋄ :EndIf
∇

∇ R←{larg}DecodeRequest xml;⎕IO
                    ⍝ Decode a SOAP-XML request
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←{decoding} {noCheckArray} DecodeRequest xml
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  xml          - SOAP-XML that is intended as a complete method-call
                    ⍝  decoding     - see <decoding> in ⍙DecodeMethod except that [type] should not be
                    ⍝                 passed when using the 3rd format of <decoding>.
                    ⍝                 Default: 1
                    ⍝  noCheckArray - see ⍙DecodeMethod.  Default: 0
                    ⍝  R            - [1] - success boolean
                    ⍝                 [2] - if success (R[1]=1):
                    ⍝                        [1] - name of the method
                    ⍝                        [2] - method argument as an MLS or arbitrary APL data
                    ⍝                        [3] - PVM for the attributes applied to the method,
                    ⍝                              e.g. <MyMethod xmlns="..."> ==> 1 2⍴'xmlns' '...'
                    ⍝                       if failure (R[1]=0):
                    ⍝                        3-element vector describing a SOAP Fault. If passed to
                    ⍝                        SOAPFault and then to MLS2XML, it yields a complete SOAP
                    ⍝                        Fault XML string (complete body of an HTTP response).
                    ⍝                        Important: Whenever such XML is returned, you should also
                    ⍝                        return an HTTP status of '500 Internal Server Error'.
                    ⍝
                    ⍝ SUBFNS:   APLType ⍙DecodeMethod
                    ⍝ -----------------------------------------------------------------------------------
 ⎕IO←1
 ⎕SHADOW'⎕ML'
 ⎕ML←3 ⍝ Protect. Even though we set ⎕ML to 3 in this namespace, a caller could localize it and then run ⎕CS, thereby setting it globally here.)
     
 :If 0=⎕NC'larg' ⋄ larg←1 0
 :ElseIf 1=×/⍴larg ⋄ larg←(larg 0)0
 :Else
   :If 0<≡2⊃larg ⋄ larg←larg 0 ⋄ :EndIf
   :If 0<≡1⊃larg ⋄ larg[1]←⊂(1⊃larg)0 ⋄ :EndIf
 :EndIf
     
 R←larg ⍙DecodeMethod xml
∇

∇ R←{larg}DecodeResponse xml;⎕IO
                    ⍝ Decode a SOAP-XML response
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←{decoding} {noCheckArray} DecodeResponse xml
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  xml          - SOAP-XML (result of calling some method via SOAP)
                    ⍝  decoding     - see <decoding> in ⍙DecodeMethod except that [type] should not be
                    ⍝                 passed when using the 3rd format of <decoding>.
                    ⍝                 Default: 1
                    ⍝  noCheckArray - see ⍙DecodeMethod.  Default: 0
                    ⍝  R            - result as APL data
                    ⍝                  [1] -  1 - success
                    ⍝                         0 - failure - a SOAP Fault structure is in 2nd element
                    ⍝                        ¯1 - failure - the SOAP message could not be decoded
                    ⍝                  [2] - if success (R[1]=1):
                    ⍝                         [1] - name of the method
                    ⍝                         [2] - method result as an MLS or arbitrary APL data
                    ⍝                         [3] - PVM for the attributes applied to the method,
                    ⍝                               e.g. <MyMethod xmlns="..."> ==> 1 2⍴'xmlns' '...'
                    ⍝                        if failure (R[1]≤0):
                    ⍝                          SOAP Fault structure (see ∇SOAPFault)
                    ⍝
                    ⍝ SUBFNS:   APLType ⍙DecodeMethod
                    ⍝ -----------------------------------------------------------------------------------
 ⎕IO←1
 ⎕SHADOW'⎕ML'
 ⎕ML←3 ⍝ Protect. Even though we set ⎕ML to 3 in this namespace, a caller could localize it and then run ⎕CS, thereby setting it globally here.)
     
 :If 0=⎕NC'larg' ⋄ larg←1 0
 :ElseIf 1=×/⍴larg ⋄ larg←(larg 1)0
 :Else
   :If 0<≡2⊃larg ⋄ larg←larg 0 ⋄ :EndIf
   :If 0<≡1⊃larg ⋄ larg[1]←⊂(1⊃larg)1 ⋄ :EndIf
 :EndIf
     
                    ⍝ We'll just leverage ⍙DecodeMethod since it's doing the work we need here but we
                    ⍝ need to modify the method name (drop 'Response' part).
 :If ↑R←larg ⍙DecodeMethod xml
   R←2⊃R
   :If 1∊':Fault'⍷1⊃R ⍝ Did the server send back a SOAP Fault structure? (the method "name" is 'SOAP-ENV:Fault')
     R←0((2⊃R)[;3])
   :Else
     R[1]←⊂{(¯8×'Response'≡¯8↑⍵)↓⍵}1⊃R ⍝ 'FooResponse' ==> 'Foo'
     R←1 R
   :EndIf
 :Else ⍝ this SOAP is invalid somehow and we constructed our own SOAP Fault structure in ⍙DecodeMethod
   R←¯1(2⊃R)
 :EndIf
∇

∇ R←I Descendants dv
                    ⍝ Return the indices of the descendants for some specified index
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←I Descendants dv
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  dv       - depth vector
                    ⍝  I        - index to find the descendants of
                    ⍝  R        - indices of the descendants, in ascending order
                    ⍝ -----------------------------------------------------------------------------------
 R←I+⍳¯1+(dv[I]≥I↓dv)⍳1
∇

∇ R←I DescendantsAndSelf dv
                    ⍝ Return the indices of the descendants and self for some specified index
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←I DescendantsAndSelf dv
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  dv       - depth vector
                    ⍝  I        - index to find the descendants of
                    ⍝  R        - indices of the descendants and self, in ascending order
                    ⍝ -----------------------------------------------------------------------------------
 R←I+¯1+⍳(dv[I]≥I↓dv)⍳1
∇

∇ R←{larg}EncodeRequest rarg;⎕IO;A
                    ⍝ Encode a SOAP-XML request
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←{isMLS} {encoding} {xmlencoding} EncodeRequest method methodarg {methodpvm}
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  method      - name of the method intended to be called
                    ⍝  methodarg   - argument to the method
                    ⍝  methodpvm   - PVM to apply to the method element.  Default: 0 2⍴⊂''
                    ⍝  isMLS       - see <isMLS> in Data2SOAP.  Default: 1
                    ⍝  encoding    - see <encoding> in ⍙EncodeMethod except that [type] should not be
                    ⍝                passed when using the 3rd format of <encoding>.
                    ⍝                Default: 0 (which is in alignment with WSDL binding use="literal")
                    ⍝  xmlencoding - see <xmlencoding> in MLS2XML.  Default: 'UTF-8'
                    ⍝  R           - SOAP-XML intended as a complete method-call
                    ⍝
                    ⍝ SUBFNS:   APLType ⍙EncodeMethod
                    ⍝ -----------------------------------------------------------------------------------
 ⎕IO←1
 ⎕SHADOW'⎕ML'
 ⎕ML←3 ⍝ Protect. Even though we set ⎕ML to 3 in this namespace, a caller could localize it and then run ⎕CS, thereby setting it globally here.)
     
 A←1 0 'UTF-8'
 :If 0=⎕NC'larg' ⋄ larg←A
 :Else ⋄ larg←larg,(×/⍴larg)↓A
   :If 0<≡2⊃larg ⋄ larg[2]←⊂(2⊃larg)0 ⋄ :EndIf
 :EndIf
     
 R←larg ⍙EncodeMethod rarg
∇

∇ R←{larg}EncodeResponse rarg;⎕IO;A
                    ⍝ Encode a SOAP-XML response
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   1) R←{type} {encoding} {xmlencoding} EncodeResponse method methodres {methodpvm}
                    ⍝           2) R←¯1     {''}       {xmlencoding} EncodeResponse rarg_to_SOAPFault
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  method      - name of the method yielding <methodres>
                    ⍝  methodres   - result of calling <method> (see <data> in Data2SOAP)
                    ⍝  methodpvm   - PVM to apply to the method element (usually just the same as that
                    ⍝                passed in the original SOAP request)
                    ⍝                Default: 0 2⍴⊂''
                    ⍝  rarg_to_SOAPFault - see rarg of ∇SOAPFault.
                    ⍝                      Important: Whenever this is returned, you should also return
                    ⍝                      an HTTP status of '500 Internal Server Error'.
                    ⍝  type        - 0 or 1: see <isMLS> in EncodeRequest/Data2SOAP.
                    ⍝                    ¯1: return a complete SOAP Fault structure as the result (see
                    ⍝                        SOAPFault), as XML.
                    ⍝                Default: 1
                    ⍝  encoding    - see <encoding> in ⍙EncodeMethod except that [type] should not be
                    ⍝                passed when using the 3rd format of <encoding>.
                    ⍝                Default: 0 (which is in alignment with WSDL binding use="literal")
                    ⍝  xmlencoding - see ∇MLS2XML. Default: 'UTF-8'
                    ⍝  R           - SOAP-XML intended to be passed back as a result, typicall in an HTTP body
                    ⍝
                    ⍝ SUBFNS:   APLType ⍙EncodeMethod MLS2XML SOAPFault
                    ⍝ -----------------------------------------------------------------------------------
 ⎕IO←1
 ⎕SHADOW'⎕ML'
 ⎕ML←3 ⍝ Protect. Even though we set ⎕ML to 3 in this namespace, a caller could localize it and then run ⎕CS, thereby setting it globally here.)
     
 A←1 0 'UTF-8'
 :If 0=⎕NC'larg' ⋄ larg←A ⋄ :Else ⋄ larg←larg,(×/⍴larg)↓A ⋄ :EndIf
     
 :If 0≤↑larg
   :If 0<≡2⊃larg ⋄ larg[2]←⊂(2⊃larg)1 ⋄ :EndIf
   rarg[1]←⊂(1⊃rarg),'Response'
   R←larg ⍙EncodeMethod rarg
 :Else
   :If 3=≡rarg ⋄ rarg←2⊃rarg ⋄ :EndIf ⍝ (in case they included the method name first)
   R←(3⊃larg)MLS2XML SOAPFault rarg
 :EndIf
∇

 EndsWith←{⍵≡(-⍴⍵)↑⍺}

∇ R←IsSimpleValue value
 :If 1<≡value ⍝ nested
   R←0
 :ElseIf (⎕DR value)∊82 80 160 320 ⍝ character
   R←↑1≥⍴⍴value
 :Else ⍝ numeric
   R←⍬≡⍴value
 :EndIf
∇

∇ R←{encoding}MLS2SOAP R;mls;content;I;pvm;mv;J;type
                    ⍝ Transform an MLS into a SOAP-MLS
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←{encoding} MLS2SOAP mls
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  mls      - fully formed MLS
                    ⍝  encoding - 0  - do not apply any datatype tagging to any elements
                    ⍝             1  - apply datatype tagging to each element according to its APL
                    ⍝                  datatype. However, for a given element, if its PVM contains the
                    ⍝                  attribute 'xsi:type', then its value is preserved (it's not
                    ⍝                  overwritten with the mapped APL datatype).
                    ⍝             apimls - apply datatype tagging according to the passed API-MLS.
                    ⍝                      This API-MLS follows the format described in API2WSDL
                    ⍝                      (2nd or 3rd element for a given method description).
                    ⍝             Observation: If all of the elements' datatypes are native to APL, then
                    ⍝             the 3rd format for <encoding> will yield the same result as <encoding>=1.
                    ⍝             Default: 1
                    ⍝  R        - SOAP-MLS. It's basically the same as the passed MLS but for each row,
                    ⍝             a datatype is somehow applied as an attribute. Also, "non-simple"
                    ⍝             content is spread out as more rows (a SOAP "array").
                    ⍝
                    ⍝ EXAMPLE:
                    ⍝  mls←0 4⍴0
                    ⍝  mls←mls⍪1 'prop1' 'this'       (0 2⍴⊂'')
                    ⍝  mls←mls⍪1 'prop2' (5 10)       (0 2⍴⊂'')
                    ⍝  mls←mls⍪1 'prop3' ('more' 7.5) (0 2⍴⊂'')
                    ⍝  MLS2SOAP mls ==>
                    ⍝      1 'prop1' 'this' (1 2⍴'xsi:type' 'xsd:string')
                    ⍝      1 'prop2' ''     (0 2⍴⊂'')
                    ⍝      2 'array' ''     (2 2⍴'xsi:type' 'SOAP-ENC:Array' 'SOAP-ENC:arrayType' 'xsd:int[2]')
                    ⍝      3 'a'     5      (0 2⍴⊂'')
                    ⍝      3 'a'     10     (0 2⍴⊂'')
                    ⍝      1 'prop3' ''     (0 2⍴⊂'')
                    ⍝      2 'array' ''     (2 2⍴'xsi:type' 'SOAP-ENC:Array' 'SOAP-ENC:arrayType' 'xsd:ur-type[2]')
                    ⍝      3 'a'     'more' (1 2⍴'xsi:type' 'xsd:string')
                    ⍝      3 'a'     7.5    (1 2⍴'xsi:type' 'xsd:double')
                    ⍝
                    ⍝ SUBFNS:   ∆MV IsSimpleValue
                    ⍝           PVMGetVal Ancestors MLSFind (if <encoding> is an API-MLS)
                    ⍝           APL2SOAP
                    ⍝ -----------------------------------------------------------------------------------
 :If 0=⎕NC'encoding' ⋄ encoding←1 ⋄ :EndIf
     
 mv←∆MV
 I←1
 :While I≤↑⍴R ⍝ (use :WHILE instead of :FOR because we may be expanding <R> on the fly)
   (content pvm)←R[I;3 4]
   :If content≡mv ⍝ (check this BEFORE calling IsSimpleValue so we don't try to run a potential ⎕NULL through it [⎕DR])
     :If ~0≡encoding ⋄ pvm←pvm⍪'xsi:null' 1 ⋄ :EndIf
     R[I;3 4]←''pvm ⍝ clean up - be sure to rid ∆mv (or ⎕NULL) from the content
     I←I+1
     
   :ElseIf IsSimpleValue content
     :If ~0≡encoding
       :If ~content≡''
       :OrIf I=↑⍴R ⋄ :OrIf ≥/R[I+0 1;1] ⍝ this means "if no descendants" (SOAP doesn't actually allow for a container to have non-empty content at its level, but we will allow it)
         :If 1≡encoding
           :If ~(⊂'xsi:type')∊pvm[;1] ⍝ if not already specified, e.g. 1 2⍴'xsi:type' 'xsd:dateTime'
             R[I;4]←⊂pvm⍪'xsi:type'('xsd:',(82 80 160 320 83 163 323 645 11⍳⎕DR content)⊃(4⍴⊂'string'),(3⍴⊂'int'),'double' 'boolean') ⍝ (Be sure to use 'double', not 'float', since APL "float" is 64-bit, not 32-bit.)
           :EndIf
         :Else ⍝ API-MLS
           :If 0≠J←encoding MLSFind R[(I Ancestors R[;1]),I;2]
           :AndIf ~mv≡type←'datatype'PVMGetVal(⊂J 4)⊃encoding
             :If ~':'∊type ⋄ type←'xsd:',type ⋄ :EndIf
             R[I;4]←⊂pvm⍪'xsi:type'type
           :EndIf
         :EndIf
       :EndIf
     :EndIf
     I←I+1
     
   :Else ⍝ we'll have to form a SOAP "array" and shove it in underneath this row
     mls←APL2SOAP content
     R[I;3]←⊂'' ⍝ clear it out
     mls[;1]←mls[;1]+R[I;1] ⍝ adjust to fit under this parent
     R←(I↑[1]R)⍪mls⍪I↓[1]R
     I←I+1+↑⍴mls ⍝ move on to next row, adjusting for how many rows we just added
   :EndIf
 :EndWhile
∇

∇ R←{encoding}MLS2XML mls;⍙mlchars;text;xlate;AV;apltype
                    ⍝ Transform an MLS into XML
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX: R←{encoding} MLS2XML mls
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  mls      - fully-formed MLS
                    ⍝  encoding - type of encoding for the resulting XML.
                    ⍝             It can be one of the following:
                    ⍝              ''                 - don't use any encoding
                    ⍝              'UTF-8'            - this is the default
                    ⍝              'UTF-16', 'UTF-32' - can only be used in Dyalog 12 or later
                    ⍝  R        - XML
                    ⍝
                    ⍝ SUBFNS: APLType ∆AV ∆MV
                    ⍝         ⍙MLS2XML ⍙MLS2XML_SprTags ⍙MLS2XML_Beg ⍙MLS2XML_PVM ⍙MLS2XML_End MLS
                    ⍝         TextRepl
                    ⍝         UTF8Encode (unless using Dyalog 12)
                    ⍝ -----------------------------------------------------------------------------------
 :If 0=⎕NC'encoding' ⋄ encoding←'UTF-8' ⋄ :EndIf
     
 mls[;1]←mls[;1]-↑mls ⍝ adjust since ⎕XML uses depth-origin of 0 because it always has exactly 1 root (unless empty, of course)
 R←('whitespace' 'preserve')('markup' 'preserve')('unknown-entity' 'preserve')⎕XML mls ⍝ ['whitespace' 'preserve'] in this context actually means to NOT add whitespace/formatting to the result
 :If ~''≡encoding ⋄ R←⎕UCS encoding ⎕UCS R ⋄ :EndIf
∇

∇ R←mls MLSFind path;B
                    ⍝ Find the first matching path in some MLS
                    ⍝∇∇{*:⎕ERROR 'DOMAIN ERROR'}
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←mls MLSFind path
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  path     - hierarchical path to find, e.g. 'Parent' 'Child' 'Grandchild'
                    ⍝  mls      - fully formed MLS to find the path in (only the first 2 columns need to
                    ⍝             be passed)
                    ⍝  R        - first row number of <mls> where the path is found; 0 if not found.
                    ⍝
                    ⍝ NOTES:
                    ⍝  - This does not currently work on an MLS that has multiple tags in a single element,
                    ⍝    e.g. 1 4⍴1 (,¨'b' 'u') 'somtext' ∆epvm
                    ⍝ -----------------------------------------------------------------------------------
     
 :If 0∊⍴mls ⋄ R←0 ⋄ :Return ⋄ :EndIf
     
 :If 82=⎕DR path
   :If (↑⍴mls)<R←(⊂[2]mls[;1 2])⍳⊂(↑mls)path ⋄ R←0 ⋄ :EndIf
 :ElseIf 1=⍴path←,path
   :If (↑⍴mls)<R←(⊂[2]mls[;1 2])⍳⊂(↑mls),path ⋄ R←0 ⋄ :EndIf
 :Else
   mls[;1]←mls[;1]-¯1+↑mls ⍝ normalize the depth vector
   :For R :In B/⍳⍴B←mls[;1 2]∧.≡(⍴path),¯1↑path ⍝ where all the path's last node matches in the MLS
     :If mls[R-(⌽(R-1)↑mls[;1])⍳⍳mls[R;1]-1;2]≡¯1↓path ⍝ ancestors match?
       :Return ⍝ found it
     :EndIf
   :EndFor
   R←0 ⍝ if we made it past the loop (or we didn't even get into the loop), we haven't found it
 :EndIf
∇

∇ R←mls MLSFindAncProp rarg;ancestors;I;J;prop;pvm;row
                    ⍝ In some MLS, look for some property up the ancestor tree
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←mls MLSFindAncProp prop row
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  prop     - property to find
                    ⍝  row      - row number of the MLS to begin the search at
                    ⍝  mls      - MLS
                    ⍝  R        - [1] - row number of the ancestor where the property is found (0 if not found)
                    ⍝             [2] - associated value ('' if not found)
                    ⍝
                    ⍝ SUBFNS:   Ancestors
                    ⍝ -----------------------------------------------------------------------------------
 :If 0=↑⍴mls ⋄ R←0 '' ⋄ :Return ⋄ :EndIf
 (prop row)←rarg
 ancestors←row,⌽row Ancestors mls[;1]
 I←0
 :Repeat
   pvm←4⊃mls[R←ancestors[I←I+1];]
   :If (↑⍴pvm)≥J←pvm[;1]⍳⊂prop
                            ⍝ Found it ==> bolt now with the value attached.
     R←R,pvm[J;2]
     :Return
   :EndIf
 :Until I=⍴ancestors
 R←0 '' ⍝ wasn't found
∇

∇ R←mls MLSSubset rarg;defval;path
                    ⍝ Get a descendant subset of a passed MLS, starting with the row or path
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   1) R←mls MLSSubset path {defval}
                    ⍝           2) R←mls MLSSubset row
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  path     - hierarchical path to find, e.g. 'Parent' 'Child' 'Grandchild'
                    ⍝  defval   - default value.  This is returned as the result if the path is not found.
                    ⍝             Default: ∆MV
                    ⍝  row      - scalar row number of the MLS (instead of finding the path)
                    ⍝  mls      - fully formed MLS
                    ⍝  R        - descendant subset MLS (depths are preserved)
                    ⍝
                    ⍝ SUBFNS:   ∆MV MLSFind DescendantsAndSelf
                    ⍝ -----------------------------------------------------------------------------------
 :If 0<≡rarg
   :If 3≤≡rarg ⋄ (path defval)←rarg
   :Else ⋄ (path defval)←rarg ∆MV
   :EndIf
   rarg←mls MLSFind path
   :If 0=rarg ⋄ R←defval ⋄ :Return ⋄ :EndIf
 :EndIf
 R←mls[rarg DescendantsAndSelf mls[;1];]
∇

∇ R←MakePVP R
 :If 0=⍴⍴R ⍝ (check for Dyalog because of prototypes)
   R←0⍴⊂''
 :ElseIf 2≠⍴R
   R←(↑R)(1↓R)
 :EndIf
∇

∇ R←prop PVMGetVal pvm;B;defval;I;mv
                    ⍝ Return the value of the specified property in the PVM; default to specified value or to ∆MV
                    ⍝ -----------------------------------------------------------------------------------
 :If B←1<≡prop ⋄ (prop defval)←prop ⋄ :EndIf
     
 mv←∆MV
 :If (↑⍴pvm)≥I←pvm[;1]⍳⊂prop
   R←(⊂I 2)⊃pvm
   :If B ⋄ :AndIf mv≡R ⍝ we should still override with defval if the value in the <pvm> is just ∆mv
     R←defval
   :EndIf
 :ElseIf B
   R←defval
 :Else
   R←mv
 :EndIf
∇

∇ R←props PVMGetVals pvm;B;I;mv
                    ⍝ Return the values of the specified properties in the PVM; default to specified respective value or to ∆MV
                    ⍝ -----------------------------------------------------------------------------------
 mv←⊂∆MV
 :If 2=≡props
   R←(pvm[;2],mv)[pvm[;1]⍳props]
 :Else
                        ⍝ Some default values were passed with one or more properties.
   pvm←(~pvm[;2]∊mv)⌿pvm ⍝ don't allow a value of ∆mv in the <pvm> take precedence over a default value
   I←WHERE B←1=≡¨props
   props[I]←⊂[2]props[I],[1.5]mv
   props[I]←MakePVP¨props[I←WHERE~B]
   (props R)←⊂[1]⊃props
   I←pvm[;1]⍳props
   B←I≤↑⍴pvm
   R[WHERE B]←pvm[B/I;2]
 :EndIf
∇

∇ R←I Parent dv
                    ⍝ Return the index of the parent for some specified index
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←I Parent dv
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  dv       - depth vector
                    ⍝  I        - index to find the parent of
                    ⍝  R        - index of the parent
                    ⍝ -----------------------------------------------------------------------------------
 R←I-(⌽(I-1)↑dv)⍳dv[I]-1
∇

∇ R←{larg}PrepareWSDL rarg;⎕IO;api;decl;pvm;encoding;decl2
                    ⍝ Prepare a WSDL document given a description of the API (cover for API2WSDL)
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←{encoding} {decl} PrepareWSDL api pvm
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  api      - see API2WSDL
                    ⍝  pvm      - see API2WSDL
                    ⍝  encoding - see MLS2XML
                    ⍝  decl     - additional processing instructions, e.g. for XSLT
                    ⍝  R        - XML form of the result returned from API2WSDL
                    ⍝
                    ⍝ SUBFNS:   APLType MLS2XML API2WSDL
                    ⍝ -----------------------------------------------------------------------------------
 ⎕IO←1
 ⎕SHADOW'⎕ML'
 ⎕ML←3 ⍝ Protect. Even though we set ⎕ML to 3 in this namespace, a caller could localize it and then run ⎕CS, thereby setting it globally here.)
     
 (api pvm)←rarg
     
 :If 0=⎕NC'larg' ⋄ (encoding decl2)←'UTF-8' ''
 :ElseIf 82=⎕DR larg ⋄ (encoding decl2)←larg''
 :Else ⋄ (encoding decl2)←larg
 :EndIf
     
 decl←'<?xml version="1.0" '
 :If 0≠⍴encoding ⋄ decl←decl,'encoding="',encoding,'" ' ⋄ :EndIf
 decl←decl,'?>'
 R←decl,decl2,encoding MLS2XML pvm API2WSDL api
∇

∇ R←RepairDV dv;J;I
                    ⍝ For a valid depth vector that had some elements removed, normalize it
                    ⍝ -----------------------------------------------------------------------------------
 dv←dv+1-⌊/dv ⍝ normalize
 I←⍳0⌈⌈/dv
 J←⍳⍴dv
 R←+/2</0,⌈\⌈⍀J×[1]dv∘.=I
∇

∇ R←SOAP2APL mls;⍙depths;⍙info
                    ⍝ Transform a SOAP-MLS into APL
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←SOAP2APL mls
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  mls      - SOAP-MLS
                    ⍝  R        - APL data
                    ⍝
                    ⍝ SUBFNS:   APLType ∆MV ⍙SOAP2APL_Recurse Children
                    ⍝ -----------------------------------------------------------------------------------
 ⍙depths←mls[;1]
 ⍙info←⊂[2]mls[;3 4]
 R←1 ''⍙SOAP2APL_Recurse 1⊃⍙info
∇

∇ R←{decoding}SOAP2Data mls;I;pvm
                    ⍝ Transform a SOAP-MLS into an MLS or arbitrary APL data
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←{decoding} SOAP2Data mls
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  mls      - SOAP-MLS (presumably just from running SOAP-XML through XML2MLS).
                    ⍝  decoding - this is applicable when SOAP2MLS has to be called. See SOAP2MLS. Default: 1
                    ⍝  R        - [1] - success bit
                    ⍝             [2] - Success:
                    ⍝                     An MLS or arbitrary APL data (an MLS itself may contain non-simple APL data).
                    ⍝                     Basically what happens here is the SOAP datatype attributes are
                    ⍝                     applied and what results is one of:
                    ⍝                     1) The content portions of the MLS become "APL data" (which
                    ⍝                        includes absorbing SOAP arrays into content).
                    ⍝                     2) The MLS is transformed into some arbitrary APL data (the top-level
                    ⍝                        element of the SOAP-XML is a SOAP "array").
                    ⍝                   Failure: error messsage
                    ⍝
                    ⍝ SUBFNS:   SOAP2MLS SOAP2APL
                    ⍝ -----------------------------------------------------------------------------------
 :If 0∊⍴mls
   R←1(0 4⍴0 '' ''(0 2⍴⊂''))
 :Else
   pvm←4⊃mls[1;]
   :If (↑⍴pvm)≥I←⌊/pvm[;1]⍳'xsi:type' 'type' ⍝ is there a datatype specified for this element?
   :AndIf 1∊':Array'⍷2⊃pvm[I;] ⍝ at the top-level, we have a SOAP array ==> get as APL data
     R←1(SOAP2APL mls)
   :Else ⍝ the top-level is a natural MLS (there may be some embedded arrays but SOAP2MLS handles that)
     :If 0=⎕NC'decoding' ⋄ decoding←1 ⋄ :EndIf
     R←1(decoding SOAP2MLS mls)
   :EndIf
 :EndIf
∇

∇ R←{decoding}SOAP2MLS R;I;mv;D;content;pvm;type;apimls;B;isAPI;tag;J;strippvm;PVM
                    ⍝ Transform a SOAP-MLS into an MLS that contains normalized/datatype'd data
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←{decoding} SOAP2MLS mls
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  mls      - SOAP-MLS
                    ⍝  decoding - this is the type of decoding to perform. Default: 1
                    ⍝               0  - no decoding. Just form an MLS without applying any data
                    ⍝                    transformations.
                    ⍝               1  - expect datatype tagging for each element (except containers)
                    ⍝                    and transform them to their APL equivalent. For a given element,
                    ⍝                    if its PVM contains a value for 'xsi:type' that does not
                    ⍝                    transform to an APL datatype, then that attribute/value pair
                    ⍝                    is preserved in the MLS and the data/content is not affected.
                    ⍝              apimls - expect no datatype tagging; apply data transformations
                    ⍝                       according to the passed API-MLS.
                    ⍝                       This API-MLS follows the format described in API2WSDL
                    ⍝                       (2nd or 3rd element for a given method description).
                    ⍝             Note that regardless of what value is passed for <decoding>, any
                    ⍝             arbitrary APL data found in content is appropriately transformed.
                    ⍝  R        - MLS with the content transformed into normalized data (as specified by
                    ⍝             the SOAP datatypes). The content of a given row can be arbitrary APL
                    ⍝             data. SOAP allows for non-simple data using a SOAP "array" which can
                    ⍝             be embedded in a true SOAP-MLS (the XML).
                    ⍝
                    ⍝ EXAMPLE:
                    ⍝  mls←0 4⍴0
                    ⍝  mls←mls⍪1 'tag1'  ''         (0 2⍴⊂'')
                    ⍝  mls←mls⍪2 'sub1'  'this'     (1 2⍴'xsi:type' 'xsd:string')
                    ⍝  mls←mls⍪2 'sub2'  '5'        (1 2⍴'xsi:type' 'xsd:int')
                    ⍝  mls←mls⍪2 'sub3'  ''         (0 2⍴⊂'')
                    ⍝  mls←mls⍪3 'array' ''         (2 2⍴'xsi:type' 'SOAP-ENC:Array' 'SOAP-ENC:arrayType' 'xsd:ur-type[4]')
                    ⍝  mls←mls⍪4 'a'     '2'        (1 2⍴'xsi:type' 'xsd:int')
                    ⍝  mls←mls⍪4 'a'     'more'     (1 2⍴'xsi:type' 'xsd:string')
                    ⍝  mls←mls⍪4 'array' ''         (2 2⍴'xsi:type' 'SOAP-ENC:Array' 'SOAP-ENC:arrayType' 'xsd:int[2]')
                    ⍝  mls←mls⍪5 'a'     '10'       (0 2⍴⊂'')
                    ⍝  mls←mls⍪5 'a'     '20'       (0 2⍴⊂'')
                    ⍝  SOAP2MLS mls ==>
                    ⍝      1 'tag1'  ''                 (0 2⍴⊂'')
                    ⍝      2 'sub1'  'this'             (0 2⍴⊂'')
                    ⍝      2 'sub2'  5                  (0 2⍴⊂'')
                    ⍝      2 'sub3'  (2 'more' (10 20)) (0 2⍴⊂'')
                    ⍝
                    ⍝ SUBFNS:   APLType ∆MV PVMGetVal Descendants Ancestors MLSFind RepairDV
                    ⍝           SOAP2APL
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝⍝⍝⍝ First, get rid of any extraneous elements (the ones that end in "_WSDLPart"). They
                    ⍝⍝⍝⍝ are just part of the WSDL machinery; WSDL needed them as wrappers in order to apply
                    ⍝⍝⍝⍝ any constraints to datatypes, e.g. 'minOccurs'.
                    ⍝⍝⍝:IF 1∊B←(¯9↑¨R[;2])∊⊂'_WSDLPart' ⋄ R←(~B)⌿R ⋄ R[;1]←RepairDV R[;1] ⋄ :ENDIF
     
 :If 0∊⍴R ⋄ :Return ⋄ :EndIf
     
 :If isAPI←2=⎕NC'decoding'
   :If isAPI←0<≡decoding
     apimls←decoding
   :EndIf
 :Else
   decoding←1
 :EndIf
     
 R[;1]←R[;1]-(↑R)-1 ⍝ normalize
 I←1
 mv←∆MV
 :Repeat
   (tag content pvm)←R[I;2 3 4]
   strippvm←1
   :If isAPI
     :If (⍴tag)≥J←tag⍳':' ⍝ we're just going to remove any namespace prefixes that some SOAP encoder may have put there)
       R[I;2]←⊂J↓tag
     :EndIf
     :If 0=J←apimls MLSFind R[(I Ancestors R[;1]),I;2]
     :OrIf mv≡type←'datatype'PVMGetVal PVM←(⊂J 4)⊃apimls
       :GoTo ∆end
     :ElseIf (↑⍴pvm)≥J←pvm[;1]⍳⊂'xsi:null' ⋄ :AndIf (,'1')≡⍕(⊂J 2)⊃pvm ⍝ null specified?
       type←'null' ⍝ so the value becomes ∆MV
     :Else
       strippvm←0
       R[I;4]←⊂{⎕ML←1 ⋄ ↑∪↓⍵}pvm⍪PVM ⍝⍝⍝BPB add WSDL specification in if not there
     :EndIf
   :ElseIf 0=decoding ⍝ we'll only continue if we have some arbitrary to transform
     :If ~(↑⍴pvm)≥J←pvm[;1]⍳⊂'xsi:type' ⍝ is there a datatype specified for this element?
     :OrIf ~'Array'≡type←(type⍳':')↓type←(⊂J 2)⊃pvm
       :GoTo ∆end
     :EndIf
   :ElseIf (↑⍴pvm)≥J←pvm[;1]⍳⊂'xsi:type' ⍝ is there a datatype specified for this element?
     type←(⊂J 2)⊃pvm
     type←(type⍳':')↓type ⍝ the type for comparison purposes
   :ElseIf (↑⍴pvm)≥J←pvm[;1]⍳⊂'xsi:null' ⋄ :AndIf (,'1')≡⍕(⊂J 2)⊃pvm ⍝ null specified?
     type←'null'
   :Else
     :GoTo ∆end
   :EndIf
     
   :Select type
   :Case 'string' ⍝ just capture it so we don't go into the :ELSE below
   :CaseList 'int' 'float' 'double' 'boolean' 'integer' ⍝ 'integer' comes from an API-MLS but 'int' comes from 'xsd:int'
     content←(⊂I 3)⊃R
     :If (⎕DR content)∊82 80 160 320
                             ⍝⍝⍝BPB - this checking is disabled for now until we implement better validation
                             ⍝        "true" and "false" need to be supported as boolean values
                             ⍝        checking needs to be defered until we implement better SOAP FAULT support
               ⍝                 :If ''≡content ⍝ (this really shouldn't be allowed since null should have been used instead)
               ⍝                    R[I;3]←⊂mv
               ⍝                 :Else
               ⍝                    :If content[1]='-' ⋄ content[1]←'¯' ⋄ :EndIf
               ⍝                    R[I;3]←2 1⊃⎕VFI content
               ⍝                 :EndIf
     :EndIf
   :Case 'Array' ⍝ (was 'SOAP-ENC:Array')
     D←I,I Descendants R[;1]
     R[I-1;3]←⊂SOAP2APL R[D;] ⍝ tuck up into its parent's content
     R←R[(⍳↑⍴R)~D;] ⍝ rid these descendants since they've just been absorbed
     I←I-1 ⍝ account for the descendants having gone away
     :GoTo ∆end ⍝ skip over the part that messes with the pvm for this row (this row has been removed by now)
     
   :Case 'null'
     R[I;3]←⊂mv
     
   :Else ⍝ e.g. 'xsd:dateTime' 'xsd:base64' ''
                            ⍝ Leave the datatype attribute intact for the application developer to pick up on.
     :GoTo ∆end
     
   :EndSelect
     
                        ⍝ Remove the 'xsi:type' or 'xsi:null' attribute. We can end up with
                        ⍝ 0 2⍴⊂'    ' or something like that (instead of the normalized 0 2⍴⊂'')
                        ⍝ so we'll check explicitly for whether that's about to happen and remedy.
   :If strippvm
     :If 1=↑⍴pvm ⋄ R[I;4]←⊂0 2⍴⊂''
     :Else ⋄ R[I;4]←⊂pvm[(⍳↑⍴pvm)~J;]
     :EndIf
   :EndIf
     
∆end:
 :Until (↑⍴R)<I←I+1
∇

∇ R←SOAPFault rarg;code;detail;string;epvm
                    ⍝ Construct a SOAP Fault structure as an MLS
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←SOAPFault code string detail
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  code       - charvec - code for identifying the error.
                    ⍝               It is of the form: Generic.Specific, e.g. 'Client.Authentication'.
                    ⍝               The generic part must be one of the following:
                    ⍝                'VersionMismatch' 'MustUnderstand' 'DataEncodingUnknown' 'Client' 'Server'
                    ⍝               The specific part is probably something like:
                    ⍝                'Invalid' 'Unexpected' 'Permission' ...
                    ⍝  string     - charvec - description of the particular reason for failure (probably good
                    ⍝               for an end-user type of message)
                    ⍝  detail     - charvec - application specific details (probably good for a developer to analyze)
                    ⍝  R          - fully formed SOAP-MLS. If converted to XML, it is suitable as the
                    ⍝               complete body of an HTTP response.
                    ⍝
                    ⍝ NOTES:
                    ⍝  - see http://www.w3c.org/tr/soap (Section 4.4 SOAP Fault)
                    ⍝ -----------------------------------------------------------------------------------
     
 (code string detail)←rarg
     
 :If ~':'∊code ⋄ code←'SOAP-ENV:',code ⋄ :EndIf
     
 epvm←0 2⍴⊂''
     
 R←0 4⍴0
 R←R⍪1 '?xml version="1.0"?' ''epvm
 R←R⍪1 'SOAP-ENV:Envelope' ''(4 2⍴'SOAP-ENV:encodingStyle' 'http://schemas.xmlsoap.org/soap/encoding/' 'xmlns:SOAP-ENV' 'http://schemas.xmlsoap.org/soap/envelope/' 'xmlns:xsd' 'http://www.w3.org/2001/XMLSchema' 'xmlns:xsi' 'http://www.w3.org/2001/XMLSchema-instance')
 R←R⍪2 'SOAP-ENV:Body' ''epvm
 R←R⍪3 'SOAP-ENV:Fault' ''epvm
 R←R⍪4 'faultcode'code epvm
 R←R⍪4 'faultstring'string epvm
 R←R⍪4 'detail'detail epvm
∇

∇ R←TOUP R;L;B
                    ⍝ For a character vector, convert all lowercase characters to uppercase characters
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ Be careful not to convert the traditionally-converted non-ASCII characters though (ÇÄÉÑÖÜ).
 (B/R)←'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[L⍳(B←R∊L←'abcdefghijklmnopqrstuvwxyz')/R]
∇

∇ R←xlate TextRepl text;row;find;avail;repl;allB;findI;rows;B;rk;⎕IO
                    ⍝ Replace sets of characters in some character vector (like TEXTREPL but doesn't use assembler)
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←xlate TextRepl text
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  text     - character vector to replace some characters in
                    ⍝  xlate    - translation table, one row for each find/replace pair:
                    ⍝              [;1] - characters to find
                    ⍝              [;2] - characters to replace with
                    ⍝             This may also be a segmented-string of the form '/find1/repl1/find2/repl2...'
                    ⍝             (using any delimiter) like that used as the left argument to TEXTREPL.
                    ⍝  R        - character vector with all of the replacements.
                    ⍝             If some characters are found (in xlate[I;1]), they are replaced with
                    ⍝             xlate[I;2] and then those characters cannot be found again, e.g.
                    ⍝             (⊃('this here' 'that')('this' 'other')) TextRepl 'this here and this' ==> 'that and other'
                    ⍝
                    ⍝ SUBFNS:   APLType IsADS WHERE
                    ⍝ -----------------------------------------------------------------------------------
     
 ⎕IO←1 ⍝ (yes, this is called by functions that set ⎕IO←0)
 rk←⍴⍴xlate
     
                    ⍝ Validate the arguments.
 :If 1≠⍴⍴text ⋄ 'DOMAIN ERROR: TextRepl right argument'⎕SIGNAL 500 ⋄ :EndIf
 :If ~rk∊1 2 ⋄ 'DOMAIN ERROR: TextRepl left argument'⎕SIGNAL 501 ⋄ :EndIf
     
                    ⍝ Transform a repl-string into a normalized N×2 matrix of find/repl.
 :If rk=1
   xlate←1↓¨(+\xlate=↑xlate)⊂xlate
   rows←0.5×⍴xlate
   :If rows≠⌈rows
     'DOMAIN ERROR: TextRepl left argument'⎕SIGNAL 501
   :EndIf
   xlate←(rows,2)⍴xlate
 :Else
   rows←↑⍴xlate
 :EndIf
     
                    ⍝ Initialize.
 R←text
 allB←(⍴text)⍴0
 avail←(⍴text)⍴1
                    ⍝ivec←⍳⍴text
     
                    ⍝ For Dyalog, create a derived function for faster performance
                    ⍝ (also do this because there is no ⎕SS equivalent in Dyalog).
     
 :For row :In ⍳rows
   (find repl)←xlate[row;]
   B←find⍷text
   findI←WHERE avail∧B ⍝ (avail^B)/ivec
   R[findI]←⊂repl
   allB[findI]←1
   avail[¯1+∊findI+⊂⍳×/⍴find]←0
 :EndFor
     
 R←∊(avail∨allB)/R
∇

∇ R←{larg}UTF8Decode utf8;ucs;type;bad;mult;good;b;f;len;class;i;⎕IO
                    ⍝ Decode a character vector that is encoded as UTF-8
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←{ifbad} UTF8Decode utf8
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  utf8     - character vector that is encoded as UTF-8
                    ⍝  ifbad    - how to treat "bad" unicode code points. A "bad" unicode code point just
                    ⍝             means it has no counterpart in ⎕AV. This isn't actually possible in Dyalog 12.
                    ⍝             The following values for <ifbad> are possible:
                    ⍝              0 - insert the unicode code point (an integer for the decimal value)
                    ⍝              1 - insert the XML form of '&#nnnn;', where nnnn is the decimal
                    ⍝                  value for the unicode code point. However, '&' won't actually
                    ⍝                  be used; unicode code point 27 (⎕TSESC) will be used instead.
                    ⍝                  See ∇XMLUnescape for some discussion on why this is a reasonable convention.
                    ⍝             Default: 0
                    ⍝  R        - decoded character vector (can be heterogeneous, actually; see <ifbad> above).
                    ⍝
                    ⍝ NOTES:
                    ⍝  ∘ See also UTF8Encode.
                    ⍝
                    ⍝ SUBFNS:
                    ⍝  APL+Win, Dyalog pre-12: ∆AV ∆AVU
                    ⍝  All:                    APLType
                    ⍝ -----------------------------------------------------------------------------------
     
 R←'UTF-8'⎕UCS ⎕UCS utf8
∇

∇ R←UTF8Encode rarg;⎕IO;len;J;I;B;ucs;AV;DR
                    ⍝ Encode a character vector as UTF-8
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX: R←UTF8Encode rarg
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  rarg   - character vector to be encoded as UTF-8.
                    ⍝           Actually, a given element can also be an integer for the unicode code
                    ⍝           point. This would only be necessary if not using Dyalog 12. Also, it
                    ⍝           would only ever be needed for a unicode code point that is not in ∆AVU,
                    ⍝           that is, it does not have a corresponding character in ⎕AV.
                    ⍝           This allows for roundtrips using UTF8Encode and UTF8Decode, e.g.
                    ⍝           p≡UTF8Decode UTF8Encode p←'AB',8734 8735,'CDE'
                    ⍝  R      - UTF-8-encoded character vector
                    ⍝
                    ⍝ NOTES:
                    ⍝  ∘ See also UTF8Decode, ∆AVU.
                    ⍝  ∘ Unless we're in Dyalog 12, this function obviously cannot accept any real
                    ⍝    unicode characters outside of ⎕AV. However, a given unicode code point can be
                    ⍝    passed as an integer instead. Also, the writer of some XML could just use
                    ⍝    '&#nnnn;' to specify such characters.
                    ⍝  ∘ Some characters in ⎕AV are not mapped to a unicode point (have 65533 in
                    ⍝    corresponding ∆AVU element) so take note that such characters will not make the
                    ⍝    round trip as so: a≡UTF8Decode UTF8Encode a←(∆AVU=65533)/⎕AV ==> 0
                    ⍝
                    ⍝ SUBFNS:
                    ⍝  APL+Win, Dyalog pre-12: ∆AV ∆AVU
                    ⍝  All:                    APLType
                    ⍝ -----------------------------------------------------------------------------------
     
 :If (⎕DR rarg)∊11 83 163 323 326 ⍝ this would be unusual, but it is allowed, and it nicely accommodates automated testing
   B←(⎕DR¨rarg)∊11 83 163 323
   (B/rarg)←⎕UCS B/rarg
 :EndIf
 R←⎕UCS'UTF-8'⎕UCS rarg
∇

∇ R←WHERE B
                    ⍝ This is good to have as a subroutine so it can be easily modified without having
                    ⍝ to change a lot of code that utilizes such a primitive action.
                    ⍝ In APL+Win, it is written as assembler (faster for "large" data and not prone to WS FULL).
                    ⍝ In Dyalog, we'll just use the standard idiom B/⍳⍴B, which is documented as being optimized.
 R←B/⍳⍴B
∇

∇ R←{larg}XML2MLS xml;⎕IO;cell;cells;cells_2;content;curdepth;endmark;endsI;hasText;hasTextB;index_cells;inQuotes;isStartTag;isWholeTag;jumpRow;noBump;pvm;row_R;specialB;tag;wspace;AV;endmarks;begs;B;B2;I;clean;decode;S;pre;isADS;ign_bad_att;apltype;A
                    ⍝ Transform XML into an MLS
                    ⍝∇∇{*:→∆err}
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←{clean} {decode} {ignore_bad_attribs} XML2MLS xml
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  xml      - XML string, encoded as UTF-8 (or ASCII, of course, which is just a subset of UTF-8)
                    ⍝  clean    - (optional)
                    ⍝              0 - preserve whitespace (default)
                    ⍝              1 - force deletion of extraneous whitespace unless an element's
                    ⍝                  'xml:space' attribute is set to 'preserve' (will look up at the
                    ⍝                  ancestor tree to get the value).
                    ⍝              2 - force deletion of extraneous whitespace.
                    ⍝                  This is not currently available for Dyalog 12.1 or later.
                    ⍝              3 - preserve whitespace but at least remove rows of the MLS that have
                    ⍝                  '' as the tag and just whitespace for the content.
                    ⍝                  This is not currently available for Dyalog 12.1 or later.
                    ⍝  decode   - (optional) decode into unicode characters (or into ⎕AV if don't have unicode support yet)
                    ⍝             Default: 0 ==> do not decode; leave as UTF-8.
                    ⍝  ignore_bad_attribs - (optional) whether to ignore bad attribute sections instead
                    ⍝                       of erroring. This is not currently available for Dyalog 12.1 or later.
                    ⍝                       Default: 0
                    ⍝  R        - MLS (encoded as UTF-8 unless <decode> in larg is set to 1)
                    ⍝
                    ⍝ SUBFNS:
                    ⍝  APL+Win: States
                    ⍝  Dyalog:  ⍙XML2MLS_Within
                    ⍝  Both:    APLType IsADS ∆AV
                    ⍝           WHERE XMLUnescape UTF8Decode
                    ⍝           MLSFindAncProp (only if <clean> in <larg> is set to 1)
                    ⍝
                    ⍝ NOTES:
                    ⍝  An XML parser should preserve all whitespace (unless it's outside of the root
                    ⍝  tag, of course).  To respect the 'xml:space' attribute of any given tag and to
                    ⍝  perhaps tighten up an MLS, see <clean>. The 'xml:space' attribute is not really
                    ⍝  for parsers to respect; it is for the "application" to respect. It may have a
                    ⍝  value of 'default' or 'preserve'. 'default' simply means to let the application
                    ⍝  do whatever it deems appropriate.  'preserve' means that even the "application"
                    ⍝  should not delete extraneous whitespace.
                    ⍝ -----------------------------------------------------------------------------------
 ⎕IO←1
 :Trap 0
   :If 0=⎕NC'larg' ⋄ clean←decode←ign_bad_att←0 ⋄ :Else ⋄ (clean decode ign_bad_att)←3↑larg ⋄ :EndIf
     
                    ⍝ ===================================================================================
   :Select clean
   :Case 0
     A←'preserve'
   :Case 1
     A←'strip' ⍝ 'xml:space' is still respected though
   :Case 2 ⍝ ⎕XML does not seem to have this option
                            ⍝ This will at least do the trick for automated testing purposes.
     xml←(1 2⍴'xml:space="preserve"' 'xml2mls:space="preserve"')TextRepl xml
     A←'strip'
   :Case 3 ⍝ ⎕XML does not seem to have this option ==> accommodate below though, for testing
     A←'preserve'
   :EndSelect
     
   R←('whitespace'A)('markup' 'preserve')('unknown-entity' 'preserve')⎕XML xml
     
   :If 0∊⍴R
     R←0 4⍴0 ⍝ (prototype for ⎕XML is 0 5⍴⊂⍬)
   :Else
     R←4↑[2]R
     R[;1]←R[;1]+1 ⍝ adjust since ⎕XML uses depth-origin of 0; it always has exactly 1 root (unless empty, of course)
     
     :If clean=2 ⍝ undo our temporary kludge for allowing automated testing to run
       :For I :In ⍳↑⍴R
         pvm←(⊂I 4)⊃R
         :If (↑⍴pvm)≥A←pvm[;1]⍳⊂'xml2mls:space'
           pvm[A;1]←⊂'xml:space'
           R[I;4]←⊂pvm
         :EndIf
       :EndFor
     :ElseIf clean=3 ⍝ fixup so automated testing will work ==> ⍝ remove rows that have an empty tag and "empty" content
     :AndIf 1∊B←R[;2]∊⊂''
     :AndIf 1∊B2←∧/¨(B/R[;3])∊¨⊂∆AV[10 11 14 33]
       R←(~B\B2)⌿R
     :EndIf
     
     :If decode
       I←WHERE 0≠∊⍴¨R[;3] ⍝ (if we only work on the non-empty ones, we won't have to use the 1↓¨(+\A=⎕AV[1])⊂A algorithm)
       A←∊⎕AV[1],¨R[I;3]
       A←'UTF-8'⎕UCS ⎕UCS A
       R[I;3]←(A≠⎕AV[1])⊂A ⍝ *** see if all of this is faster than: R[I;3]←(⊂'UTF-8') ⎕UCS¨ ⎕UCS¨ R[I;3]
     :EndIf
   :EndIf
     
   :Return
     
 :Else
   :If ''≡xml~∆AV[10 11 14 33]
     R←0 4⍴0
   :Else
     'DOMAIN ERROR: The XML is not well-formed.'⎕SIGNAL 500
   :EndIf
 :EndTrap
∇

∇ R←∆AV
                    ⍝ Return ⎕AV in APL+Win order whether in APL+Win or in Dyalog.
                    ⍝ This returns ⎕AV in an order such that the 11 ⎕DR of it is in ascending order,
                    ⍝ which can be the real value of using ∆AV in algorithms.
 R←⎕AV[⎕IO+0 43 44 58 91 92 6 7 1 9 2 10 5 3 11 235 220 221 222 223 224 225 226 227 228 229 230 8 219 238 217 250 4 204 215 216 61 12 218 13 185 248 180 169 194 168 46 156 48 49 50 51 52 53 54 55 56 57 240 193 160 162 164 172 231 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 155 158 249 167 16 237 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 123 192 125 175 95 124 126 191 190 245 246 176 177 161 163 196 195 253 254 203 96 207 64 183 198 197 205 206 181 182 159 157 186 187 188 189 166 251 243 63 62 59 60 127 252 128 247 244 47 165 209 208 45 184 179 200 199 201 202 239 94 14 173 241 210 178 174 15 242 129 97 98 99 130 131 132 100 101 134 102 103 104 105 106 107 108 135 109 110 111 112 136 171 137 113 114 115 138 116 117 139 140 141 142 118 143 144 145 146 147 148 149 150 119 151 152 153 120 154 121 211 212 122 213 170 214 232 233 234 236 93 133 255]
∇

∇ R←∆AVU
                    ⍝ This is like ⎕AVU in Dyalog 12.
                    ⍝ Return the unicode points that correspond to ⎕AV.
                    ⍝ In APL+Win, ∆AVU has 28 occurrences of 65533 ("REPLACEMENT CHARACTER").
                    ⍝ In Dyalog, ∆AVU doesn't have any of those; they're all mapped.
                    ⍝
                    ⍝ The following is a bit of information on some characters worthy of discussion:
                    ⍝   *  ⍝ Dyalog uses 002A[42], as opposed to, e.g. 22C6, 2217
                    ⍝   -  ⍝ Dyalog uses 002D[45], as opposed to, e.g. 2212
                    ⍝   ¯  ⍝ 00AF[175]. There's no reason to mess with this (SOAP utils convert real negative numbers to the appropriate character, '-', outside of any character conversions).
                    ⍝   ~  ⍝ Dyalog uses 007E[126], as opposed to, e.g. 223C
                    ⍝   |  ⍝ Dyalog uses 007C[124], as opposed to, e.g. 2223
                    ⍝   (broken stile)  ⍝ No reason to use anything but 00A6[166]. Dyalog doesn't have this in their ⎕AV.
                    ⍝   ^  ⍝ In Dyalog ⎕AV, there is a "LOGICAL AND" character for this 2227[8743] (which is
                    ⍝      ⍝ similar to "LOGICAL OR" at 2288[8744]). Dyalog also has a separate element, the
                    ⍝      ⍝ "CIRCUMFLEX ACCENT" character 005E[94]. In APL+Win, since there is only
                    ⍝      ⍝ one of them, we'll just use the ASCII character (∆AVU is set accordingly).
                    ⍝  In APL+Win, the default value of ∆AVU will incorporate what Dyalog uses, when
                    ⍝  applicable, in order to try to be as consistent as possible.
     
 R←⎕AVU
∇

∇ R←∆MV
                    ⍝ Return "missing value"
                    ⍝
                    ⍝ Some problems with using ⎕NULL in Dyalog:
                    ⍝  ⎕DR ⎕NULL ==> DOMAIN ERROR
                    ⍝  ↑0⍴⎕NULL  ==> NONCE ERROR (makes it difficult to use in automated testing, e.g. use of ∇GenAPLData)
                    ⍝                note: ↑1⍴⎕NULL ==> ⎕NULL (no problem here)
                    ⍝
                    ⍝ You can set your own "missing value" by setting ∆mv to any homogeneous value of depth
                    ⍝ 1 or less. If it's not simple like that, it can get broken up by algorithms that
                    ⍝ inspect it and work on it recursively.
                    ⍝ -----------------------------------------------------------------------------------
 :If 0≠⎕NC'∆mv' ⋄ R←∆mv
 :Else ⋄ R←(4⍴2)⍴'MV' ⍝2+¯2*31
 :EndIf
∇

∇ R←depth ⍙APL2SOAP_Recurse data;type;dr;ch;chdr;I;B;s;A
                    ⍝ Private subroutine of APL2SOAP
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ Return:
                    ⍝  [;1] - depth (as in "depth vector", not ≡)
                    ⍝  [;2] - data
                    ⍝  [;3] - shape
                    ⍝  [;4] - array-type
                    ⍝           0 - non-"simple"
                    ⍝           1 - "simple"
                    ⍝          ¯1 - special (APL character non-vec)
                    ⍝          ¯2 - NULL (according to what ∆MV returns)
                    ⍝  [;5] - DR. If array-type is 0:
                    ⍝              ∘ The DR of all its children are the same ==> use their DR
                    ⍝                and mark 0 as the DR for each child (unless a given child
                    ⍝                has children itself that it is already representing).
                    ⍝                If all of the children are arrays, use 326.
                    ⍝              ∘ If the children do not all have the same DR, use 807.
                    ⍝             If array-type is 1 or ¯1, use the DR of the data.
                    ⍝             If array-type is ¯2, use ¯1 as the DR.
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ Special case for NULL.
 :If data≡⍙mv ⍝ (⍙mv was localized in APL2SOAP)
   R←1 5⍴depth'' 0 ¯2 ¯1 ⍝ be sure to rid ∆mv (or ⎕NULL) from the content (use '' instead of <data>)
   :Return
 :EndIf
     
 dr←⎕DR data
 s←⍴data
     
                    ⍝ ===================================================================================
                    ⍝ * APL data is considered to be a SOAP-array only if it is one of the following:
                    ⍝   ∘ nested
                    ⍝   ∘ numeric non-scalar
                    ⍝ * Put another way, it is NOT to be considered a SOAP-array if it is one the following:
                    ⍝   ∘ character vector
                    ⍝   ∘ numeric scalar
                    ⍝ * However, the following simply do not have a counterpart in SOAP:
                    ⍝   ∘ character data of any rank other than 1, e.g. 'A' or ⊃'this' 'that'
 :Select dr
 :CaseList 326 807 ⋄ type←0
 :CaseList 82 80 160 320 ⋄ :If 1=⍴s ⋄ type←1 ⋄ :Else ⋄ type←¯1 ⋄ :EndIf
 :Else ⋄ type←0=↑⍴s
 :EndSelect
     
                    ⍝ ===================================================================================
 :If 0=type
   :If 0∊s
                            ⍝ This is good for preserving the prototype but we want all the other attributes to remain intact.
     ch←(depth+1)⍙APL2SOAP_Recurse↑1↑0⍴data
   :Else
                            ⍝ ∇ConcatMats is faster than ↑⍪/ for large data. Using ⍪/ is especially
                            ⍝ inefficient simply because the bulk of the data that runs through
                            ⍝ ⍙APL2SOAP_Recurse is "simple" (ELSE case way down below); we could
                            ⍝ restructure everything to gather such 1-row results in a single step (big
                            ⍝ reshape). However, we seem to handle all of this more cleanly by just
                            ⍝ optimizing with ∇ConcatMats.
                            ⍝ (We could use the idiom ,/ (called "join") in Dyalog then reshape the
                            ⍝  data at the end of a cover function calling this.)
                            ⍝ch←↑⍪/(depth+1) ⍙APL2SOAP_Recurse¨ ,data
     ch←ConcatMats(depth+1)⍙APL2SOAP_Recurse¨,data
   :EndIf
     
   B←ch[;1]=depth+1 ⍝ where the direct children are (there can be other descendants here, of course)
   I←WHERE B
   :If 0∧.=ch[I;4]
     dr←326 ⍝ use this DR to show that all of the children are also "arrays"
     ch[WHERE B∧0≠ch[;4];5]←0
   :ElseIf A∧.=chdr←↑A←ch[I;5]
     dr←chdr ⍝ inherit the DR that is the same as all of the children
     ch[WHERE B∧0≠ch[;4];5]←0
   :Else
     dr←807 ⍝ use this DR to show that the children are of varying datatypes (even though Dyalog doesn't actually have 807)
   :EndIf
     
   R←depth''s type dr⍪ch ⍝ (might as well use '' as the spaceholder since it is appropriate for the final result in the calling function)
     
 :Else
   R←1 5⍴depth data s type dr
     
 :EndIf
∇

∇ R←larg ⍙DecodeMethod xml;noCheckArray;decoding;mls;D;api;type;methods;B;J;I;A;method;mpvm;envns
                             ⍝ Private subroutine of DecodeRequest and DecodeResponse - Decode a SOAP-XML method/data
                             ⍝ -----------------------------------------------------------------------------------
                             ⍝ SYNTAX:   R←decoding noCheckArray ⍙DecodeMethod xml
                             ⍝
                             ⍝ ARGS/RESULT:
                             ⍝  xml         - SOAP-XML that is intended as a complete method-call
                             ⍝  decoding    - applies when the XML yields an MLS (as opposed to arbitary APL data)
                             ⍝                This is the type of decoding to perform. Default: 1
                             ⍝                  0  - no decoding. Just form an MLS without applying any data
                             ⍝                       transformations.
                             ⍝                  1  - expect datatype tagging for each element (except containers)
                             ⍝                       and transform them to their APL equivalent. For a given element,
                             ⍝                       if its PVM contains a value for 'xsi:type' that does not
                             ⍝                       transform to an APL datatype, then that attribute/value pair
                             ⍝                       is preserved in the MLS and the data/content is not affected.
                             ⍝                 [api][type] - expect no datatype tagging; apply data transformations
                             ⍝                               according to the passed API:
                             ⍝                  api  - associated API for any method that may be passed in <xml>.
                             ⍝                         This API follows the format described in API2WSDL.
                             ⍝                  type - 0-request, 1-response. Note, this only needs to be passed
                             ⍝                         to determine which element to pick from the relevant
                             ⍝                         method's api-structure.
                             ⍝                Note that regardless of what value is passed for <decoding>, any
                             ⍝                arbitrary APL data found in content is appropriately transformed.
                             ⍝  noCheckArray - When not passed or set to 0, run the SOAP data through SOAP2Data
                             ⍝                 in order to determine whether the data is a SOAP array (intended
                             ⍝                 as some arbitrary APL) or it is some arbitrary XML (intended as an
                             ⍝                 MLS). It can generally be determined if the data is for conversion
                             ⍝                 to arbitrary APL (should be run through SOAP2APL) by seeing if the
                             ⍝                 top-level element attribute 'xsi:type' is set to 'SOAP-ENC:Array'.
                             ⍝                 However, the following is not a SOAP array and you may or may not
                             ⍝                 want it to be slated for conversion to APL.
                             ⍝                  <a xsi:type="xsd:int">120</a> ⍝ (can get this by running: MLS2XML APL2SOAP 120)
                             ⍝                 Hence, the reason for needing this argument.
                             ⍝  R           - [1] - success boolean
                             ⍝                [2] - if success (R[1]=1):
                             ⍝                        [1] - name of the method
                             ⍝                        [2] - data for the method (as its argument or as its result)
                             ⍝                        [3] - PVM for the attributes applied to the method,
                             ⍝                              e.g. <MyMethod xmlns="..."> ==> 1 2⍴'xmlns' '...'
                             ⍝                      if failure (R[1]=0):
                             ⍝                       3-element vector describing a SOAP Fault (see SOAPFault)
                             ⍝
                             ⍝ SUBFNS:   APLType XML2MLS Descendants SOAP2Data SOAP2APL
                             ⍝ -----------------------------------------------------------------------------------
 (decoding noCheckArray)←larg
     
 :Trap 0
   mls←3 1 XML2MLS xml
 :Else
   I←1 ⋄ :GoTo ∆invalid
 :EndTrap
     
                             ⍝ The only child of the body is the function name element. The children of the
                             ⍝ the function name element make up the argument to the function (I don't think
                             ⍝ there are rows in the MLS beyond those children but we'll use Descendants
                             ⍝ to be safe).
     
 :If 0∊⍴envns←(<\mls[;2]EndsWith¨⊂':Envelope')/mls[;2] ⍝ find the Envelope tag
   I←4 ⋄ :GoTo ∆invalid
 :Else
   envns←↑envns
   envns←(envns⍳':')↑envns ⍝ grab the namespace name
 :EndIf
     
 :If (↑⍴mls)<I←mls[;2]⍳⊂envns,'Body'
   I←2 ⋄ :GoTo ∆invalid
 :ElseIf (↑⍴mls)<I←I+1
   I←3 ⋄ :GoTo ∆invalid
 :EndIf
     
 (method mpvm)←mls[I;2 4]
     
 :If (⍴method)≥J←method⍳':' ⋄ :AndIf ~(envns,'FAULT')≡NoCase method ⋄ method←J↓method ⋄ :EndIf
     
 D←I Descendants mls[;1]
     
 :If 1<≡decoding
                                 ⍝ Pluck out just this method's request-MLS or its response-MLS.
   (api type)←decoding
   methods←1⊃¨api
   :If 1∊B←2=∊⍴¨⍴¨methods ⋄ (B/methods)←(⊂⊂1 2)⊃¨B/methods ⋄ :EndIf
   :If 0=type ⋄ A←method ⋄ :Else ⋄ A←¯8↓method ⋄ :EndIf ⍝ if a response, have to drop trailing 'Response'
   :If (⍴methods)≥J←methods⍳⊂A ⋄ decoding←(J,2+type)⊃api
   :Else ⋄ decoding←0 4⍴0
   :EndIf
 :EndIf
     
 :If 0≠⍴D
   mls←mls[D;]
   B←1
     
                             ⍝ Since there are no subelements, the function call either has a simple value as
                             ⍝ its argument (in its content) or no argument at all. (I'm not even sure if a
                             ⍝ function can have content by itself but we'll allow it).
 :ElseIf ''≡3⊃mls[I;]
   R←''
   B←0
     
 :Else
   mls←mls[,I;]
   B←1
     
 :EndIf
     
 :If B
   :If noCheckArray
     R←SOAP2APL mls
   :Else
     (B R)←decoding SOAP2Data mls
     :If ~B ⋄ I←5 ⋄ :GoTo ∆invalid ⋄ :EndIf
   :EndIf
 :EndIf
     
     
 R←1(method R mpvm)
     
                             ⍝ ===================================================================================
 :Return
∆invalid:
 :Select I
 :Case 1 ⋄ R←'The SOAP-XML is invalid.'
 :Case 2 ⋄ R←'The body (:Body) element is missing.'
 :Case 3 ⋄ R←'The procedure call element is missing.'
 :Case 4 ⋄ R←'The Envelope (:Envelope) element is missing.'
 :Case 5 ⋄ R←'Input data validation error.'
 :EndSelect
 R←0('Client.Invalid'R'')
∇

∇ R←larg ⍙EncodeMethod rarg;etag;stag;methoddata;mls;B;I;isMLS;methods;xmlencoding;encoding;api;type;method;A;methodpvm
                    ⍝ Private subroutine of EncodeRequest and EncodeResponse - Encode method/data as SOAP-XML
                    ⍝ -----------------------------------------------------------------------------------
                    ⍝ SYNTAX:   R←isMLS encoding xmlencoding ⍙EncodeMethod method methoddata methodpvm
                    ⍝
                    ⍝ ARGS/RESULT:
                    ⍝  method      - name of the method
                    ⍝  methoddata  - data for the method (as its argument or as its result)
                    ⍝  methodpvm   - PVM to apply to the method element (for a response, this is usually
                    ⍝                just the same as that passed in the original SOAP request)
                    ⍝  isMLS       - whether <methoddata> is intended to be an MLS (see <isMLS> in Data2SOAP).
                    ⍝  encoding    - This is applicable when <isMLS> is 1.
                    ⍝                  0  - do not apply any datatype tagging to any elements (presumably
                    ⍝                       the receiving end will know how to work it out based on the
                    ⍝                       API or WSDL)
                    ⍝                  1  - apply datatype tagging to each element according to its APL
                    ⍝                       datatype. However, for a given element, if its PVM contains the
                    ⍝                       attribute 'xsi:type', then its value is preserved (it's not
                    ⍝                       overwritten with the mapped APL datatype).
                    ⍝                 [api][type] - apply datatype tagging according to the passed API:
                    ⍝                  api  - associated API for any method that may be passed in rarg.
                    ⍝                         This API follows the format described in API2WSDL.
                    ⍝                  type - 0-request, 1-response. Note, this only needs to be passed
                    ⍝                         to determine which element to pick from the relevant
                    ⍝                         method's api-structure.
                    ⍝                Observation: If all of the elements' datatypes are native to APL,
                    ⍝                then the 3rd format for <encoding> will yield the same result as
                    ⍝                <encoding>=1. It can be quite advantageous to use an API since the
                    ⍝                application-developer can create new datatypes, e.g. a date (as an
                    ⍝                APL string), and it will get "transformed" by virtue of getting tagged
                    ⍝                with a valid SOAP datatype that means something to a consumer of the
                    ⍝                SOAP. Of course, the application-developer can add the tag himself
                    ⍝                (in the PVM) when constructing his MLS, but it is more elegant to not
                    ⍝                have to worry about that and just let the "machinery" handle such details.
                    ⍝  xmlencoding - see MLS2XML <encoding>. Default: 'UTF-8'
                    ⍝  R           - SOAP-XML that is suitable for the body an HTTP request/response
                    ⍝
                    ⍝ SUBFNS:   APLType WHERE Data2SOAP MLS2XML
                    ⍝ -----------------------------------------------------------------------------------
     
 :If (⎕DR rarg)∊82 80 160 320
   method←rarg
   methoddata←''
   methodpvm←0 2⍴⊂''
 :ElseIf 1=×/⍴rarg
   method←∊rarg
   methoddata←''
   methodpvm←0 2⍴⊂''
 :Else
   (method methoddata methodpvm)←3↑rarg,⊂0 2⍴⊂''
   (isMLS encoding xmlencoding)←larg
     
   :If 1<≡encoding
                            ⍝ Pluck out just this method's request-MLS or its response-MLS.
     (api type)←encoding
     methods←1⊃¨api
     :If 1∊B←2=∊⍴¨⍴¨methods ⋄ (B/methods)←(⊂⊂1 2)⊃¨B/methods ⋄ :EndIf
     :If 0=type ⋄ A←method ⋄ :Else ⋄ A←¯8↓method ⋄ :EndIf ⍝ if a response, have to drop trailing 'Response'
     :If (⍴methods)≥I←methods⍳⊂A ⋄ encoding←(I,2+type)⊃api
     :Else ⋄ encoding←0 4⍴0
     :EndIf
   :EndIf
     
   mls←isMLS encoding Data2SOAP methoddata
     
                        ⍝ Convert real negative numbers to charvecs so that we can use the hyphen/minus
                        ⍝ character instead of the high-minus sign. It may be the case that some character
                        ⍝ conversion is performed on the result of this and it takes care of that conversion
                        ⍝ but we shouldn't depend on that.
   B←(⎕DR¨mls[;3])∊83 163 323 645
                        ⍝ We thought about using the following instead but it doesn't take care of
                        ⍝ changing '¯' for the ∆MV when it returns the typical ∆mv instead of ⎕NULL. We
                        ⍝ really should never have a SOAP-MLS carry ∆MV (∆mv or ⎕NULL) in it at all now
                        ⍝ that we're using SOAP 'null' attributes to properly describe it.
                        ⍝B←323=∆DT¨ mls[;3]
   :If 1∊B
     I←WHERE B
     mls[I;3]←⍕¨mls[I;3]
     mls[I;3]←{res←⍵ ⋄ ((res='¯')/res)←'-' ⋄ res}¨mls[I;3]
   :EndIf
     
   methoddata←xmlencoding MLS2XML mls
     
 :EndIf
     
                    ⍝ Be sure to at least accommodate attribute/value pairs since they "could" follow
                    ⍝ the method name (passed and not being placed in the methodpvm).
 I←¯1+method⍳' '
 etag←I↑method
 stag←etag,I↓method
     
 :If 0≠↑⍴methodpvm ⋄ stag←stag,¯5↓2↓MLS2XML 1 4⍴1 'a' ''methodpvm ⋄ :EndIf
     
 R←'<?xml version="1.0"?><SOAP-ENV:Envelope SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
 R←R,'<SOAP-ENV:Body><',stag,'>'
 R←R,methoddata
 R←R,'</',etag,'></SOAP-ENV:Body></SOAP-ENV:Envelope>'
∇

∇ R←larg ⍙SOAP2APL_Recurse rarg;A;I;J;pvm;shape;type;type_parent;B
                    ⍝ Private subroutine of SOAP2APL
                    ⍝ -----------------------------------------------------------------------------------
 (I type_parent)←larg
 (R pvm)←rarg
     
                    ⍝ Determine the type.
 :If (↑⍴pvm)≥J←⌊/pvm[;1]⍳'xsi:type' 'type' ⍝ is there a datatype specified for this element?
   type←(⊂J 2)⊃pvm
 :ElseIf (↑⍴pvm)≥J←pvm[;1]⍳⊂'xsi:null' ⋄ :AndIf (,'1')≡⍕(⊂J 2)⊃pvm ⍝ null specified? (check this before checking on parent)
   type←'null'
 :Else
   type←type_parent ⍝ perhaps our parent contains the datatype?
 :EndIf
 :If (⍴type)≥J←type⍳':' ⋄ type←J↓type ⋄ :EndIf
     
 :Select type
 :CaseList 'int' 'float' 'double' 'boolean'
   :If (⎕DR R)∊82 80 160 320
     :If ''≡R ⍝ (this really shouldn't be allowed since null should have been used instead)
       R←∆MV
     :Else
       :If R[1]='-' ⋄ R[1]←'¯' ⋄ :EndIf
       R←2 1⊃⎕VFI R
     :EndIf
   :EndIf
 :Case 'Array' ⍝ (was 'SOAP-ENC:Array')
                        ⍝ Get the shape, if any.  Also, get the parent's datatype in case we need
                        ⍝ it. We'll use the parent datatype in the next call (recursive) if a given
                        ⍝ child doesn't have its own datatype specified.
   J←((-⍴A)↑¨pvm[;1])⍳⊂A←':arrayType' ⍝ (e.g. property is 'SOAP-ENC:arrayType')
   :If B←(↑⍴pvm)≥J
     type_parent←2⊃pvm[J;]
     J←¯1+type_parent⍳'['
     shape←J↓type_parent ⍝ pick this up before we start modifying <type_parent>
     type_parent←J↑type_parent
     :If 'ur-type'≡type_parent
                                ⍝ 'ur-type' means the types for the children are mixed and should
                                ⍝ therefore be specified. Assign parent type to '' to nullify
                                ⍝ utilizing it in the next call.
       type_parent←''
     :EndIf
   :ElseIf (↑⍴pvm)≥J←pvm[;1]⍳⊂'xsi:null' ⋄ :AndIf (,'1')≡⍕(⊂J 2)⊃pvm ⍝ e.g. pvm is ⊃('xsi:type' 'SOAP-ENC:Array')('xsi:null' 1)
     type_parent←'null'
   :Else
     type_parent←''
   :EndIf
     
   I←I Children ⍙depths
   R←(I,¨⊂⊂type_parent)⍙SOAP2APL_Recurse¨⍙info[I]
     
                        ⍝ If there was a shape specified, respect it.
   :If B
     ((shape∊',[]')/shape)←' '
                              ⍝((shape∊'[]')/shape)←' '
     shape←2⊃⎕VFI shape
     R←shape⍴R
   :EndIf
     
 :Case 'string'
   :If (↑⍴pvm)≥J←pvm[;1]⍳⊂'APL-ENC:shape'
     shape←2⊃pvm[J;]
     shape←2⊃⎕VFI shape
     R←shape⍴R
   :EndIf
     
 :Case 'null' ⍝ comes from 1 2⍴'xsi:null' 1 or from 1 2⍴'SOAP-ENC:arrayType' 'xsd:null[S...]'
   R←∆MV
     
                    ⍝:ELSE ⍝ anything unrecognized ==> no-op; leave <R> alone
     
 :EndSelect
∇

 NoCase←{(TOUP ⍺)⍺⍺ TOUP ⍵}


:EndNamespace 