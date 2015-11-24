"""
Vincente Pericoli
UC Davis

for more info, including license information,
see: https://github.com/ucdavis-kanvinde-group/abaqus-odb-tools


Set of functions to use with ABAQUS output databases (ODB files).

These functions rely on the abaqus-odb-tools library (see above).
They exist purely for backward-compatibility, since that library
was totally refactored into an object-oriented code.

Simply download abaqus-odb-tools, and change the sys.path.append
directory (below) to point towards the download.
"""

#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Import Modules


from odbAccess import *
from abaqusConstants import *
import numpy
import sys
sys.path.append("C:\Users\Vince Pericoli\Documents\GitHub\abaqus-odb-tools")
from odbFieldVariableClasses import *

#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Function defs

def getNodalPEEQ(odbName, nodeSetName, verbose=True):
    """ Returns a CSV of the nodal averaged PEEQ """
    
    dataName = 'PEEQ'
    nodalPEEQ = IntPtVariable(odbName, dataName, nodeSetName)
    nodalPEEQ.fetchNodalAverage()
    nodalPEEQ.saveCSV(verbose)
    return

def getNodalMises(odbName, nodeSetName, verbose=True):
    """ returns a CSV of the nodal averaged Mises """
    
    dataName = 'MISES'
    nodalMISES = IntPtVariable(odbName, dataName, nodeSetName)
    nodalMISES.fetchNodalAverage()
    nodalMISES.saveCSV(verbose)
    return

def getNodalPressure(odbName, nodeSetName, verbose=True):
    """ returns a CSV of the nodal averaged pressure """
    
    dataName =  'PRESS'
    nodalPRESS = IntPtVariable(odbName, dataName, nodeSetName)
    nodalPRESS.fetchNodalAverage()
    nodalPRESS.saveCSV(verbose)
    return
    
def getNodalInv3(odbName, nodeSetName, verbose=True):
    """ returns a CSV of the nodal averaged third invariant """
    
    dataName = 'INV3'
    nodalINV3 = IntPtVariable(odbName, dataName, nodeSetName)
    nodalINV3.fetchNodalAverage()
    nodalINV3.saveCSV(verbose)
    return

def getNodalDispl(odbName, nodeSetName, verbose=True):
    """
    returns several CSVs of the nodal coordinates
    (one CSV file per direction)
    """
    dataName = 'U'
    nodalDispl = NodalVariable(odbName, dataName, nodeSetName)
    nodalDispl.fetchNodalOutput()
    nodalDispl.saveCSV(verbose)
    return

def getNodalReactionSum(odbName, nodeSetName, verbose=True):
    """
    returns several CSVs of the summed nodal reactions
    (one CSV file per direction)
    """
    dataName = 'RF'
    summedRF = NodalVariable(odbName, dataName, nodeSetName)
    summedRF.fetchNodalOutput()
    summedRF.sumNodalData()
    summedRF.saveCSV(verbose)
    return