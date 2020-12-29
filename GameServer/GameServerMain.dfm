object Form1: TForm1
  Left = 62
  Top = 107
  BorderIcons = [biSystemMenu]
  Caption = 'Server'
  ClientHeight = 508
  ClientWidth = 528
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pnl1: TPanel
    Left = 371
    Top = 0
    Width = 157
    Height = 508
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 8
      Width = 78
      Height = 13
      Caption = 'Games Running:'
    end
    object NetworkDisplay: TLabel
      Left = 10
      Top = 36
      Width = 74
      Height = 13
      Caption = 'NetworkDisplay'
    end
    object StatusDisplay: TLabel
      Left = 10
      Top = 175
      Width = 54
      Height = 13
      Caption = 'StatDisplay'
    end
    object GamesRunningEdt: TEdit
      Left = 92
      Top = 5
      Width = 57
      Height = 21
      Enabled = False
      ReadOnly = True
      TabOrder = 0
      Text = '0'
    end
    object KillAllGamesBtn: TButton
      Left = 6
      Top = 447
      Width = 145
      Height = 25
      Caption = 'Kill all Games'
      TabOrder = 1
      OnClick = KillAllGamesBtnClick
    end
    object CheatCheck: TCheckBox
      Left = 6
      Top = 424
      Width = 201
      Height = 17
      Caption = 'Cheats (for new games)'
      TabOrder = 2
      OnClick = CheatCheckClick
    end
    object BreakOnExceptionCheck: TCheckBox
      Left = 6
      Top = 408
      Width = 201
      Height = 17
      Caption = 'Break on Exception'
      TabOrder = 3
      OnClick = BreakOnExceptionCheckClick
    end
    object SendGameTickBtn: TButton
      Left = 6
      Top = 478
      Width = 147
      Height = 25
      Caption = 'Send GameTick'
      TabOrder = 4
      OnClick = SendGameTickBtnClick
    end
    object LoadBalancingButton: TButton
      Left = 6
      Top = 359
      Width = 147
      Height = 27
      Caption = 'Load balancing'
      TabOrder = 5
      WordWrap = True
      OnClick = LoadBalancingButtonClick
    end
    object OverwatchChecked: TCheckBox
      Left = 6
      Top = 392
      Width = 201
      Height = 17
      Caption = 'Overwatch'
      TabOrder = 6
      OnClick = OverwatchCheckedClick
    end
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 371
    Height = 508
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object EventCounterDisplay: TValueListEditor
      Left = 0
      Top = 217
      Width = 371
      Height = 291
      TabStop = False
      Align = alClient
      DrawingStyle = gdsClassic
      Enabled = False
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine]
      TabOrder = 0
      TitleCaptions.Strings = (
        'GameID'
        'Meta-Data')
      OnSelectCell = EventCounterDisplaySelectCell
      ColWidths = (
        216
        149)
      RowHeights = (
        18
        18)
    end
    object LogList: TListBox
      Left = 0
      Top = 0
      Width = 371
      Height = 217
      Align = alTop
      ItemHeight = 13
      ScrollWidth = 2000
      TabOrder = 1
    end
  end
  object ApplicationEvents1: TApplicationEvents
    OnIdle = ApplicationEvents1Idle
    Left = 120
    Top = 24
  end
  object HttpServer: TIdHTTPServer
    Bindings = <>
    OnCommandOther = HttpServerCommandOther
    OnCommandGet = HttpServerCommandOther
    Left = 40
    Top = 16
  end
  object ExcelFileOpenDialog: TOpenDialog
    Filter = 'Excel|*.xls; *.xlsx|All Files|*.*'
    FilterIndex = 0
    InitialDir = '..\Dokumente\Base Conflict'
    Left = 208
    Top = 24
  end
end
