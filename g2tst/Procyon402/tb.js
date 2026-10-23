
/**
 * $D0 =         PXCLR
 * $D1 =         PXRCLK
 * $D2 =         PXLC
 * $D3 =         PXLF
 * $50-$CF =     RAM0
 * $1000-$1FFF = CARTRIGE
 * $1FFA =       FRAME START
 * $1FFC =       PAD INTERACT
 * $1FFE =       INIT
 */

import * as emp from "https://cdn.jsdelivr.net/gh/ErickStudios/EMP-Arch@c96a0388bda047c2b09ad3798b34e990567d7f84/Toolchain/libemp.js?v=200"

export async function loadFile(fnam) {
  const url = new URL(fnam, import.meta.url)
  const txt = await fetch(url).then(r => r.text())
  return txt;
}
let pxclrs = ['#000','#888','#800','#740','#880','#680','#228','#508','#444','#ddd','#f44','#d80','#cc0','#9f4','#aae','#548']
let video = document.getElementById('video');
if (!(video instanceof HTMLCanvasElement)) throw new Error('not valid');

let videoctx = video.getContext('2d');
let pxclr = pxclrs[Math.ceil(Math.random() * pxclrs.length)];
let pxi = 0;
let pxrclrm = 50;
let pxnxtm = 120;
let pxnxt = pxnxtm;
let pxrclr = pxrclrm;
let rtins = 0;
let mmask = 0x1FFF;
let ram0 = new Array(0xD0-0x50).fill(0);
let pxline_pulse = 0; 

let px_px = 0;
let px_py = 0;
let px_wy = 75;
let px_wx = 100;
let px_idle = true;
let px_idle2 = false;
let px_rmem = 100;
let px_rme = px_rmem;
let px_rmfm = 50;
let px_rmf = px_rmfm;

function VideoStep() {
    let old_px = px_px + 1;

    videoctx.fillStyle = pxclr;
    videoctx.fillRect(px_px, px_py, 1, 1);

    px_px = (px_px + 1) % (px_wx + 1);
    px_rmf = px_rmfm;
    px_idle2 = true;

    if (old_px != px_px) {
        let old_py = px_py + 1;
        px_py = (px_py + 1) % px_wy;

        if (old_py != px_py) {
            px_idle = true;
            px_rme = px_rmem;
        }
    }
}

function VideoStepper() {
    if (px_idle) {
        px_rme--;
        if (px_rme == 0) {
            px_idle = false;
            InitializeFrame();
        }
    }
    else {
        px_rmf--;
        if (px_rmf == 0) {
            px_idle2 = false;
            VideoStep();
        }
    }
}

function pxlf(){
    if (px_idle2) {
        let n = Number((px_px == (px_wx)));
        px_idle2 = false;
        return n;
    }
    return 0;
}
function pxlc() {
    return Number(px_idle);
}

let cpu = new emp.cpuGen2();
let rom = emp.g2asm.parseAsm(await loadFile('./fd.asm')).result
let pc;
console.log(rom);

// Frame Initializator
function InitializeFrame() {
    console.log('frame')

    pc = ReadBus16(0x1FFA);
    pxi = 0;
}

// Write Bus 8 bit
function WriteBus8(_adr, val) {
    let adr = _adr & mmask;

    if (adr == 0xD0)
        pxclr = pxclrs[val % pxclrs.length];
    if (adr == 0xD1)
        pxrclr = 1;

    if (adr >= 0x50 && adr < (0x50 + (ram0.length - 1)))
        ram0[adr - 0x50] = val;
}

// Write Bus General
function WriteBus(adr, val) {
    WriteBus8(adr, val);
}

// Read Bus 8 bit
function ReadBus8(_adr) {
    let adr = _adr & mmask;

    if (adr >= 0x1000 && adr <= 0x1FFF)
        return rom[adr - 0x1000];

    if (adr == 0xD2) 
        return pxlc();

    if (adr == 0xD3)
        return pxlf();

    if (adr >= 0x50 && adr <= (0x50 + (ram0.length - 1)))
        return ram0[adr - 0x50];

    return 0;
}

// Read Bus General
function ReadBus(adr) {
    return ReadBus8(adr);
}

// Read Bus 16 bit
function ReadBus16(adr) {
    return ((ReadBus8(adr) << 8) | ReadBus8(adr+1));
}

// Instruction Fetcher
function FetchInstruction(adr) {
    return ReadBus16(adr);
}

cpu.rest = (a) => { 
    pc = ReadBus16(0x1FFE);
    cpu.rst();
}
cpu.jf = (adr) => {
    pc = adr - ((rtins & 0x800000) == 0x800000 ? 3 : 2);
}
cpu.rex = ReadBus;
cpu.wex = WriteBus;

cpu.rest()

function CpuStepper() {
    try {
    let ins = [cpu.rex(pc), cpu.rex(pc+1), cpu.rex(pc+2)];
    rtins = ((ins[0] << 16) | (ins[1] << 8) | ins[2])

    let rta = (rtins & 0x800000) == 0x800000 ? ins.slice(0, 3) : ins.slice(0, 2);
    let ab = pc.toString(16).padStart(4, '0').toUpperCase() + ' ' + rta.map(v => v.toString(16).padStart(2,'0')).join('').toUpperCase().padEnd(8, ' ') +  emp.g2asm.LineDisasm(ins)+ "\n";
    ab = `${ab} GPU#${pxnxt}`
    //console.log(ab)
    
    let ia = cpu.exi(rtins);
    pc = pc + ia;
    } catch (e) {
    }
}

function PyshicStep() {
    CpuStepper();
    VideoStepper();
}

window.PyshicStep = PyshicStep

setInterval(function () {
    let i = 1000;
    while (i--) {
        PyshicStep()
    }
}, 50)