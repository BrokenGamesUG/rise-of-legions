object PostEffectDebugForm: TPostEffectDebugForm
  Left = 1035
  Top = 57
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsToolWindow
  Caption = 'PostEffects'
  ClientHeight = 600
  ClientWidth = 400
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
  object PostEffectList: TListBox
    Left = 0
    Top = 0
    Width = 400
    Height = 265
    Align = alTop
    ItemHeight = 13
    PopupMenu = ListPopupMenu
    TabOrder = 0
    OnClick = BigChange
  end
  object PostEffectOptionPanel: TScrollBox
    Left = 0
    Top = 265
    Width = 400
    Height = 335
    Align = alClient
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    TabOrder = 1
  end
  object OpenDialog: TOpenDialog
    DefaultExt = 'fxs'
    Filter = 'Effect-Stack (.fxs)|*.fxs|All Files (.*)|*.*'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 272
    Top = 24
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'fxs'
    Filter = 'Effect-Stack (.fxs)|*.fxs|All Files (.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Left = 336
    Top = 24
  end
  object ListPopupMenu: TPopupMenu
    Left = 272
    Top = 96
    object ListAddList: TMenuItem
      Caption = 'Add'
      object TMenuItem
      end
    end
    object ListDeleteBtn: TMenuItem
      Caption = 'Delete'
      OnClick = BigChange
    end
    object ListMoveUpBtn: TMenuItem
      Caption = 'MoveUp'
      OnClick = BigChange
    end
    object ListMoveDownBtn: TMenuItem
      Caption = 'MoveDown'
      OnClick = BigChange
    end
    object ListRenameBtn: TMenuItem
      Caption = 'Rename'
      OnClick = BigChange
    end
  end
  object MainMenu: TMainMenu
    Left = 336
    Top = 96
    object File1: TMenuItem
      Caption = 'File'
      object NewBtn: TMenuItem
        Caption = 'New'
        OnClick = BigChange
      end
      object LoadBtn: TMenuItem
        Caption = 'Load'
        OnClick = BigChange
      end
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
