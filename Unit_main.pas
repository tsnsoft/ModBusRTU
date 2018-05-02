unit Unit_main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Math, System.UITypes;

const
  MAX_BUFFER_LENGTH = 100; // Размер буфера для работы с ModBus RTU

type
  ARR_BYTE = array [1 .. MAX_BUFFER_LENGTH] of byte; // Тип буфера для работы с ModBus RTU

type
  TForm1 = class(TForm)
    Button_ConnectOn: TButton;
    Timer_Polling: TTimer;
    Memo_Data: TMemo;
    Button_ConnectOff: TButton;
    RadioGroup_TypeRead: TRadioGroup;
    procedure Button_ConnectOnClick(Sender: TObject);
    procedure Timer_PollingTimer(Sender: TObject);
    procedure Button_ConnectOffClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    function InitPort(var h: Thandle; cport: string; access: dword): boolean;
    procedure ClosePort(var h: Thandle);
    function decoderParamFromPocketMB(numParam: word; sizeParam: word): string;
    procedure InitParam(typeParam: word);
    procedure RadioGroup_TypeReadClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

const
  COM_PORT = 'COM7'; // Имя COM-порта для чтения

  FDCB: dcb = (BaudRate: 9600; ByteSize: 8; Parity: NOPARITY; Stopbits: TWOSTOPBITS); // Настройки соединения

  TOUT: CommTimeouts = (ReadIntervalTimeout: 15; ReadTotalTimeoutConstant: 70;
    WriteTotalTimeoutMultiplier: 15; WriteTotalTimeoutConstant: 60); // Таймауты связи

  D_DEMO_COIL = 0; // Демонстрация чтения флагов
  D_DEMO_REGISTER_WORD = 1; // Демонстрация чтения регистров со словами
  D_DEMO_REGISTER_SINGLE = 2; // Демонстрация чтения регистров с вещественными числами

  C_COIL = 0; // Условный размер типа флага ModBus RTU в ячейках (двухбайтовых)
  C_WORD = 1; // Размер типа слова ModBus RTU в ячейках (двухбайтовых)
  C_SINGLE = 2; // Размер типа вещественного числа ModBus RTU в ячейках (двухбайтовых)

  R_COIL = 1;  // Команда чтения флагов ячеек ModBus RTU
  R_REGISTER = 3; // Команда чтения регистров ячеек ModBus RTU

  NUMBER_FLAGS = 56; // Количество флагов для чтения

  INQUIRY_BUFFER_LENGTH = 8; // Размер буфера для работы с ModBus RTU
  MAX_RESPONSE_BUFFER_LENGTH = 1000; // Максимальный размер буфера для ответа ModBus RTU

var
  Form1: TForm1;

  hh: Thandle = 0; // Хэндл COM-порта для записи

  READ_COMMAND: word; // Код команды чтения данных
  SIZE_PARAMETER: word; // Размер параметров
  NUMBER_PARAMETERS: word; // Количество параметров
  NUMBER_DATA: word; // Количество данных
  LENGTH_DATA: word; // Размер данных
  RESPONSE_BUFFER_LENGTH: word; // Размер буфера для ответа ModBus RTU

  RESPONSE_FROM_PORT: array [1 .. MAX_RESPONSE_BUFFER_LENGTH] of byte; // Ответ с ModBus RTU

  INQUIRY_PORT: array [1 .. INQUIRY_BUFFER_LENGTH] of byte = ( // Массив запроса с устройства
    01, // Номер устройства
    00, // Код команды чтения
    00, // Начальный адрес ячейки для чтения (старший байт)
    00, // Начальный адрес ячейки для чтения  (младший байт)
    00,  // Количество ячеек для чтения (старший байт)
    00, // Количество ячеек/флагов для чтения (младший байт)
    00,  // CRC16 ModBus RTU (младший байт)
    00   // CRC16 ModBus RTU (старший байт)
  );

implementation

{$R *.dfm}

uses Unit_CRC16_ModBus, Unit_utils;

