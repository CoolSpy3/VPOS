import os
import os.path as path
import sys

from genericpath import isfile

dir = sys.argv[1]
outfile = sys.argv[2]

if path.exists(outfile):
    os.remove(outfile)

if path.exists(outfile + '.d'):
    os.remove(outfile + '.d')

ignoreList = ['buildfs.py']
files = []

def recursivelySearchDir(rootDir: str) -> None:
    for file in os.listdir(rootDir):
        file = path.join(rootDir, file)
        if path.relpath(file, dir).replace('\\', '/') not in ignoreList:
            if path.isdir(file):
                recursivelySearchDir(file)
            elif path.isfile(file):
                    files.append(path.relpath(file, dir))

recursivelySearchDir(dir)

if not files:
    with open(outfile, 'w+') as file:
        pass

    with open(outfile + '.d', 'w+') as file:
        pass

    exit()

headerLength = len(files) * 8 + 4
nameLengths = [len(file.replace('\\', '/')) + 1 for file in files]
fileLengths = [4 + path.getsize(path.join(dir, file)) for file in files]

nameOffsets = [headerLength + sum(nameLengths[:i]) for i in range(len(nameLengths))]

fileSectionOffset = nameLengths[-1] + nameOffsets[-1]

fileOffsets = [fileSectionOffset + sum(fileLengths[:i]) for i in range(len(fileLengths))]

nullByte = (0).to_bytes(1, byteorder='little', signed=False)

paddingLen = 512 - ( ( fileLengths[-1] + fileOffsets[-1] ) % 512 )

def binaryNumber(num: int) -> bytes:
    return num.to_bytes(4, byteorder='little', signed=False)

with open(outfile, 'wb+') as oStream:
    for i in range(len(files)):
        oStream.write(binaryNumber(nameOffsets[i]))
        oStream.write(binaryNumber(fileOffsets[i]))
    oStream.write(bytes(4))
    for i in range(len(files)):
        oStream.write(bytes(files[i].replace('\\', '/'), encoding='ascii'))
        oStream.write(nullByte)
    for i in range(len(files)):
        oStream.write(binaryNumber(fileLengths[i]))
        with open(path.join(dir, files[i]), 'rb') as iStream:
            while buf := iStream.read(1024):
                oStream.write(buf)
    oStream.write(bytes(paddingLen))

with open(outfile + '.d', 'w+') as oStream:
    reqs = ' '.join([path.join(dir, file).replace('\\', '/') for file in files])
    oStream.write(f'{outfile} : {reqs}\n')
