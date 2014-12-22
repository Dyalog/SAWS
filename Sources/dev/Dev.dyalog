 Dev;z
 z←{(-⌊/(⌽⍵)⍳'\/')↓⍵}⎕WSID
 ⎕←'      )clear'
 ⎕←'      ]load "',z,'/sources/dev/*"'
 ⎕←'      )wsid "',z,'/dev.dws"'
 ⎕←'      ⎕LX←''Load'''
 ⎕←'      )save'