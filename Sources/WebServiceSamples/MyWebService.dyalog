:Namespace MyWebService
⍝ === VARIABLES ===

NL←(⎕ucs 13 10)


⍝ === End of variables definition ===

(⎕IO ⎕ML ⎕WX)←1 3 3

∇ r←AplExec arg;expr;rslt;noatt;mls;execspace
 expr←(arg[;2]⍳⊂'Expression')⊃arg[;3],⊂'' ⍝ Extract Name from argument
 expr←expr~NL
 noatt←0 2⍴⊂''                  ⍝ We do not set any attributes
 mls←0 4⍴0
 mls⍪←1 '' ''noatt
 :If 0≠⍴expr
   'execspace'⎕NS''  ⍝ execute expression in empty namespace
   :Trap 0
     rslt←⍕'execspace'⍎expr
     rslt←⊃,/(↓rslt),¨⊂NL
     mls[1;2 3]←'Result'rslt
   :Else
     mls[1;2 3]←'Error'(1⊃⎕DM)
   :EndTrap
 :EndIf
 r←1 mls
∇

∇ api←BuildAPI;method;arg;result;single
                    ⍝ Must return the API description for the webservice
     
 api←0⍴⊂'' ⍝ initialize the API (right argument to API2WSDL and enabler of constructing datatyped args/results)
 single←{(⊃('datatype'⍵)('minimum' 1)('maximum' 1))}
     
                     ⍝ --- Regression ---
 method←1 4⍴1 'Regression' ''(1 2⍴'pattern' 2)
     
 result←arg←0 4⍴0
     
 arg⍪←1 'Data' ''(⊃('datatype' 'string')('minimum' 1)('maximum' 1))
 arg⍪←1 'Degree' ''(⊃('datatype' 'integer')('minimum' 1)('maximum' 1))
     
 result⍪←1 'RegResult' ''(1 2⍴'minimum' 0)
 result⍪←2 'Coeff0' ''(single'double')
 result⍪←2 'Coeff1' ''(single'double')
 result⍪←2 'Coeff2' ''(single'double')
 result⍪←2 'Residual' ''(single'double')
 api←api,⊂method arg result
     
                     ⍝ Describe the method for Executing an APL expression
 method←1 4⍴1 'AplExec' ''(1 2⍴'pattern' 2)
     
 arg←1 4⍴1 'Expression' ''(⊃('datatype' 'string')('minimum' 1)('maximum' 1))
     
 result←0 4⍴0
 result⍪←1 'Result' ''(⊃('datatype' 'string')('minimum' 1)('maximum' 1))
 result⍪←1 'Error' ''(⊃('datatype' 'string')('minimum' 1)('maximum' 1))
     
 api←api,⊂method arg result
∇

∇ r←Regression arg;noatt;nums;result;getarg;degree;iLN
                    ⍝ WebService Method to return statistics
     
 getarg←{(arg[;2]⍳⊂⍵)⊃arg[;3],⊂''} ⍝ Argument picker
     
 nums←tonum getarg'Data' ⍝ Extract Name from argument
 degree←⊃tonum⍕getarg'Degree'
     
 iLN←⎕NEW LinReg(nums degree)
     
 r←('Coeff0' 'Coeff1' 'Coeff2' 'Residual'),[1.5](3↑iLN.Coefficients),iLN.Residual
     
 noatt←0 2⍴⊂'' ⍝ All simple types
 result←1 4⍴1 'RegResult' ''noatt
 result⍪←2,r,⊂noatt
     
 r←1 result
∇

 tonum←{↑(//)⎕VFI ⍵}

   :Class LinReg
    ⍝ Wrap regression "DSL" as a Class

    ⍝ --- Input Data ---
      :Field Public Degree←1
      :Field Public Data←⍬
      :Field Public TempFolder←'c:\tmp\' ⍝ Where Charts will appear

    ⍝ --- Output ---
      :Field Public FX←⍬
      :Field Public Coefficients←⍬
      :Field Public Residual←0

    ⍝ --- Constructors

      ∇ LinReg0      ⍝ iLN←⎕NEW LinReg
        :Access Public
        :Implements Constructor
      ∇

      ∇ LinReg1 data
      ⍝ iLN←⎕NEW LinReg (Data [Degree])
        :Access Public
        :Implements Constructor
        :If (2=|≡data)∧2=⍴data ⋄ data Degree←data ⋄ :EndIf ⍝ Degree included?
        {}Fit data
      ∇

    ⍝ --- Public Methods ---

      ∇ r←Regress
        :Access Public Instance
        Coefficients←Degree regress Data
        FX←(⍳⍴Data)evaluate Coefficients
        Residual←residual Data-FX
      ∇

      ∇ r←Fit data
        :Access Public Instance
        Data←data ⋄ Regress ⋄ r←FX
      ∇

      ∇ r←Chart title
        :Access Public Instance
        r←title rainplot Data FX
      ∇

    ⍝ --- Private Methods ---
      avg←{+/⍵÷⍴⍵}
      residual←{avg (⍵-avg ⍵)*2}
      regress←{⍺←1 ⋄ ⍵⌹(⍳⍴⍵)∘.*0,⍳⍺}
      evaluate←{(⍺∘.*¯1+⍳⍴⍵)+.×⍵}

   :EndClass

:EndNamespace 