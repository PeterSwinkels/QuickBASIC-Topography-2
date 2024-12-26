DEFINT A-Z

TYPE LocationStr
 NameV AS STRING * 40
 TypeV AS INTEGER
 x AS INTEGER
 y AS INTEGER
 Plural AS INTEGER
END TYPE

TYPE RegistersStr
 ax    AS INTEGER
 bx    AS INTEGER
 cx    AS INTEGER
 dx    AS INTEGER
 ps    AS INTEGER
 si    AS INTEGER
 di    AS INTEGER
 flags AS INTEGER
END TYPE

CONST MAPX = 25
CONST MAPY = 35

DECLARE FUNCTION AnswerIsCorrect (Location() AS LocationStr, Location AS INTEGER, CursorX AS INTEGER, CursorY AS INTEGER)
DECLARE FUNCTION LoadLocations (Location() AS LocationStr, RegionFile AS STRING)
DECLARE FUNCTION SelectLocation (Location() AS LocationStr, LocationCount AS INTEGER)
DECLARE FUNCTION SelectRegion$ ()
DECLARE SUB Center (x, Text AS STRING)
DECLARE SUB DisplayLocations (Location() AS LocationStr, LocationCount AS INTEGER)
DECLARE SUB DisplayMap (MapFile AS STRING)
DECLARE SUB DisplayPrompt (Prompt AS STRING)
DECLARE SUB DisplayStatusBar (Right AS INTEGER, Wrong AS INTEGER, Turn AS INTEGER)
DECLARE SUB DisplayTitle ()
DECLARE SUB GetMouseStatus (Buttons AS INTEGER, CursorX AS INTEGER, CursorY AS INTEGER)
DECLARE SUB Initialize ()
DECLARE SUB INTERRUPT (InterruptN AS INTEGER, RegInp AS RegistersStr, RegOut AS RegistersStr)
DECLARE SUB LoadMap ()
DECLARE SUB LoadRegions (RegionFile() AS STRING, RegionName() AS STRING)
DECLARE SUB Main (RegionFile AS STRING)
DECLARE SUB MouseButtonWait (Status AS INTEGER)
DECLARE SUB Quit ()
DECLARE SUB SetMouseBorders (x1 AS INTEGER, y1 AS INTEGER, x2 AS INTEGER, y2 AS INTEGER)
ON ERROR GOTO ErrorTrap
DIM Background(0 TO 9293) AS INTEGER
DIM ErrorCode AS INTEGER
DIM KeyStroke AS STRING

 Initialize
 DisplayTitle

 DO
  CALL Main(SelectRegion)
 LOOP

ErrorTrap:
 GET (120, 54)-STEP(360, 100), Background
 COLOR 15
 LOCATE 5
 ErrorCode = ERR
 SELECT CASE ErrorCode
  CASE 7, 14
   Center 0, "Not enough memory."
  CASE 53
   Center 0, "Cannot find file."
  CASE 71
   Center 0, "No disk in drive. "
  CASE 72
   Center 0, "Disk is damaged."
  CASE ELSE
   Center 0, "Unexpected error."
 END SELECT
 COLOR 7
 Center 0, "Enter = Retry   Escape = Quit"
 DO
  KeyStroke = INPUT$(1)
  SELECT CASE KeyStroke
   CASE CHR$(13)
    PUT (120, 54), Background, PSET
    RESUME
   CASE CHR$(27)
    Quit
  END SELECT
 LOOP

FUNCTION AnswerIsCorrect (Location() AS LocationStr, SelectedLocation AS INTEGER, CursorX AS INTEGER, CursorY AS INTEGER)
DIM Background(0 TO 65) AS INTEGER
DIM Correct AS INTEGER
DIM Prompt AS STRING

 IF CursorX >= Location(SelectedLocation).x - 5 AND CursorY >= Location(SelectedLocation).y - 5 AND CursorX <= Location(SelectedLocation).x + 5 AND CursorY <= Location(SelectedLocation).y + 5 THEN
  Correct = -1
  MouseButtonWait 0
 ELSE
  Correct = 0
  SOUND 37, 3
  GET (MAPX + Location(SelectedLocation).x - 5, MAPY + Location(SelectedLocation).y - 12)-STEP(15, 15), Background
  DRAW "BM" + STR$(MAPX + Location(SelectedLocation).x) + "," + STR$(MAPY + Location(SelectedLocation).y - 5) + "C15 D8 R8 H3 E5 H2 G5 H3 D5 BR2 P15,15"
  IF Location(SelectedLocation).Plural THEN
   Prompt = "Those are"
  ELSE
   Prompt = "That is"
  END IF
  Prompt = Prompt + " " + RTRIM$(Location(SelectedLocation).NameV) + "."
  DisplayPrompt Prompt
  MouseButtonWait 0
  MouseButtonWait 1
  DisplayPrompt ""
  PUT (MAPX + Location(SelectedLocation).x - 5, MAPY + Location(SelectedLocation).y - 12), Background, PSET
  MouseButtonWait 0
 END IF

 AnswerIsCorrect = Correct
