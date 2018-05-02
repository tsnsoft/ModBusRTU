object Form1: TForm1
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'ModBusRTU, ver. 3.0 [TS]'
  ClientHeight = 463
  ClientWidth = 485
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 120
  TextHeight = 16
  object Button_ConnectOn: TButton
    Left = 24
    Top = 383
    Width = 441
    Height = 33
    Caption = #1053#1072#1095#1072#1090#1100' '#1086#1087#1088#1086#1089
    TabOrder = 0
    OnClick = Button_ConnectOnClick
  end
  object Memo_Data: TMemo
    Left = 24
    Top = 8
    Width = 441
    Height = 313
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object Button_ConnectOff: TButton
    Left = 24
    Top = 424
    Width = 441
    Height = 32
    Caption = #1054#1089#1090#1072#1085#1086#1074#1080#1090#1100' '#1086#1087#1088#1086#1089
    TabOrder = 2
    OnClick = Button_ConnectOffClick
  end
  object RadioGroup_TypeRead: TRadioGroup
    Left = 32
    Top = 327
    Width = 433
    Height = 42
    Caption = #1056#1077#1078#1080#1084' '#1095#1090#1077#1085#1080#1103' '#1076#1072#1085#1085#1099#1093
    Columns = 3
    ItemIndex = 0
    Items.Strings = (
      'coil'
      'word'
      'single')
    TabOrder = 3
    OnClick = RadioGroup_TypeReadClick
  end
  object Timer_Polling: TTimer
    Enabled = False
    OnTimer = Timer_PollingTimer
    Left = 120
    Top = 72
  end
end