procedure TForm1.InitParam(typeParam: word);
// Инициализация параметров запросов ModBus RTU
begin
  if  typeParam = D_DEMO_COIL then begin
    READ_COMMAND := R_COIL; // Код чтения флагов ModBus RTU
    SIZE_PARAMETER := C_COIL; // Размер параметра в ячейках
  end;

  if NUMBER_FLAGS mod 8 = 0 then begin
    NUMBER_PARAMETERS := (NUMBER_FLAGS div 8); // Количество считываемых параметров с флагами
  end else begin
    NUMBER_PARAMETERS := (NUMBER_FLAGS div 8) +1; // Количество считываемых параметров с флагами
  end;

  if typeParam = D_DEMO_REGISTER_WORD then begin
     READ_COMMAND := R_REGISTER; // Код чтения регистров ModBus RTU
     SIZE_PARAMETER := C_WORD; // Размер параметра в ячейках
     NUMBER_PARAMETERS := 10; // Количество считываемых параметров
  end;

  if typeParam = D_DEMO_REGISTER_SINGLE then begin
    READ_COMMAND := R_REGISTER; // Код чтения регистров ModBus RTU
    SIZE_PARAMETER := C_SINGLE; // Размер параметра в ячейках
    NUMBER_PARAMETERS := 10; // Количество считываемых параметров
  end;

  if typeParam = C_COIL then begin
    NUMBER_DATA := NUMBER_FLAGS; // Количество считываемых флагов
    LENGTH_DATA := (NUMBER_FLAGS div 8) +1; // Размер считываемых байт
  end else begin
    NUMBER_DATA := NUMBER_PARAMETERS * SIZE_PARAMETER; // Количество считываемых ячеек
    LENGTH_DATA := NUMBER_DATA * 2; // Размер считываемых ячеек в байтах
  end;

  RESPONSE_BUFFER_LENGTH := 5 + LENGTH_DATA; // Размер буфера для ответа ModBus RTU

  INQUIRY_PORT[2] := READ_COMMAND; // Команда чтения данных

  INQUIRY_PORT[6] := NUMBER_DATA; // Количество считываемых данных
end;

function TForm1.InitPort(var h: Thandle; cport: string; access: dword): boolean;
// Инициализация подключения к COM-порту
var port: string; err_code: integer;
begin
  port := '\\.\' + cport; InitPort := false;
  if h <> 0 then Closehandle(h);
  h := CreateFile(Pchar(port), access, 0, Nil, OPEN_EXISTING, 0, 0);
  SetCommState(h, FDCB);
  SetCommTimeouts(h, TOUT);
  if h = high(h) then begin
    Closehandle(h); err_code := GetLastError;
    case err_code of
      5: begin
          MessageDlg('К порту ' + cport + ' доступ запрещен.' + #13#10 +
            'Дескриптор порта=' + InttoStr(h), mtError, [mbOK], 0);
        end;
      6: begin
          MessageDlg('Порт ' + cport +
            ' не существует или занят другой программой.' + #13#10 +
            'Дескриптор порта=' + InttoStr(h), mtError, [mbOK], 0);
        end;
    end;
  end else InitPort := true;
end;

procedure TForm1.RadioGroup_TypeReadClick(Sender: TObject);
// Инициализация параметров режима чтения данных
begin
  Memo_Data.Clear;
  InitParam(RadioGroup_TypeRead.ItemIndex);
end;

procedure TForm1.ClosePort(var h: Thandle);
// Откключение от COM-порта
begin
  if h <> 0 then begin
    PurgeComm(h, PURGE_TXABORT or PURGE_RXABORT or PURGE_TXCLEAR or PURGE_RXCLEAR);
    Closehandle(h); h := 0;
  end;
end;

procedure TForm1.Button_ConnectOnClick(Sender: TObject);
// Подключение к COM-портам
begin
  Memo_Data.Lines.Clear;
  InitParam(RadioGroup_TypeRead.ItemIndex);
  if InitPort(hh, COM_PORT, GENERIC_READ OR GENERIC_WRITE) then Timer_Polling.Enabled := true;
