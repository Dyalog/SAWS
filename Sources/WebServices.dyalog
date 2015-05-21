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
:EndNamespace 