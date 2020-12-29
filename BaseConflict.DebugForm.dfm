object Form2: TForm2
  Left = 2000
  Top = 0
  Caption = 'Form2'
  ClientHeight = 337
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object OutputLabel: TLabel
    Left = 16
    Top = 16
    Width = 59
    Height = 13
    Caption = 'OutputLabel'
  end
  object OutputMemo: TMemo
    Left = 336
    Top = 8
    Width = 291
    Height = 289
    TabOrder = 0
  end
  object DebugTrack: TTrackBar
    Left = 8
    Top = 303
    Width = 619
    Height = 26
    Max = 600
    Position = 300
    TabOrder = 1
    TickMarks = tmBoth
    TickStyle = tsNone
    OnChange = DebugTrackChange
  end
  object DebugValueEdit: TEdit
    Left = 16
    Top = 272
    Width = 121
    Height = 21
    TabOrder = 2
    Text = '0'
  end
  object PrintBtn: TButton
    Left = 240
    Top = 128
    Width = 75
    Height = 25
    Caption = '=>'
    TabOrder = 3
  end
  object ValueMinEdit: TEdit
    Left = 24
    Top = 224
    Width = 121
    Height = 21
    TabOrder = 4
    Text = '0'
    OnChange = ValueMinEditChange
  end
  object ValueMaxEdit: TEdit
    Left = 160
    Top = 224
    Width = 121
    Height = 21
    TabOrder = 5
    Text = '1'
    OnChange = ValueMinEditChange
  end
end
