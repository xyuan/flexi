#!MC 1400
# Created by Tecplot 360 build 14.0.2.35002
$!VarSet |MFBD|   = 'FIGIPATH'
$!VarSet |MYCASE| = 'FIGICASE'
$!VarSet |MYR|    = 'FIGIR'
$!DRAWGRAPHICS FALSE
$!READDATASET  'FIGIFILES'
  READDATAOPTION = NEW
  RESETSTYLE = YES
  INCLUDETEXT = NO
  INCLUDEGEOM = NO
  INCLUDECUSTOMLABELS = NO
  VARLOADMODE = BYNAME
  ASSIGNSTRANDIDS = YES
  INITIALPLOTTYPE = CARTESIAN3D
  VARNAMELIST = '"CoordinateX" "CoordinateY" "CoordinateZ" "Density" "MomentumX" "MomentumY" "MomentumZ" "EnergyStagnationDensity"'

# Compute sone derived quantities
$!ALTERDATA 
  EQUATION = '{VelocityX}={MomentumX}/{Density}'
$!ALTERDATA 
  EQUATION = '{VelocityY}={MomentumY}/{Density}'
$!ALTERDATA 
  EQUATION = '{VelocityZ}={MomentumZ}/{Density}'
$!ALTERDATA 
  EQUATION = '{VelocityMagnitude}=sqrt({VelocityX}*{VelocityX} + {VelocityY}*{VelocityY}+{VelocityZ}*{VelocityZ})'
$!ALTERDATA 
  EQUATION = '{Pressure}=0.4*({EnergyStagnationDensity}-{Density}*{VelocityMagnitude}*{VelocityMagnitude}*0.5)'
$!ALTERDATA 
  EQUATION = '{VelocitySound}=sqrt(1.4*{Pressure}/{Density})'
$!ALTERDATA 
  EQUATION = '{Mach}={VelocityMagnitude}/{VelocitySound}'
$!ALTERDATA 
  EQUATION = '{Temperature}={Pressure}/{Density}/|MYR|'

# Perform integration
$!EXTENDEDCOMMAND 
  COMMANDPROCESSORID = 'CFDAnalyzer4'
  COMMAND = 'Integrate VariableOption=\'Average\' XOrigin=0 YOrigin=0 ZOrigin=0 ScalarVar=9 Absolute=\'F\' ExcludeBlanked=\'F\' XVariable=1 YVariable=2 ZVariable=3 IntegrateOver=\'Cells\' IntegrateBy=\'Zones\' IRange={MIN =1 MAX = 0 SKIP = 1} JRange={MIN =1 MAX = 0 SKIP = 1} KRange={MIN =1 MAX = 0 SKIP = 1} PlotResults=\'F\' PlotAs=\'Result\' TimeMin=0 TimeMax=0'
$!VARSET |VELAVG|=|$INTEGRATION_TOTAL|
$!EXTENDEDCOMMAND 
  COMMANDPROCESSORID = 'CFDAnalyzer4'
  COMMAND = 'Integrate VariableOption=\'Average\' XOrigin=0 YOrigin=0 ZOrigin=0 ScalarVar=4 Absolute=\'F\' ExcludeBlanked=\'F\' XVariable=1 YVariable=2 ZVariable=3 IntegrateOver=\'Cells\' IntegrateBy=\'Zones\' IRange={MIN =1 MAX = 0 SKIP = 1} JRange={MIN =1 MAX = 0 SKIP = 1} KRange={MIN =1 MAX = 0 SKIP = 1} PlotResults=\'F\' PlotAs=\'Result\' TimeMin=0 TimeMax=0'
$!VARSET |DENSAVG|=|$INTEGRATION_TOTAL|

$!ALTERDATA 
  EQUATION = '{u/u<sub>b</sub>}={VelocityX}/|VELAVG|'
$!ALTERDATA 
  EQUATION = '{<greek>r</greek>/<greek>r</greek><sub>b</sub>}={Density}/|DENSAVG|'