end;

procedure TForm1.Timer_PollingTimer(Sender: TObject);
// Чтение данных с COM-порта
var bytesReceived: cardinal; bytesTransmitted: cardinal; numParam: integer; data: dword;
begin
  PurgeComm(hh, PURGE_TXABORT or PURGE_TXCLEAR);

  EscapeCommFunction(hh, SETRTS);

  data := CRC16(@INQUIRY_PORT, 6);

  INQUIRY_PORT[7] := lo(data); // CRC16
  INQUIRY_PORT[8] := hi(data); // CRC16

  WriteFile(hh, INQUIRY_PORT, INQUIRY_BUFFER_LENGTH, bytesTransmitted, nil); sleep(20);

  EscapeCommFunction(hh, CLRRTS);
  ReadFile(hh, RESPONSE_FROM_PORT, RESPONSE_BUFFER_LENGTH, bytesReceived, nil);

  if (bytesReceived = RESPONSE_BUFFER_LENGTH) AND (RESPONSE_FROM_PORT[3] = LENGTH_DATA) then begin
    Memo_Data.Lines.Clear;
    Memo_Data.Lines.Add('Пакет с запросом: [' +
      ConvertArrByteToStr(INQUIRY_PORT, length(INQUIRY_PORT))+']');
    Memo_Data.Lines.Add('Пакет с ответом: [' +
      ConvertArrByteToStr(RESPONSE_FROM_PORT, RESPONSE_BUFFER_LENGTH)+']');
    Memo_Data.Lines.Add('');
    Memo_Data.Lines.Add('Декодированные значения данных:');
    for numParam := 0 to NUMBER_PARAMETERS - 1 do begin
      Memo_Data.Lines.Add('data' + inttostr(numParam + 1) + '=' +
        decoderParamFromPocketMB(numParam, SIZE_PARAMETER));
    end;
  end else begin
    Memo_Data.Lines.Clear; Memo_Data.Lines.Add('ожидание данных ...');
  end;
  Application.ProcessMessages;
end;

procedure TForm1.Button_ConnectOffClick(Sender: TObject);
// Отключение от COM-портов
begin
  Timer_Polling.Enabled := false;
  Memo_Data.Clear;
  ClosePort(hh); ClosePort(hh);
end;

function TForm1.decoderParamFromPocketMB(numParam: word; sizeParam: word): string;
// Декодер параметра из пакета ответа ModBus RTU
var offset: integer; byte1, byte2, byte3, byte4: byte; data: dword; rdata: single;
begin
  result := '';
  if SIZE_PARAMETER > 0 then offset := numParam * SIZE_PARAMETER * 2 else offset := numParam;
  case sizeParam of
    C_COIL: begin
        byte1 := RESPONSE_FROM_PORT[4 + offset];
        result := InttoStr(byte1) + ' ($' + inttohex(byte1,2) + ')';
      end;
    C_WORD: begin
        byte1 := RESPONSE_FROM_PORT[5 + offset];
        byte2 := RESPONSE_FROM_PORT[4 + offset];
        data := byteToWord(byte1, byte2);
        result := InttoStr(data) + ' ($' + inttohex(data,2) + ')';
      end;
    C_SINGLE: begin
        byte1 := RESPONSE_FROM_PORT[7 + offset];
        byte2 := RESPONSE_FROM_PORT[6 + offset];
        byte3 := RESPONSE_FROM_PORT[5 + offset];
        byte4 := RESPONSE_FROM_PORT[4 + offset];
        rdata := byteToReal(byte1, byte2, byte3, byte4);
        if Math.IsNan(rdata) or Math.IsInfinite(rdata) then
           result :='нет значения' else
           result := formatfloat('######0.000', rdata);
      end;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
// Выход из программы
begin
  Button_ConnectOffClick(Sender);
end;

end.
