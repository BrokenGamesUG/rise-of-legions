object MeshEditorForm: TMeshEditorForm
  Left = 1035
  Top = 57
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSizeToolWin
  Caption = 'Mesh Editor'
  ClientHeight = 633
  ClientWidth = 390
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  Menu = MainMenu
  OldCreateOrder = False
  ScreenSnap = True
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object MeshBox: TScrollBox
    Left = 0
    Top = 0
    Width = 390
    Height = 633
    Align = alClient
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    TabOrder = 0
    object MeshPanel: TPanel
      Left = 0
      Top = 0
      Width = 373
      Height = 1200
      Align = alTop
      BevelOuter = bvNone
      Padding.Left = 10
      Padding.Top = 10
      Padding.Right = 10
      Padding.Bottom = 10
      TabOrder = 0
    end
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'xml'
    Filter = 'Mesh-File (*.xml)|*.xml|All Files (*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 336
    Top = 24
  end
  object MainMenu: TMainMenu
    Left = 336
    Top = 96
    object File1: TMenuItem
      Caption = 'File'
      object SaveBtn: TMenuItem
        Caption = 'Save'
        OnClick = BigChange
      end
      object SaveAsBtn: TMenuItem
        Caption = 'Save As'
        OnClick = BigChange
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object CloseBtn: TMenuItem
        Caption = 'Close'
        OnClick = BigChange
      end
    end
  end
end
