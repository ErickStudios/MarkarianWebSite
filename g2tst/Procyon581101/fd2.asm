
    ; NEW
    ; LET A IS 12
    ;  1
    ; LET B IS $A+2
    ;  2
    ; OK
    ; SAVE
    ; ...
    ; LOAD
    
    ; A-Z = 26 LETS * 2 = 40 + 12 = 52 bytes

    local 1000h

    row equ 9fh
    col equ 9eh
    tmp1 equ 80h
    tmp2 equ 82h
    tmp3 equ 84h
    let1id equ 8ah
    letContents equ 700h
    inputCommand equ 800h
    addrToPut equ 890h
    OperationO1 equ 892h
    OperationO2 equ 894h
    ActualFileLine equ 898h
    BufferOfFile equ 8B0h
    basicPc equ 89ah
    strTmp equ 870h
    tmp4 equ 86h
    tmp5 equ 88h

    jmp $start

    ; X = BUFFER
execute:
    stx %z $tmp1

    ; LET
    ldy %x $0
    tiy $4C45h
    lcf $1
    bcf $.tryLet
    jmp $.isNotLet
.tryLet:
    lby %x $2
    tiy $54h
    lcf $1
    bcf $.isLet
    jmp $.isNotLet

; LET behavior
.isLet:
    cha $4
    add %x %a
    lba %x $0
    sub $65
    sba %z $let1id
    cha $2 ; skip name + space
    add %x %a
    
    ; IS statment
    lda %x $0
    tia $4953h
    lcf $1
    bcf $.letSetAbs

.letSetAbs:
    cha $3
    add %x %a

    sbz %z $501h
    jmp $getStatment
    lba %z $let1id
    mul $2
    sty %a $letContents
    sbz %z $500h

.isNotLet:
    ldy %x $0
    tiy $504fh
    lcf $1
    bcf $.tryPoke
    jmp $.isNotPoke

.tryPoke:
    ldy %x $2
    tiy $4b45h
    lcf $1
    bcf $.isPoke
    jmp $.isNotPoke

.isPoke:
    cha $5
    add %x %a

    sbz %z $501h
    jmp $getStatment

    sty %z $addrToPut

    cha $1
    add %x %a

    sbz %z $501h
    jmp $getStatment

    lda %z $addrToPut
    sby %a $0

    sbz %z $500h

.isNotPoke:

    ldy %x $0
    tiy $5045h
    lcf $1
    bcf $.tryPeek
    jmp $.isNotPeek

.tryPeek:
    ldy %x $2
    tiy $454bh
    lcf $1
    bcf $.isPeek
    jmp $.isNotPeek

.isPeek:
    chy $5
    add %x %y

    lba %x $0

    sub $65
    sba %z $let1id

    cha $2
    add %x %a

    sbz %z $501h
    jmp $getStatment

    lby %y $0
    mul $2

    sty %a $letContents

    sbz %z $500h

.isNotPeek:

    ldy %x $0
    tiy $4e45h
    lcf $1
    bcf $.tryNew

    jmp $.isNotNew

.tryNew:

    lby %x $2
    tiy $57h
    lcf $1
    bcf $.isNew
    jmp $.isNotNew

.isNew:
    jmp $editMode
    sbz %z $500h

.isNotNew:

    ldy %x $0
    tiy $5341h
    lcf $1
    bcf $.trySave
    jmp $.isNotSave
.trySave:
    ldy %x $2
    tiy $5645h
    lcf $1
    bcf $.isSave
    jmp $.isNotSave
.isSave:
    cha $5
    add %x %a
    sbz %z $501h
    jmp $getStatment

    cha $8
    sba %z $406h ; set card8
    sty %z $401h

    cha $1
    add %x %a

    sbz %z $501h
    jmp $getStatment

    sub %x %x

    cha $512
    mul %y %a
.saveLoop:
    lda %x $BufferOfFile
    sta %z $403h
    cha $2
    sba %z $405h
    add %x %a
    tsx %y
    lcf $2
    bcf $.saveLoop
    sbz %z $500h

.isNotSave:
    ldy %x $0
    tiy $4c4fh
    lcf $1
    bcf $.tryLoad
    jmp $.isNotLoad

.tryLoad:
    ldy %x $2
    tiy $4144h
    lcf $1
    bcf $.isLoad
    jmp $.isNotLoad

.isLoad:
    cha $5
    add %x %a
    sbz %z $501h
    jmp $getStatment

    cha $8
    sba %z $406h
    sty %z $401h
    
    cha $1
    add %x %a

    sbz %z $501h
    jmp $getStatment

    sub %x %x

    cha $512
    mul %y %a

