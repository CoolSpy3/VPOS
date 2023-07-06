%ifndef FAT32_FSINFO
%define FAT32_FSINFO

fat32_fsinfo:
    dd           0x41615252 ; Signature
    times 480 db 0          ; Reserved
    dd           0x61417272 ; Signature
    dd           0xFFFFFFFF ; Free cluster count
    dd           0xFFFFFFFF ; Next free cluster
    times 12  db 0          ; Reserved
    dd           0xAA550000 ; Signature

%if ($-fat32_fsinfo) != 512
    %error "FAT32 FSInfo is not the correct size"
%endif

%endif
