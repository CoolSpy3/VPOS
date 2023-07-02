import datetime
import os
import os.path as path
import sys

from filesystem_builder_utils import *

sectorsPerCluster = 1

minClusters = 70000 # Technically 65525, but the documentation stresses that this is easy to get wrong, so use 70000 to be ABSOLUTELY SURE

staticDir  = sys.argv[1] # The directory containing the static files
dynamicDir = sys.argv[2] # The directory containing the dynamic files
relReqDir  = sys.argv[3] # The directory which requirements are referenced to
outfile    = sys.argv[4] # The file to write the filesystem to

if path.exists(outfile):
    os.remove(outfile)

if path.exists(outfile + '.d'):
    os.remove(outfile + '.d')

def recursivelySearchDir(dir: str) -> dict:
    files = {}
    for file in os.listdir(dir):
        file = path.join(dir, file)
        relFile = path.relpath(file, dir)
        if path.isdir(file):
            files[relFile] = recursivelySearchDir(file)
        elif path.isfile(file):
            files[relFile] = file
    return files

staticFiles = recursivelySearchDir(staticDir)
dynamicFiles = recursivelySearchDir(dynamicDir)

def mergeDirectory(staticFiles: dict, dynamicFiles: dict, dir: str = "") -> dict:
    files = staticFiles
    for name, file in dynamicFiles.items():
        if name in files:
            if type(file) == dict and type(files[name]) == dict:
                files[name] = mergeDirectory(files[name], file, f'{dir}/{name}')
            else:
                print(f'Error: file name collision: {dir}/{name}')
                exit(1)
        files[name] = file
    return files

files = mergeDirectory(staticFiles, dynamicFiles)

def recursivelyCalculateRequiredSizeSectors(files: dir) -> tuple[dict, int]:
    sizedFiles = {}
    for name, file in files.items():
        if type(file) == dict:
            sizedFiles[name] = recursivelyCalculateRequiredSizeSectors(file)
        else:
            sizedFiles[name] = ( file, os.path.getsize(file) )

    size = 0
    for name in files.keys():
        requiredLFNEntries = getRequiredUnits(len(name), 13)

        if requiredLFNEntries > 0x1F:
            print(f'Error: file name too long: {name}')
            exit(1)

        size += ( requiredLFNEntries + 1 ) * 32

    return ( sizedFiles, size )

sizedFiles, rootDirectorySize = recursivelyCalculateRequiredSizeSectors(files)

fatEOF = dword(0x0FFFFFFF)

