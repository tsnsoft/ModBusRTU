unit Unit_CRC16_ModBus;

interface

function CRC16(buf: pointer; size: word): word;

implementation

uses SysUtils;

const P_16 = $A001;

var crc_tab16: array [0 .. 255] of word;

procedure init_crc16_tab;
var i, j, crc, c: word;
begin
  for i := 0 to 255 do begin
    crc := 0; c := i;
    for j := 0 to 7 do begin
      if (crc xor c) and 1 = 1 then crc := (crc shr 1) xor P_16 else crc := crc shr 1;
      c := c shr 1;
    end;
    crc_tab16[i] := crc;
  end;
end;

function update_crc_16(crc, c: word): word;
var tmp: word;
begin
  tmp := crc xor c;
  crc := (crc shr 8) xor crc_tab16[tmp and $FF];
  Result := crc;
end;

function CRC16(buf: pointer; size: word): word;
var i, crc_16_modbus: word;
begin
  init_crc16_tab;
  crc_16_modbus := $FFFF;
  for i := 0 to size - 1 do crc_16_modbus := update_crc_16(crc_16_modbus, pbytearray(buf)^[i]);
  Result := crc_16_modbus;
end;

end.