$!ALTERDATA 
  EQUATION = '{x/L}={CoordinateX}/|MAXVAR[1]|'
$!ALTERDATA 
  EQUATION = '{y/h}={CoordinateY}/|MAXVAR[2]|'

# Extract points
$!VarSet |ZPOS| = (|MAXVAR[3]|*0.1)

$!VarSet |XPOS| = (|MAXVAR[1]|*0.1)
$!EXTRACTFROMPOLYLINE 
  EXTRACTTHROUGHVOLUME = YES
  EXTRACTLINEPOINTSONLY = NO
  INCLUDEDISTANCEVAR = NO
  NUMPTS = 100
  EXTRACTTOFILE = YES
  FNAME = '|MFBD|/MICROCHANNEL_|MYCASE|_1.dat'
  RAWDATA
2
|XPOS| |MAXVAR[2]| |ZPOS|
|XPOS| |MINVAR[2]| |ZPOS|
$!PICK SETMOUSEMODE
  MOUSEMODE = SELECT
$!RemoveVar |XPOS|


$!VarSet |XPOS| = (|MAXVAR[1]|*0.2)
$!EXTRACTFROMPOLYLINE 
  EXTRACTTHROUGHVOLUME = YES
  EXTRACTLINEPOINTSONLY = NO
  INCLUDEDISTANCEVAR = NO
  NUMPTS = 100
  EXTRACTTOFILE = YES
  FNAME = '|MFBD|/MICROCHANNEL_|MYCASE|_2.dat'
  RAWDATA
2
|XPOS| |MAXVAR[2]| |ZPOS|
|XPOS| |MINVAR[2]| |ZPOS|
$!PICK SETMOUSEMODE
  MOUSEMODE = SELECT


$!VarSet |XPOS| = (|MAXVAR[1]|*0.3)
$!EXTRACTFROMPOLYLINE 
  EXTRACTTHROUGHVOLUME = YES
  EXTRACTLINEPOINTSONLY = NO
  INCLUDEDISTANCEVAR = NO
  NUMPTS = 100
  EXTRACTTOFILE = YES
  FNAME = '|MFBD|/MICROCHANNEL_|MYCASE|_3.dat'
  RAWDATA
2
|XPOS| |MINVAR[2]| |ZPOS|
|XPOS| |MAXVAR[2]| |ZPOS|
$!PICK SETMOUSEMODE
  MOUSEMODE = SELECT

$!VarSet |XPOS| = (|MAXVAR[1]|*0.4)
$!EXTRACTFROMPOLYLINE 
  EXTRACTTHROUGHVOLUME = YES
  EXTRACTLINEPOINTSONLY = NO
  INCLUDEDISTANCEVAR = NO
  NUMPTS = 100
  EXTRACTTOFILE = YES
  FNAME = '|MFBD|/MICROCHANNEL_|MYCASE|_4.dat'
  RAWDATA
2
|XPOS| |MINVAR[2]| |ZPOS|
|XPOS| |MAXVAR[2]| |ZPOS|
$!PICK SETMOUSEMODE
  MOUSEMODE = SELECT

$!VarSet |XPOS| = (|MAXVAR[1]|*0.5)
$!EXTRACTFROMPOLYLINE 
  EXTRACTTHROUGHVOLUME = YES
  EXTRACTLINEPOINTSONLY = NO
  INCLUDEDISTANCEVAR = NO
  NUMPTS = 100
  EXTRACTTOFILE = YES
  FNAME = '|MFBD|/MICROCHANNEL_|MYCASE|_5.dat'
  RAWDATA
2
|XPOS| |MINVAR[2]| |ZPOS|
|XPOS| |MAXVAR[2]| |ZPOS|
$!PICK SETMOUSEMODE
  MOUSEMODE = SELECT

