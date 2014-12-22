:Namespace ClientSample
(⎕IO ⎕ML ⎕WX)←1 0 3

    :Class WWWeather: 'Form'
        ⎕io ⎕ml←1

        :field Countries   ⍝ list of countries
        :field Cities      ⍝ [;1] index into Countries [;2] city name
        :field lcCountries ⍝ lower case countries (so we don't have to convert every time we do lookup)
        :field public Available←0  ⍝ used to indicate if service is available
        :field public g ⍝ grid is public so that its data can be used by calling environment

        lc←{tt←⎕AV ⋄ tt[tt⍳⎕A]←'abcdefghijklmnopqrstuvwxyz' ⋄ tt[⎕av⍳⍵]}  ⍝ lowercase
        grade←{⎕av⍋↑lc¨ ⍵} ⍝ case insensitive grade up
        match←{((⍴⍵)↑¨⍺)⍳⊂lc ⍵} ⍝ case insensitive match

        ∇ r←GetCities;method;z;data;cities;countrymask;xml;countries;ucountries
     ⍝ Get all countries/cities
     ⍝  r[1] - list of unique countries
     ⍝  r[2] - matrix of [;1] index into country list [;2] city name
⍝
⍝ See: http://www.webservicex.net/globalweather.asmx?WSDL for WSDL description
          :Access Public
          r←⍬ ⍝ initialize result
          method←'GetCitiesByCountry'
          z←'www.webserviceX.NET' 80 'globalweather.asmx'#.SAWS.Call''method('CountryName' '') ⍝ make Web Service call
          :If 0=1⊃z ⍝ ok return code?
              :If method≡2 1⊃z
                  data←,2 2⊃z
                  :If 'GetCitiesByCountryResult'≡2⊃data ⍝ got a result?
                      xml←⎕XML 3⊃data ⍝ convert the xml into APL
                      countrymask←xml[;2]≡¨⊂'Country' ⍝ find the country elements
                      countries←countrymask⌿xml[;3]
                      cities←(¯1↓0,countrymask)⌿xml[;3] ⍝ city elements follow country elements
                      ucountries←∪countries ⍝ unique countries
                      ucountries←ucountries[grade ucountries]
                      cities←(ucountries⍳countries),⍪cities
                      cities←cities[grade cities[;2];]
                      r←ucountries cities
                  :EndIf
              :EndIf
          :EndIf
        ∇

        ∇ r←GetWeatherInfo(Country City);z;method;data;xml
    ⍝ Gets Weather Information for Country/City
    ⍝ Country - country name
    ⍝ City - city name (full or partial)
    ⍝ r - [;1] element name [;2] element value
    ⍝     because data reported by this web service varies from location to location, we just return what we get
          :Access Public
          method←'GetWeather'
          z←'www.webserviceX.NET' 80 'globalweather.asmx'#.SAWS.Call''method(('CityName'City)('CountryName'Country))
          r←1 2⍴'Status' 'Could not retrieve data'
          :If 0=1⊃z ⍝ ok return code?
              :If method≡2 1⊃z ⍝ method name match?
                  data←,2 2⊃z ⍝ grab the data
                  :If 'GetWeatherResult'≡2⊃data ⍝ result?
                      :If '<?xml '≡6↑xml←3⊃data ⍝ got an xml result?
                          xml←⎕XML xml ⍝ then convert xml to APL
                          r←xml[;2 3] ⍝ return element name and text
                      :EndIf
                  :EndIf
              :EndIf
          :EndIf
        ∇

        ∇ ctor;countries;CityData
          :Access public
          :Implements constructor :base
          {}#.SAWS.Init''⍝ start SAWS/Conga
          :If 0∊⍴CityData←GetCities ⍝ get list of countries/cities
              ⎕←'Could not retrieve country/city data'
              ⎕THIS.Close
          :Else
              Available←1 ⍝ set service availability flag
              Countries Cities←CityData ⍝ call the web service to get lookup data
              lcCountries←lc¨Countries ⍝ build list of lower case country names for easier lookup
              Coord←'Pixel'
              Size←400 500
              BCol←200 200 255
              Caption←'World Wide Weather'
              l1←⎕NEW'Label'(('Posn'(25 25))('Size'(20 50))('Caption' 'Country:')('Justify' 'Right')('BCol'BCol))
              c1←⎕NEW'Combo'(('Posn'(25 85))('Size'(20 250))('Rows' 12)('Style' 'DropEdit'))
              c1.Items←Countries ⍝ first combo items
              c1.(onSelect onChange)←⊂'FilterCities'
              l2←⎕NEW'Label'(('Posn'(50 25))('Size'(20 50))('Caption' 'City:')('Justify' 'Right')('BCol'BCol))
              c2←⎕NEW'Combo'(('Posn'(50 85))('Size'(20 250))('Rows' 12)('Active' 0)('Style' 'DropEdit'))
              c2.(onChange onSelect)←⊂'GetWeather'
              g←⎕NEW'Grid'(('Posn'(85 25))('TitleWidth' 90)('CellWidths' 360)('Size'(300 450))('GridBCol'BCol)('TitleHeight' 0)('Border' 0))
              g.(e←⎕NEW'Edit'(,⊂'ReadOnly' 1))
              g.Input←'g.e'
              g.InputMode←'AlwaysInCell'
              c1.GotFocus ⍬
          :EndIf
        ∇

        ∇ FilterCities ctl;mb;ind
    ⍝ looks up country name (case insensitive) and, if found, filters list of cities for second combo box
          :If (⍴lcCountries)<ind←lcCountries match c1.Text
              mb←⎕NEW'MsgBox'(('Caption' 'Country Not Found')('Text'(c1.Text,' is not a valid country'))('Style' 'Msg'))
              {}mb.Wait
          :Else
              c1.Text←⊃Country←Countries[ind] ⍝ insert country name
              c2.Items←(Cities[;1]=ind)⌿Cities[;2] ⍝ populate second combo box's list of items
              c2.Active←1 ⍝ turn on second combo
              g.Values←0 1⍴⊂'' ⍝ clear the grid's values
          :EndIf
        ∇

        ∇ GetWeather ctl;weather
    ⍝ retrieves weather information for country/city and populates the grid
          City←c2.Text
          weather←GetWeatherInfo((⊃Country)City)
          g.Values←weather[;,2]
          g.RowTitles←weather[;1]
        ∇
    :EndClass

:EndNamespace 