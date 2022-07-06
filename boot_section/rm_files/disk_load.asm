; INPUT:  DL=Drive
;         CH=Cylinder
;         DH=Head
;         CL=Sector
;         AX=SectorCount
;         ES:BX=Buffer
; OUTPUT: CF=0 AH       = 0
;              CH,DH,CL = CHS of following sector
;         CF=1 AH       = Error status
;              CH,DH,CL = CHS of problem sector
disk_load: ; Credit: Sep Roland on https://stackoverflow.com/questions/30990880/how-are-all-disk-sectors-iterated-in-assembly
    push    es
    push    di
    push    bp
    mov     bp,sp           ;Local variables:
    push    ax              ;[bp-2]=SectorCount
    push    cx              ;[bp-4]=MaxSector
    push    dx              ;[bp-6]=MaxHead
    push    bx              ;[bp-8]=MaxCylinder

    push    es
    mov     ah,08h
    int     13h             ;ReturnDiskDriveParameters
    pop     es
    jc      .NOK
    mov     bx,cx           ;10-bit cylinder info -> BX
    xchg    bl,bh
    shr     bh,6
    xchg    [bp-8],bx       ;Store MaxCylinder and get input BX back
    movzx   dx,dh           ;8-bit head info -> DX
    xchg    [bp-6],dx       ;Store MaxHead and get input DX back
    and     cx,003Fh        ;6-bit sector info -> CX
    xchg    [bp-4],cx       ;Store MaxSector and get input CX back

    .ReadNext:
        mov     di,5            ;Max 5 tries per sector
    .ReadAgain:
        mov     ax,0201h        ;Read 1 sector
        int     13h             ;ReadDiskSectors
        jnc     .OK
        push    ax              ;Save error status byte in AH
        mov     ah,00h
        int     13h             ;ResetDiskSystem
        pop     ax
        dec     di
        jnz     .ReadAgain
        stc
        jmp     .NOK
    .OK:
        dec     word [bp-2] ;SectorCount
        ; jz      Ready         ; Read forever (or until we read the whole drive)
        call    .NextCHS
        mov     ax,es           ;Move buffer 512 bytes up
        add     ax,512/16
        mov     es,ax
        jmp     .ReadNext

    .Ready:
        call    .NextCHS         ;Return useful CHS values to support reads
        xor     ah,ah           ; -> CF=0 ... that are longer than memory
    .NOK:
        mov     sp,bp
        pop     bp
        pop     di
        pop     es
        ret

    .NextCHS:
        mov     al,cl            ;Calculate the 6-bit sector number
        and     al,00111111b
        cmp     al,[bp-4]        ;MaxSector
        jb      .NextSector
        cmp     dh,[bp-6]        ;MaxHead
        jb      .NextHead
        mov     ax,cx            ;Calculate the 10-bit cylinder number
        xchg    al,ah
        shr     ah,6
        cmp     ax,[bp-8]        ;MaxCylinder
        jb      .NextCylinder
    .DiskWrap:
        mov     cx,1             ;Wraparound to very first sector on disk
        mov     dh,0
        ret
    .NextCylinder:
        inc     ax
        shl     ah,6             ;Split 10-bit cylinder number over CL and CH
        xchg    al,ah
        mov     cx,ax
        mov     dh,0
        inc     cl
        ret
    .NextHead:
        inc     dh
        and     cl,11000000b
    .NextSector:
        inc     cl
        ret