END FUNCTION

SUB Center (x, Text AS STRING)
 IF x > 0 THEN LOCATE x
 LOCATE , INT(40 - (LEN(Text) / 2))
 PRINT Text
END SUB

SUB DisplayLocations (Location() AS LocationStr, LocationCount AS INTEGER)
DIM Index AS INTEGER
 
 FOR Index = 0 TO LocationCount - 1
  SELECT CASE Location(Index).TypeV
   CASE 1
    CIRCLE (MAPX + Location(Index).x, MAPY + Location(Index).y), 3, 4
    PAINT (MAPX + Location(Index).x, MAPY + Location(Index).y), 4
   CASE 2
    DRAW "BM" + STR$(MAPX + Location(Index).x) + "," + STR$(MAPY + Location(Index).y) + "C6 BU5 G10 R20 H10 BD2 P6,6"
   CASE 3
    CIRCLE (MAPX + Location(Index).x, MAPY + Location(Index).y), 3, 1
    PAINT (MAPX + Location(Index).x, MAPY + Location(Index).y), 1
   CASE 4
    DRAW "BM" + STR$(MAPX + Location(Index).x) + "," + STR$(MAPY + Location(Index).y) + "C12 BU5 G10 R20 H10 BD2 P12,12"
  END SELECT
 NEXT Index
END SUB

SUB DisplayMap (MapFile AS STRING)
DIM Image(0 TO 31999) AS INTEGER

 DEF SEG = VARSEG(Image(0))
 BLOAD MapFile + ".img", VARPTR(Image(0))
 LINE (MAPX + 1, MAPY + 1)-STEP(Image(0), Image(1)), 8, BF
 PUT (MAPX, MAPY), Image, PSET
END SUB

SUB DisplayPrompt (Prompt AS STRING)
 LOCATE 27, 1
 PRINT SPACE$(80);
 COLOR 15
 LOCATE 27, 11
 PRINT Prompt
END SUB

SUB DisplayStatusBar (Right AS INTEGER, Wrong AS INTEGER, Turn AS INTEGER)
 COLOR 9
 LOCATE 1, 5
 PRINT USING "Right: ##   Wrong: ##   Turns left: ### "; Right; Wrong; Turn
 COLOR 7
 LOCATE , 1: PRINT STRING$(80, "Ä");
END SUB

SUB DisplayTitle ()
DIM FileH AS INTEGER
DIM Row AS STRING

 COLOR 15
 PRINT

 FileH = FREEFILE
 OPEN "Title.dat" FOR INPUT LOCK READ WRITE AS FileH
  DO UNTIL EOF(FileH)
   LINE INPUT #FileH, Row
   PRINT Row
  LOOP
 CLOSE FileH

 COLOR 7
 PRINT
 Center 0, "   Topography 2   "
 Center 0, "   Version 2.13   "
 Center 0, "By: Peter Swinkels"
 Center 0, "    ***1997***    "
 COLOR 9
 PRINT
 Center 0, "Press a key to continue."

 DO: LOOP WHILE INKEY$ = ""
END SUB

SUB GetMouseStatus (Buttons AS INTEGER, CursorX AS INTEGER, CursorY AS INTEGER)
DIM Registers AS RegistersStr

 Registers.ax = 1
 INTERRUPT &H33, Registers, Registers
 Registers.ax = 3
 INTERRUPT &H33, Registers, Registers
 Buttons = Registers.bx
 CursorX = Registers.cx
 CursorY = Registers.dx
END SUB

SUB Initialize ()
 RANDOMIZE TIMER
 SCREEN 12
 WIDTH 80, 30
 COLOR 15
 CLS
 SetMouseBorders 0, 0, 639, 479
END SUB

FUNCTION LoadLocations (Location() AS LocationStr, RegionFile AS STRING)
DIM FileH AS INTEGER
DIM Index AS INTEGER
DIM LocationCount AS INTEGER
DIM LocationType AS INTEGER

 LocationCount = 0
 FileH = FREEFILE
 OPEN RegionFile + ".dat" FOR INPUT LOCK READ WRITE AS FileH
  FOR Index = LBOUND(Location) TO UBOUND(Location)
   IF EOF(FileH) THEN EXIT FOR
   INPUT #FileH, Location(Index).NameV, Location(Index).x, Location(Index).y, Location(Index).TypeV, Location(Index).Plural
   LocationCount = LocationCount + 1
  NEXT Index
 CLOSE FileH

 LoadLocations = LocationCount
END FUNCTION

SUB LoadRegions (RegionFile() AS STRING, RegionName() AS STRING)
DIM FileH AS INTEGER
DIM Index AS INTEGER

 FileH = FREEFILE
 OPEN "Regions.dat" FOR INPUT LOCK READ WRITE AS FileH
  FOR Index = LBOUND(RegionName) TO UBOUND(RegionName)
   INPUT #FileH, RegionName(Index), RegionFile(Index)
  NEXT Index
 CLOSE FileH