$!VarSet |XPOS| = (|MAXVAR[1]|*0.6)
$!EXTRACTFROMPOLYLINE 
  EXTRACTTHROUGHVOLUME = YES
  EXTRACTLINEPOINTSONLY = NO
  INCLUDEDISTANCEVAR = NO
  NUMPTS = 100
  EXTRACTTOFILE = YES
  FNAME = '|MFBD|/MICROCHANNEL_|MYCASE|_6.dat'
  RAWDATA
2
|XPOS| |MINVAR[2]| |ZPOS|
|XPOS| |MAXVAR[2]| |ZPOS|
$!PICK SETMOUSEMODE
  MOUSEMODE = SELECT

$!VarSet |XPOS| = (|MAXVAR[1]|*0.7)
$!EXTRACTFROMPOLYLINE 
  EXTRACTTHROUGHVOLUME = YES
  EXTRACTLINEPOINTSONLY = NO
  INCLUDEDISTANCEVAR = NO
  NUMPTS = 100
  EXTRACTTOFILE = YES
  FNAME = '|MFBD|/MICROCHANNEL_|MYCASE|_7.dat'
  RAWDATA
2
|XPOS| |MINVAR[2]| |ZPOS|
|XPOS| |MAXVAR[2]| |ZPOS|
$!PICK SETMOUSEMODE
  MOUSEMODE = SELECT

$!VarSet |XPOS| = (|MAXVAR[1]|*0.8)
$!EXTRACTFROMPOLYLINE 
  EXTRACTTHROUGHVOLUME = YES
  EXTRACTLINEPOINTSONLY = NO
  INCLUDEDISTANCEVAR = NO
  NUMPTS = 100
  EXTRACTTOFILE = YES
  FNAME = '|MFBD|/MICROCHANNEL_|MYCASE|_8.dat'
  RAWDATA
2
|XPOS| |MINVAR[2]| |ZPOS|
|XPOS| |MAXVAR[2]| |ZPOS|
$!PICK SETMOUSEMODE
  MOUSEMODE = SELECT

$!VarSet |XPOS| = (|MAXVAR[1]|*0.9)
$!EXTRACTFROMPOLYLINE 
  EXTRACTTHROUGHVOLUME = YES
  EXTRACTLINEPOINTSONLY = NO
  INCLUDEDISTANCEVAR = NO
  NUMPTS = 100
  EXTRACTTOFILE = YES
  FNAME = '|MFBD|/MICROCHANNEL_|MYCASE|_9.dat'
  RAWDATA
2
|XPOS| |MINVAR[2]| |ZPOS|
|XPOS| |MAXVAR[2]| |ZPOS|
$!PICK SETMOUSEMODE
  MOUSEMODE = SELECT

$!VarSet |XPOS| = (|MAXVAR[1]|*0.25)
$!EXTRACTFROMPOLYLINE 
  EXTRACTTHROUGHVOLUME = YES
  EXTRACTLINEPOINTSONLY = NO
  INCLUDEDISTANCEVAR = NO
  NUMPTS = 100
  EXTRACTTOFILE = YES
  FNAME = '|MFBD|/MICROCHANNEL_|MYCASE|_10.dat'
  RAWDATA
2
|XPOS| |MINVAR[2]| |ZPOS|
|XPOS| |MAXVAR[2]| |ZPOS|
$!PICK SETMOUSEMODE
  MOUSEMODE = SELECT

$!VarSet |XPOS| = (|MAXVAR[1]|*0.75)
$!EXTRACTFROMPOLYLINE 
  EXTRACTTHROUGHVOLUME = YES
  EXTRACTLINEPOINTSONLY = NO
  INCLUDEDISTANCEVAR = NO
  NUMPTS = 100
  EXTRACTTOFILE = YES
  FNAME = '|MFBD|/MICROCHANNEL_|MYCASE|_11.dat'
  RAWDATA
2
|XPOS| |MINVAR[2]| |ZPOS|
|XPOS| |MAXVAR[2]| |ZPOS|
$!PICK SETMOUSEMODE
  MOUSEMODE = SELECT

$!RemoveVar |XPOS|
$!RemoveVar |MFBD|
