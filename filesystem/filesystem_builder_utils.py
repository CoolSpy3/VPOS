def binaryNumber(num: int, len: int) -> bytes:
    return num.to_bytes(len, byteorder='little', signed=False)

def qword(num: int) -> bytes:
    return binaryNumber(num, 8)

def dword(num: int) -> bytes:
    return binaryNumber(num, 4)

def word(num: int) -> bytes:
    return binaryNumber(num, 2)

def byte(num: int) -> bytes:
    return binaryNumber(num, 1)

def getRequiredUnits(size: int, unitSize: int) -> int:
    return (size + (unitSize - 1)) // unitSize

def getShortName(name: str) -> str:
    # TODO: Implement this
    name = name[:11]
    return name + (11 - len(name)) * '\0'
