!=================================================================================================================================
! Copyright (c) 2016  Prof. Claus-Dieter Munz 
! This file is part of FLEXI, a high-order accurate framework for numerically solving PDEs with discontinuous Galerkin methods.
! For more information see https://www.flexi-project.org and https://nrg.iag.uni-stuttgart.de/
!
! FLEXI is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License 
! as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
!
! FLEXI is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
! of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License v3.0 for more details.
!
! You should have received a copy of the GNU General Public License along with FLEXI. If not, see <http://www.gnu.org/licenses/>.
!=================================================================================================================================
#include "flexi.h"

!==================================================================================================================================
!> The channel case is a setup according to the Moser channel
!==================================================================================================================================
MODULE MOD_Testcase
! MODULES
USE MOD_Testcase_Vars
IMPLICIT NONE
PRIVATE
!----------------------------------------------------------------------------------------------------------------------------------
! GLOBAL VARIABLES

INTERFACE DefineParametersTestcase
  MODULE PROCEDURE DefineParametersTestcase
END INTERFACE

INTERFACE InitTestcase
  MODULE PROCEDURE InitTestcase
END INTERFACE

INTERFACE FinalizeTestcase
  MODULE PROCEDURE FinalizeTestcase
END INTERFACE

INTERFACE ExactFuncTestcase
  MODULE PROCEDURE ExactFuncTestcase
END INTERFACE

INTERFACE CalcForcing
  MODULE PROCEDURE CalcForcing
END INTERFACE

INTERFACE TestcaseSource
  MODULE PROCEDURE TestcaseSource
END INTERFACE

INTERFACE AnalyzeTestCase
  MODULE PROCEDURE AnalyzeTestCase
END INTERFACE

PUBLIC:: DefineParametersTestcase,InitTestcase,FinalizeTestcase,ExactFuncTestcase,TestcaseSource,CalcForcing,AnalyzeTestCase

CONTAINS

!==================================================================================================================================
!> Define parameters 
!==================================================================================================================================
SUBROUTINE DefineParametersTestcase()
! MODULES
USE MOD_Globals
USE MOD_ReadInTools ,ONLY: prms
IMPLICIT NONE
!==================================================================================================================================
CALL prms%SetSection("Testcase")
CALL prms%CreateIntOption('nWriteStats', "Write testcase statistics to file at every n-th AnalyzeTestcase step.", '1')
CALL prms%CreateIntOption('nAnalyzeTestCase', "Call testcase specific analysis routines every n-th timestep. "//&
                                              "(Note: always called at global analyze level)", '1000')
END SUBROUTINE DefineParametersTestcase

!==================================================================================================================================
!> Specifies all the initial conditions. The state in conservative variables is returned.
!==================================================================================================================================
SUBROUTINE InitTestcase()
! MODULES
USE MOD_PreProc
USE MOD_Globals
USE MOD_ReadInTools,        ONLY: GETINT
USE MOD_Output_Vars,        ONLY: ProjectName
USE MOD_Equation_Vars,      ONLY: RefStatePrim,IniRefState,kappa,mu0
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
LOGICAL                  :: fileExists                   ! Error handler for file
INTEGER                  :: ioUnit,openStat
REAL                     :: c1
!==================================================================================================================================
nWriteStats  = GETINT('nWriteStats','1')
nAnalyzeTestCase = GETINT( 'nAnalyzeTestCase','1000')
nWriteStats  = 1
!uBulkScale=0.98
uBulkScale=1.
Re_tau       = 1/mu0
c1 = 2.4390244
uBulk=c1*exp(-Re_tau/3.)*((Re_tau+c1)*exp(Re_tau/3.)*log(Re_tau+c1)+1.3064019*(Re_tau*exp(Re_tau/3)&
      +29.627395*exp(8./33.*Re_tau)+0.66762137*(Re_tau+3)))  -97.4857927165 
uBulk=uBulk/Re_tau

!prevent wrong pressure in channel testcase
IF(MPIRoot) THEN
  WRITE(*,*) 'Bulk velocity based on initial velocity Profile =',uBulk
  WRITE(*,*) 'Associated Pressure for Mach = 0.1 is', (uBulk/0.1)**2*RefStatePrim(IniRefState,1)/kappa
  IF (ABS(RefStatePrim(IniRefState,5)- (uBulk/0.1)**2*RefStatePrim(IniRefState,1)/kappa)/(uBulk/0.1)**2&
    *RefStatePrim(IniRefState,1)/kappa .GT. 0.01) THEN
    CALL abort(__STAMP__,'RefState incorrect, correct pressure in parameter file')
  END IF
END IF

dpdx = -1. ! Re_tau^2*rho*nu^2/delta^3

IF(.NOT.MPIRoot) RETURN