with open(outfile, 'wb+') as oStream:
    oStream.write(dword(0xFFFFFF00 | 0xF8)) # FAT ID
    oStream.write(fatEOF)
    currentCluster = 2

    def allocateClusters(numClusters: int, shadow: bool = False) -> None:
        global currentCluster
        for i in range(numClusters - 1):
            currentCluster += 1
            oStream.write(dword(0x00000000) if shadow else dword(currentCluster))

        currentCluster += 1
        oStream.write(fatEOF)

    def recursivelyClusterFiles(files: dict) -> dict:
        clusteredFiles = {}
        for name, file in files.items():
            fileCluster = currentCluster
            allocateClusters(getRequiredUnits(file[1], 512 * sectorsPerCluster))
            if type(file[0]) == dict:
                clusteredFiles[name] = (recursivelyClusterFiles(file[0]), file[1], fileCluster)
            else:
                clusteredFiles[name] = (file[0], file[1], fileCluster)

        return clusteredFiles

    allocateClusters(getRequiredUnits(rootDirectorySize, sectorsPerCluster * 512))

    clusteredFiles = recursivelyClusterFiles(sizedFiles)

    requiredPaddingClusters = minClusters - (currentCluster - 1) # -1 because currentCluster is always the NEXT cluster to be allocated

    if requiredPaddingClusters > 0:
        allocateClusters(requiredPaddingClusters, shadow=True)

    # Pad the FAT to the next sector boundary
    oStream.write(b'\x00' * (512 - (currentCluster * 4) % 512))

    with open(outfile + ".fatSize", 'w+') as oStream2:
        oStream2.write(f'{oStream.tell() // 512}')

    now = datetime.datetime.now()

    time = word(now.hour << 11 | now.minute << 5 | now.second // 2)
    date = word((now.year - 1980) << 9 | now.month << 5 | now.day)

    def padCluster(size: int) -> None:
        if size % (sectorsPerCluster * 512) != 0:
            oStream.write(byte(0x00) * (sectorsPerCluster * 512 - (size % (sectorsPerCluster * 512))))

    # If recurse in the same way as recursivelyClusterFiles, we should visit all the files in the same order and thus write to the same clusters we allocated
    def recursivelyWriteDirectory(files: dict, directorySize: int) -> None:
        for name, file in files.items(): # First write the directory entries
            currentLFNId = getRequiredUnits(len(name), 13)

            # Write first LFN entry with padding
            shortenedName = name[-13 if len(name) % 13 == 0 else -(len(name) % 13):]
            paddedName = shortenedName + '\0' + b'\xff\xff'.decode('utf-16-le') * 13 # We only use the first 13 characters, so we can pad 13 characters, and extra padding will be ignored
            oStream.write(byte(0x40 | currentLFNId))
            oStream.write(paddedName[:5].encode('utf-16-le'))
            oStream.write(byte(0x0F))
            oStream.write(byte(0x00))
            oStream.write(byte(120)) # Checksum
            oStream.write(paddedName[5:11].encode('utf-16-le'))
            oStream.write(word(0x0000))
            oStream.write(paddedName[11:13].encode('utf-16-le'))
            currentLFNId -= 1

            for i in range(len(name) - len(shortenedName), 0, -13): # Write the LFN entries
                shortenedName = name[i-13:i]
                oStream.write(byte(currentLFNId))
                oStream.write(shortenedName[:5].encode('utf-16-le'))
                oStream.write(byte(0x0F))
                oStream.write(byte(0x00))
                oStream.write(byte(120)) # Checksum
                oStream.write(shortenedName[5:11].encode('utf-16-le'))
                oStream.write(word(0x0000))
                oStream.write(shortenedName[11:13].encode('utf-16-le'))
                currentLFNId -= 1

            # Write the 8.3 entry
            oStream.write(getShortName(name).encode('utf-8'))
            oStream.write(byte(0x10) if type(file[0]) == dict else byte(0x00)) # Attributes
            oStream.write(byte(0x00)) # Reserved
            oStream.write(byte(0x00)) # Creation time (tenths of a second)
            oStream.write(time) # Creation time
            oStream.write(date) # Creation date
            oStream.write(date) # Last access date
            oStream.write(word(file[2] >> 16)) # High word of first cluster
            oStream.write(time) # Last modified time
            oStream.write(date) # Last modified date
            oStream.write(word(file[2] & 0xFFFF)) # Low word of first cluster
            oStream.write(dword(0x00000000) if type(file[0]) == dict else dword(file[1])) # File size

        padCluster(directorySize)

        for name, file in files.items(): # Then write the file data
            if type(file[0]) == dict:
                recursivelyWriteDirectory(file[0])
            else:
                with open(file[0], 'rb') as iStream:
                    while buf := iStream.read(1024):
                        oStream.write(buf)
                padCluster(file[1])

    recursivelyWriteDirectory(clusteredFiles, rootDirectorySize)

    if requiredPaddingClusters > 0:
        oStream.write(byte(0x00) * (sectorsPerCluster * 512 * requiredPaddingClusters))

requiredFiles = []

def recursivelyFindRequiredFiles(files: dict):
    for file in files.values():
        if type(file) == dict:
            recursivelyFindRequiredFiles(file)
        else:
            requiredFiles.append(file)

recursivelyFindRequiredFiles(files)

requiredFiles = [path.relpath(file, relReqDir).replace('\\', '/') for file in requiredFiles]

with open(outfile + '.d', 'w+') as oStream:
    reqs = ' '.join(requiredFiles)
    oStream.write(f'{outfile} : {reqs}\n')
    for file in requiredFiles: # Create phony Makefile targets for each required file
        oStream.write(f'{file} :\n')