.loadLoop:
    lda %z $403h
    sta %x $BufferOfFile
    cha $2
    sba %z $405h
    add %x %a
    tsx %y
    lcf $2
    bcf $.loadLoop
    sbz %z $500h

.isNotLoad:
    ldy %x $0
    tiy $4946h
    lcf $1
    bcf $.isIf

    jmp $.isNotIf

.isIf:
    cha $3
    add %x %a

    sbz %z $501h
    jmp $getStatment

    sty %z $OperationO1

    cha $1
    add %x %a

    sbz %z $501h
    jmp $getStatment

    lda %z $OperationO1
    sub %y %a

    sty %z $OperationO1

    cha $1
    add %x %a

    lba %x $0
    ldy %z $OperationO1

    tia $'E'
    lcf $1
    bcf $.ifEqualCondition

    tia $'L'
    lcf $1
    bcf $.ifLessCondition

.ifEqualCondition:
    cha $0
    tiy $0
    lcf $1
    bcf $.ifActiveFlag
    jmp $.ifGetLineNum
.ifLessCondition:
    cha $0
    tiy $8000h
    lcf $2
    bcf $.ifActiveFlag
    jmp $.ifGetLineNum
.ifActiveFlag:
    cha $1
.ifGetLineNum:
    sba %z $OperationO2
    cha $2
    add %x %a

    sbz %z $501h
    jmp $getStatment

    lba %z $OperationO2
    tia $0
    lcf $1
    bcf $.ifNotChange

    cha $1
    sub %y %a
    sty %z $basicPc

.ifNotChange:
    sbz %z $500h

.isNotIf:
    ldy %x $0
    tiy $5255h
    lcf $1
    bcf $.tryRun
    jmp $.isNotRun

.tryRun:
    lby %x $2
    tiy $4eh
    lcf $1
    bcf $.isRun
    jmp $.isNotRun
.isRun:
    jmp $runProgram
    sbz %z $500h
    
.isNotRun:
    ldy %x $0
    tiy $5052h
    lcf $1
    bcf $.startTryPrint
    jmp $.isNotPrint

.startTryPrint:
    ldy %x $2
    tiy $494eh
    lcf $1
    bcf $.tryPrint
    jmp $.isNotPrint

.tryPrint:
    lby %x $4
    tiy $54h
    lcf $1
    bcf $.isPrint
    jmp $.isNotPrint

.isPrint:
    cha $6
    add %x %a

    sbz %z $501h
    jmp $getStatment

    tsy %z
    lcf $1
    bcf $.printAZero

    sub %a %a
    add %a %y
    mul $10
    sub %y %y
    add %y %a

    sty %z $OperationO1
    stx %z $tmp1
    sub %a %a
    sub %x %x

.printformatLoop:
    tiy $0
    lcf $1
    bcf $.goPrintRead
    stx %z $tmp3

    sub %a %a
    add %a %y
    div $10
    mul $10
    sub %x %x
    add %x %y
    sub %x %a
    sub %a %a
    add %a %x
    add $48

    ldx %z $tmp3
    sba %x $strTmp
    cha $1
    add %x %a
    sub %a %a
    add %a %y
    div $10
    sub %y %y
    add %y %a
    jmp $.printformatLoop

.printAZero:
    cha $'0'
    sbz %z $501h
    jmp $tty
    cha $10
    jmp $tty

.goPrintRead:
    cha $1
    sub %x %a
.goPrintReadl:
    tix $0
    lcf $1
    bcf $.endPrint

    lba %x $strTmp
    stx %z $let1id
    sbz %z $501h
    jmp $tty
    ldx %z $let1id
    cha $1
    sub %x %a
    jmp $.goPrintReadl

.endPrint:
    ldx %z $tmp1
    cha $10
    sbz %z $501h
    jmp $tty
    ldx %z $tmp1
    sbz %z $500h

.isNotPrint:
    sbz %z $500h

runProgram:
    stz %z $basicPc
.loop:
    lda %z $basicPc
    mul $16
    chx $BufferOfFile
    add %x %a

    sbz %z $501h
    jmp $execute

    lda %z $basicPc
    add $1
    sta %z $basicPc
    jmp $.loop

    ; X = BUF, Y = VAL
getStatment:
    lba %x $0
    tia $'$'
    lcf $1
    bcf $.operation

    tia $64
    lcf $3
    bcf $.isLet

    jmp $getNumber
.isLet:
    sub $65
    mul $2
    ldy %a $letContents
    cha $1
    add %x %a
    sbz %z $500h
.operation:
    cha $1
    add %x %a
    sbz %z $501h
    jmp $trimSpaces

    sbz %z $501h
    jmp $getStatment
    sty %z $OperationO1

    sbz %z $501h
    jmp $trimSpaces

    lba %x $0
    tia $'+'
    lcf $1
    bcf $.adition

    lba %x $0
    tia $'-'
    lcf $1
    bcf $.substract

    lba %x $0
    tia $'/'
    lcf $1
    bcf $.divition

    lba %x $0
    tia $'*'
    lcf $1
    bcf $.multiply


    sbz %z $500h