ALLOCATE(writeBuf(3,nWriteStats))
Filename = TRIM(ProjectName)//'_Stats.dat'
INQUIRE(FILE = Filename, EXIST = fileExists)
IF(.NOT.fileExists)THEN ! File exists and append data
  ioUnit=GETFREEUNIT()
  OPEN(UNIT   = ioUnit       ,&
       FILE   = Filename     ,&
       STATUS = 'Unknown'    ,&
       ACCESS = 'SEQUENTIAL' ,&
       IOSTAT = openStat                 )
  IF (openStat.NE.0) THEN
    CALL abort(__STAMP__, &
      'ERROR: cannot open '//TRIM(Filename))
  END IF
  WRITE(ioUnit,'(A)')'TITLE="Statistics,'//TRIM(ProjectName)//'"'
  WRITE(ioUnit,'(A)')'VARIABLES = "t_sim" "dpdx" "bulkVel"'
  WRITE(ioUnit,'(A)')'ZONE T="Statistics,'//TRIM(ProjectName)//'"'
  CLOSE(ioUnit)
END IF

END SUBROUTINE InitTestcase



!==================================================================================================================================
!> Specifies all the initial conditions. The state in conservative variables is returned.
!==================================================================================================================================
SUBROUTINE ExactFuncTestcase(tIn,x,Resu,Resu_t,Resu_tt)
! MODULES
USE MOD_Preproc,      ONLY: PP_Pi
USE MOD_Globals,      ONLY: Abort
USE MOD_Equation_Vars,ONLY: RefStatePrim,IniRefState
USE MOD_EOS,          ONLY: PrimToCons
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
REAL,INTENT(IN)                 :: x(3),tIn
REAL,INTENT(OUT)                :: Resu(5),Resu_t(5),Resu_tt(5)
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
REAL                            :: yplus,prim(5),amplitude
!==================================================================================================================================
!Channel Testcase: set mu0 = 1/Re_tau, rho=1, pressure adapted, Mach=0.1 according to Moser!!
!and hence: u_tau=tau=-dp/dx=1, and t=t+=u_tau*t/delta
Prim = RefStatePrim(IniRefState,:) ! prim=(/1.,0.3,0.,0.,0.71428571/)
IF(x(2).LE.0) THEN
  yPlus = (x(2)+1.)*Re_tau ! Re_tau=590
ELSE
  yPlus = (1.-x(2))*Re_tau ! Re_tau=590
END IF
!Prim(2)=uPlus
Prim(2) = uBulkScale*(1./0.41*log(1+0.41*yPlus)+7.8*(1-exp(-yPlus/11.)-yPlus/11.*exp(-yPlus/3.)))
!Prim(5)=(uBulk*sqrt(kappa*Prim(5)/Prim(1)))**2*Prim(1)/kappa ! Pressure such that Ma=1/sqrt(kappa*p/rho)
Amplitude = 0.1*Prim(2)
Prim(2)=Prim(2)+sin(20.0*PP_PI*(x(2)/(2.0)))*sin(20.0*PP_PI*(x(3)/(2*PP_PI)))*Amplitude
Prim(2)=Prim(2)+sin(30.0*PP_PI*(x(2)/(2.0)))*sin(30.0*PP_PI*(x(3)/(2*PP_PI)))*Amplitude
Prim(2)=Prim(2)+sin(35.0*PP_PI*(x(2)/(2.0)))*sin(35.0*PP_PI*(x(3)/(2*PP_PI)))*Amplitude
Prim(2)=Prim(2)+sin(40.0*PP_PI*(x(2)/(2.0)))*sin(40.0*PP_PI*(x(3)/(2*PP_PI)))*Amplitude
Prim(2)=Prim(2)+sin(45.0*PP_PI*(x(2)/(2.0)))*sin(45.0*PP_PI*(x(3)/(2*PP_PI)))*Amplitude
Prim(2)=Prim(2)+sin(50.0*PP_PI*(x(2)/(2.0)))*sin(50.0*PP_PI*(x(3)/(2*PP_PI)))*Amplitude

Prim(3)=Prim(3)+sin(30.0*PP_PI*(x(1)/(4*PP_PI)))*sin(30.0*PP_PI*(x(3)/(2*PP_PI)))*Amplitude
Prim(3)=Prim(3)+sin(35.0*PP_PI*(x(1)/(4*PP_PI)))*sin(35.0*PP_PI*(x(3)/(2*PP_PI)))*Amplitude
Prim(3)=Prim(3)+sin(40.0*PP_PI*(x(1)/(4*PP_PI)))*sin(40.0*PP_PI*(x(3)/(2*PP_PI)))*Amplitude
Prim(3)=Prim(3)+sin(45.0*PP_PI*(x(1)/(4*PP_PI)))*sin(45.0*PP_PI*(x(3)/(2*PP_PI)))*Amplitude
Prim(3)=Prim(3)+sin(50.0*PP_PI*(x(1)/(4*PP_PI)))*sin(50.0*PP_PI*(x(3)/(2*PP_PI)))*Amplitude

Prim(4)=Prim(4)+sin(30.0*PP_PI*(x(1)/(4*PP_PI)))*sin(30.0*PP_PI*(x(2)/(2.0)))*Amplitude
Prim(4)=Prim(4)+sin(35.0*PP_PI*(x(1)/(4*PP_PI)))*sin(35.0*PP_PI*(x(2)/(2.0)))*Amplitude
Prim(4)=Prim(4)+sin(40.0*PP_PI*(x(1)/(4*PP_PI)))*sin(40.0*PP_PI*(x(2)/(2.0)))*Amplitude
Prim(4)=Prim(4)+sin(45.0*PP_PI*(x(1)/(4*PP_PI)))*sin(45.0*PP_PI*(x(2)/(2.0)))*Amplitude
Prim(4)=Prim(4)+sin(50.0*PP_PI*(x(1)/(4*PP_PI)))*sin(50.0*PP_PI*(x(2)/(2.0)))*Amplitude
CALL PrimToCons(prim,Resu)

Resu_t =0.
Resu_tt=0.

END SUBROUTINE ExactFuncTestcase



!==================================================================================================================================
!> Compute bulk velocity for forcing term of the channel.
!==================================================================================================================================
SUBROUTINE CalcForcing(t,dt)
! MODULES
USE MOD_PreProc
USE MOD_Globals
USE MOD_DG_Vars,        ONLY: U
USE MOD_Mesh_Vars,      ONLY: sJ
USE MOD_Analyze_Vars,   ONLY: wGPVol,Vol
USE MOD_Mesh_Vars,      ONLY: nElems
#ifdef MPI
USE MOD_MPI_Vars
#endif
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
REAL,INTENT(IN)                 :: t,dt
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                         :: i,j,k,iElem
!==================================================================================================================================
BulkVel =0.
DO iElem=1,nElems
  DO k=0,PP_N; DO j=0,PP_N; DO i=0,PP_N
    BulkVel = BulkVel+U(2,i,j,k,iElem)/U(1,i,j,k,iElem)*wGPVol(i,j,k)/sJ(i,j,k,iElem)
  END DO; END DO; END DO
END DO

#ifdef MPI
CALL MPI_ALLREDUCE(MPI_IN_PLACE,BulkVel,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,iError)
#endif
BulkVel = BulkVel/Vol
END SUBROUTINE CalcForcing


!==================================================================================================================================
!> Apply forcing term equivalent to a constant streamwise pressure gradient
!==================================================================================================================================
SUBROUTINE TestcaseSource(Ut)
! MODULES
USE MOD_PreProc
USE MOD_Globals
USE MOD_Mesh_Vars, ONLY:sJ,nElems
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
REAL,INTENT(INOUT)              :: Ut(PP_nVar,0:PP_N,0:PP_N,0:PP_N,1:nElems) !< solution time derivative
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                         :: i,j,k,iElem
!==================================================================================================================================
! Apply forcing with the pressure gradient
DO iElem=1,nElems
  DO k=0,PP_N; DO j=0,PP_N; DO i=0,PP_N
    Ut(2,i,j,k,iElem)=Ut(2,i,j,k,iElem) -dpdx/sJ(i,j,k,iElem)
    Ut(5,i,j,k,iElem)=Ut(5,i,j,k,iElem) -dpdx*BulkVel/sJ(i,j,k,iElem)
  END DO; END DO; END DO
END DO
END SUBROUTINE TestcaseSource


!==================================================================================================================================
!> Output testcase statistics
!==================================================================================================================================
SUBROUTINE WriteStats()
! MODULES
USE MOD_PreProc
USE MOD_Globals
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
INTEGER                  :: ioUnit,openStat
!==================================================================================================================================
ioUnit=GETFREEUNIT()
OPEN(UNIT     = ioUnit     , &
     FILE     = Filename   , &
     FORM     = 'FORMATTED', &
     STATUS   = 'OLD'      , &
     POSITION = 'APPEND'   , &
     RECL     = 50000      , &
     IOSTAT = openStat           )
IF(openStat.NE.0) THEN
  CALL abort(__STAMP__, &
    'ERROR: cannot open '//TRIM(Filename))
END IF
WRITE(ioUnit,'(3E23.14)') writeBuf(:,1:ioCounter)
CLOSE(ioUnit)

END SUBROUTINE WriteStats



!==================================================================================================================================
!> Specifies periodic hill testcase
!==================================================================================================================================
SUBROUTINE AnalyzeTestcase(Time)
! MODULES
USE MOD_Globals
IMPLICIT NONE
!----------------------------------------------------------------------------------------------------------------------------------
! INPUT/OUTPUT VARIABLES
REAL,INTENT(IN)                 :: Time                   !< simulation time
!----------------------------------------------------------------------------------------------------------------------------------
! LOCAL VARIABLES
!==================================================================================================================================
IF(MPIRoot)THEN
  ioCounter=ioCounter+1
  writeBuf(:,ioCounter) = (/Time, dpdx, BulkVel/)
  IF(ioCounter.EQ.nWriteStats)THEN
    CALL WriteStats()
    ioCounter=0
  END IF
END IF
END SUBROUTINE AnalyzeTestCase

!==================================================================================================================================
!> Specifies all the initial conditions. The state in conservative variables is returned.
!==================================================================================================================================
SUBROUTINE FinalizeTestcase()
! MODULES
USE MOD_Globals
IMPLICIT NONE
!==================================================================================================================================
IF(MPIRoot) CALL WriteStats()
IF(MPIRoot) DEALLOCATE(writeBuf)
END SUBROUTINE


END MODULE MOD_Testcase
