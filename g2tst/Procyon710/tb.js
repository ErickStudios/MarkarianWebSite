/**
 *  
 *  040-06f     MMIO
 *  070-07f     RESERVED0
 *  080-0ff     RAM0
 *  100-1ff     ROM0
 *  200-9ff     RAM1
 */

import * as emp from "https://cdn.jsdelivr.net/gh/ErickStudios/EMP-Arch@f95e9ce8231b1f883058d6d8c3749b6d595d2a48/Toolchain/libemp.js?v=200";

let cpu = new emp.cpuGen2();

let pc = 0x1FC;
let teletypeColors = {
    0b00: 'red',
    0b01: 'blue',
    0b10: 'black',
    0b11: 'green'
}

// Board Reset
function BoardReset() {
    cpu.rst();
    pc = 0x1FC;
}

// Board Read
function BoardRead(adr) {

    return 0;
}
// Board Write
function BoardWrite(adr, val) {

}

let tty_line;
_tty_newline_();

// new line tty
function _tty_newline_() {
    tty_line = document.createElement('div');
    tty_line.style.display = 'flex';
    document.body.appendChild(tty_line);
}

// teletype function
function _tty_(txt, clr) {
    if (txt == '\n') {
        _tty_newline_();
    }
    else {
        let tty_char = document.createElement('p');
        tty_char.textContent = txt;
        tty_char.style.color = clr;
        tty_line.appendChild(tty_char)
    }
}

// teletype character
function tty_char(chr, clr) {
    _tty_(chr[0], teletypeColors[clr & 0b11])   
}

tty_char('h', 0b01);
tty_char('i', 0b01);

cpu.rex = BoardRead;
cpu.wex = BoardWrite;

BoardReset();