.adition:
    cha $1
    add %x %a
    sbz %z $501h
    jmp $trimSpaces

    sbz %z $501h
    jmp $getStatment

    lda %z $OperationO1
    add %y %a

    sbz %z $500h

.substract:
    cha $1
    add %x %a
    sbz %z $501h
    jmp $trimSpaces

    sbz %z $501h
    jmp $getStatment

    lda %z $OperationO1
    sub %y %a

    sbz %z $500h

.divition:
    cha $1
    add %x %a
    sbz %z $501h
    jmp $trimSpaces

    sbz %z $501h
    jmp $getStatment

    lda %z $OperationO1
    div %y %a

    sbz %z $500h

.multiply:
    cha $1
    add %x %a
    sbz %z $501h
    jmp $trimSpaces

    sbz %z $501h
    jmp $getStatment

    lda %z $OperationO1
    mul %y %a

    sbz %z $500h

    ; X = BUF
trimSpaces:
.loop:
    lba %x $0
    tia $31
    lcf $3
    bcf $.end
    cha $1
    add %x %a
    jmp $.loop
.end:
    sbz %z $500h

    ; X= BUF, Y= num
getNumber:
    sub %y %y
.while:
    lba %x $0
    tia $'9'
    lcf $3
    bcf $.end

    lba %x $0
    tia $48
    lcf $2
    bcf $.end

    cha $10
    mul %y %a
    lba %x $0
    tia $47
    lcf $3
    bcf $.ok

.end:
    sbz %z $500h

.ok:
    sub $48
    add %y %a
    cha $1
    add %x %a
    jmp $.while

editMode:
    stz %z $ActualFileLine
.readline:
    sub %x %x
.waitk:
    lba %z $440h
    tsa %z
    lcf $1
    bcf $.waitk

    tia $10
    lcf $1
    bcf $.endIo

    sba %x $inputCommand

    stx %z $tmp3
    sbz %z $501h
    jmp $tty
    ldx %z $tmp3

    cha $1
    add %x %a

    jmp $.waitk
.endIo:
    ldy %z $inputCommand
    tiy $4f4bh
    lcf $1
    bcf $.endProgram

    stx %z $tmp3
    cha $10
    sbz %z $501h
    jmp $tty
    ldx %z $tmp3

    lda %z $ActualFileLine
    mul $16
.cpyloop:
    ldy %z $tmp3
    sub %y %x
    lby %y $inputCommand
    sby %a $BufferOfFile

    chy $1
    sub %x %y
    add %a %y
    tsx %z
    lcf $3
    bcf $.cpyloop

    lda %z $ActualFileLine
    add $1
    sta %z $ActualFileLine

    jmp $.readline

.endProgram:
    cha $10
    sbz %z $501h
    jmp $tty
    sbz %z $500h

start:
    sub %x %x
    sbz %z $inputCommand
.wait:
    lba %z $440h
    tsa %z
    lcf $1
    bcf $.wait

    tia $10
    lcf $1
    bcf $.endIo

    sba %x $inputCommand

    stx %z $tmp2
    sbz %z $501h
    jmp $tty
    ldx %z $tmp2

    cha $1
    add %x %a

    jmp $.wait
.endIo:
    cha $10
    sbz %z $501h
    jmp $tty

    chx $inputCommand
    sbz %z $501h
    jmp $execute
    jmp $start

    ; sprite = A
tty:
    tia $10
    lcf $1
    bcf $.nl

    lbx %z $row
    chy $16
    mul %x %y
    lby %z $col
    add %x %y
    sba %x $340h

    lba %z $col
    add $1
    sba %z $col

    lbx %z $row
    tix $12
    lcf $2
    bcf $.res

    jmp $.ars

.res:

    sbz %z $500h

.nl:
    sbz %z $col
    lba %z $row
    add $1
    sba %z $row
    lbx %z $row
    tix $12
    lcf $2
    bcf $.res2
    jmp $.ars
.res2:
    sbz %z $500h

.ars:
    sba %z $tmp1
    stx %z $tmp2

    sbz %z $501h
    jmp $cls

    ldx %z $tmp2
    lba %z $tmp1

    sbz %z $row
    sbz %z $col
    sbz %z $500h

cls:
    sub %y %y
.loop:
    cha $02020h
    sta %y $340h
    cha $2
    add %y %a
    tiy $0c0h
    lcf $2
    bcf $.loop
    sbz %z $500h

hang:
    jmp $hang