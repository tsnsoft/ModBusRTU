program ModBusRTU;

uses
  Vcl.Forms,
  Unit_main in 'Unit_main.pas' {Form1},
  Vcl.Themes,
  Vcl.Styles,
  Unit_CRC16_ModBus in 'Unit_CRC16_ModBus.pas',
  Unit_utils in 'Unit_utils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Cyan Night');
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