END SUB

SUB Main (RegionFile AS STRING)
DIM Buttons AS INTEGER
DIM CursorX AS INTEGER
DIM CursorY AS INTEGER
DIM Location(0 TO 28) AS LocationStr
DIM LocationCount AS INTEGER
DIM Registers AS RegistersStr
DIM Right AS INTEGER
DIM SelectedLocation AS INTEGER
DIM Turn AS INTEGER
DIM Wrong AS INTEGER

 Turn = 25
 Right = 0
 Wrong = 0

 CLS

 DisplayMap RegionFile
 LocationCount = LoadLocations(Location(), RegionFile)
 DisplayLocations Location(), LocationCount

 SelectedLocation = SelectLocation(Location(), LocationCount)
 DO UNTIL INKEY$ = CHR$(27)
  DisplayStatusBar Right, Wrong, Turn
  IF Turn = 0 THEN
   EXIT DO
  ELSE
   GetMouseStatus Buttons, CursorX, CursorY
   IF Buttons = 1 THEN
    IF AnswerIsCorrect(Location(), SelectedLocation, CursorX - MAPX, CursorY - MAPY) THEN
     Right = Right + 1
    ELSE
     Wrong = Wrong + 1
    END IF
    Turn = Turn - 1
    SelectedLocation = SelectLocation(Location(), LocationCount)
   END IF
  END IF
 LOOP
 
 Registers.ax = 2
 INTERRUPT &H33, Registers, Registers

 DisplayPrompt "Press any key to continue..."

 DO: LOOP WHILE INKEY$ = ""
END SUB

SUB MouseButtonWait (Status AS INTEGER)
DIM Buttons AS INTEGER
DIM Registers AS RegistersStr

 DO
  Registers.ax = 3
  INTERRUPT &H33, Registers, Registers
  Buttons = Registers.bx
 LOOP UNTIL Buttons = Status
END SUB

SUB Quit ()
 SCREEN 0
 WIDTH 80, 25
 COLOR 7, 0
 CLS
 SYSTEM
END SUB

FUNCTION SelectLocation (Location() AS LocationStr, LocationCount AS INTEGER)
DIM Prompt AS STRING
DIM Selected AS INTEGER

 Selected = INT(RND * LocationCount)
 Prompt = "Point out where " + RTRIM$(Location(Selected).NameV) + " "

 IF Location(Selected).Plural THEN
  Prompt = Prompt + "are"
 ELSE
  Prompt = Prompt + "is"
 END IF

 DisplayPrompt Prompt + "."

 SelectLocation = Selected
END FUNCTION

FUNCTION SelectRegion$ ()
DIM Background(0 TO 783) AS INTEGER
DIM CursorY AS INTEGER
DIM Index AS INTEGER
DIM KeyStroke AS STRING
DIM RegionFile(0 TO 6) AS STRING
DIM RegionName(0 TO 6) AS STRING
DIM SelectedRegion AS INTEGER

 LoadRegions RegionFile(), RegionName()

 CursorY = 64
 SelectedRegion = 0

 CLS
 COLOR 7
 Center 1, "Select a region."
 COLOR 15
 PRINT STRING$(80, "Ä");
 COLOR 9
 LOCATE 5
 FOR Index = LBOUND(RegionName) TO UBOUND(RegionName)
  LOCATE , 10: PRINT RegionName(Index)
  PRINT
 NEXT Index
 LOCATE 19, 10
 PRINT "Quit"

 DO
  GET (64, CursorY)-STEP(176, 16), Background
  PUT (64, CursorY), Background, PRESET
  DO
   KeyStroke = INKEY$
  LOOP WHILE KeyStroke = ""
  PUT (64, CursorY), Background, PSET
  SELECT CASE KeyStroke
   CASE CHR$(0) + "H"
    IF NOT CursorY = 64 THEN
     CursorY = CursorY - 32
     SelectedRegion = SelectedRegion - 1
    END IF
   CASE CHR$(0) + "P"
    IF NOT CursorY = 288 THEN
     CursorY = CursorY + 32
     SelectedRegion = SelectedRegion + 1
    END IF
   CASE CHR$(13)
    IF SelectedRegion = 7 THEN
     Quit
    ELSE
     EXIT DO
    END IF
  END SELECT
 LOOP

 SelectRegion = RegionFile(SelectedRegion)
END FUNCTION

SUB SetMouseBorders (x1, y1, x2, y2)
DIM Registers AS RegistersStr

 Registers.ax = 7
 Registers.cx = x1
 Registers.dx = x2
 INTERRUPT &H33, Registers, Registers
 Registers.ax = 8
 Registers.cx = y1
 Registers.dx = y2
 INTERRUPT &H33, Registers, Registers
END SUB

