object ToolWindow: TToolWindow
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Map-Tools'
  ClientHeight = 930
  ClientWidth = 330
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Visible = True
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object ToolBox: TCategoryPanelGroup
    Left = 0
    Top = 0
    Width = 330
    Height = 930
    VertScrollBar.Position = 773
    VertScrollBar.Tracking = True
    Align = alClient
    HeaderFont.Charset = DEFAULT_CHARSET
    HeaderFont.Color = clWindowText
    HeaderFont.Height = -11
    HeaderFont.Name = 'Tahoma'
    HeaderFont.Style = []
    TabOrder = 0
    object ZonePanel: TCategoryPanel
      Top = 672
      Height = 256
      Caption = 'Zones'
      TabOrder = 0
      object Label7: TLabel
        Left = 8
        Top = 176
        Width = 232
        Height = 13
        Caption = 'Left Shift while setting first node => subtractive'
      end
      object ZoneList: TListBox
        Left = 8
        Top = 32
        Width = 289
        Height = 137
        ItemHeight = 13
        TabOrder = 0
        OnClick = BigChange
        OnDblClick = ZoneListDblClick
      end
      object ZoneEdit: TEdit
        Left = 8
        Top = 5
        Width = 162
        Height = 21
        TabOrder = 1
        OnClick = BigChange
      end
      object ZoneAddBtn: TButton
        Left = 176
        Top = 4
        Width = 113
        Height = 22
        Caption = 'Add Zone'
        TabOrder = 2
        OnClick = BigChange
      end
      object ZoneExportBtn: TButton
        Left = 8
        Top = 195
        Width = 289
        Height = 25
        Caption = 'Export'
        TabOrder = 3
        OnClick = BigChange
      end
    end
    object ReferenceEntitiesTab: TCategoryPanel
      Top = 160
      Height = 512
      Caption = 'Reference entities'
      TabOrder = 1
      object Label10: TLabel
        Left = 0
        Top = 0
        Width = 309
        Height = 13
        Align = alTop
        Caption = 'Pattern'
        ExplicitWidth = 36
      end
      object Label11: TLabel
        Left = 0
        Top = 302
        Width = 309
        Height = 13
        Align = alBottom
        Caption = 'Existing reference entities'
        ExplicitWidth = 125
      end
      object ReferenceEntityPatternList: TListBox
        Left = 0
        Top = 13
        Width = 309
        Height = 289
        Align = alClient
        Columns = 2
        ItemHeight = 13
        TabOrder = 0
        OnClick = BigChange
      end
      object ReferenceEntitiesList: TListBox
        Left = 0
        Top = 315
        Width = 309
        Height = 154
        Align = alBottom
        Columns = 2
        ItemHeight = 13
        PopupMenu = ReferencePopupMenu
        TabOrder = 1
        OnClick = BigChange
      end
      object FreezeReferenceCheck: TCheckBox
        Left = 0
        Top = 469
        Width = 309
        Height = 17
        Align = alBottom
        Caption = 'Freeze all Reference Entities'
        Checked = True
        State = cbChecked
        TabOrder = 2
        OnClick = BigChange
      end
    end
    object DecoTab: TCategoryPanel
      Top = -540
      Height = 700
      Caption = 'Decoration'
      TabOrder = 2
      object Label5: TLabel
        Left = 0
        Top = 0
        Width = 309
        Height = 13
        Align = alTop
        Caption = 'DecoPattern'
        ExplicitWidth = 60
      end
      object Label6: TLabel
        Left = 0
        Top = 234
        Width = 309
        Height = 13
        Align = alTop
        Caption = 'ExistingDecoObjects'
        ExplicitWidth = 98
      end
      object DecoUnitsList: TListBox
        Left = 0
        Top = 13
        Width = 309
        Height = 201
        Align = alTop
        Columns = 2
        ItemHeight = 13
        TabOrder = 0
        OnClick = BigChange
      end
      object ExistingDecoList: TListBox
        Left = 0
        Top = 247
        Width = 309
        Height = 201
        Align = alClient
        Columns = 2
        ItemHeight = 13
        MultiSelect = True
        TabOrder = 1
        OnClick = BigChange
      end
      object DecoPatternRefreshBtn: TButton
        Left = 0
        Top = 214
        Width = 309
        Height = 20
        Align = alTop
        Caption = 'Refresh'
        TabOrder = 2
      end
      object DecoValueGroup: TGroupBox
        Left = 0
        Top = 531
        Width = 309
        Height = 143
        Align = alBottom
        Caption = 'Deco Values'
        TabOrder = 3
        Visible = False
        object Label12: TLabel
          Left = 19
          Top = 24
          Width = 37
          Height = 13
          Caption = 'Position'
        end
        object Label13: TLabel
          Left = 146
          Top = 24
          Width = 41
          Height = 13
          Caption = 'Rotation'
        end
        object Label14: TLabel
          Left = 146
          Top = 72
          Width = 19
          Height = 13
          Caption = 'Size'
        end
        object DecoValuePositionXEdit: TEdit
          Left = 19
          Top = 43
          Width = 121
          Height = 21
          TabOrder = 0
          Text = '0'
          OnChange = BigChange
        end
        object DecoValuePositionYEdit: TEdit
          Left = 19
          Top = 67
          Width = 121
          Height = 21
          TabOrder = 1
          Text = '0'
          OnChange = BigChange
        end
        object DecoValuePositionZEdit: TEdit
          Left = 19
          Top = 91
          Width = 121
          Height = 21
          TabOrder = 2
          Text = '0'
          OnChange = BigChange
        end
        object DecoValueRotationEdit: TEdit
          Left = 146
          Top = 43
          Width = 121
          Height = 21
          TabOrder = 3
          Text = '0'
          OnChange = BigChange
        end
        object DecoValueSizeEdit: TEdit
          Left = 146
          Top = 91
          Width = 121
          Height = 21
          TabOrder = 4
          Text = '0'
          OnChange = BigChange
        end
        object DecoValueFreezeCheck: TCheckBox
          Left = 19
          Top = 117
          Width = 97
          Height = 17
          Caption = 'Frozen'
          TabOrder = 5
          OnClick = BigChange
        end
      end
      object Memo1: TMemo
        Left = 0
        Top = 448
        Width = 309
        Height = 83
        Align = alBottom
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        Color = clMenu
        Lines.Strings = (
          'Adjustments after setting '
          'Translation - Move while selected '
          'Rotation - Hold Shift while moving '
          'Scaling - Hold AltGr while moving'
          ' X-Axis - Hold X while moving '
          'Y-Axis - Hold Y while moving '
          'Z-Axis - Hold Z while moving '
          'Duplication - Press Strg + D '
          'Toggle Freeze - Press F')
        ReadOnly = True
        TabOrder = 4
      end
    end
    object LaneTab: TCategoryPanel
      Top = -700
      Height = 160
      Caption = 'Lanes'
      TabOrder = 3
      object PlaceLaneSpeed: TSpeedButton
        Left = 0
        Top = 97
        Width = 309
        Height = 32
        Align = alTop
        AllowAllUp = True
        GroupIndex = 1
        Caption = 'Place Lane'
        OnClick = BigChange
        ExplicitWidth = 290
      end
      object LanesList: TListBox
        Left = 0
        Top = 0
        Width = 309
        Height = 97
        Align = alTop
        Columns = 3
        ItemHeight = 13
        TabOrder = 0
        OnClick = BigChange
      end
    end
    object GeneralTab: TCategoryPanel
      Top = -773
      Height = 73
      Caption = 'General'
      TabOrder = 4
      object Label1: TLabel
        Left = 8
        Top = 16
        Width = 58
        Height = 13
        Caption = 'Max players'
      end
      object Label2: TLabel
        Left = 160
        Top = 16
        Width = 56
        Height = 13
        Caption = 'Team count'
      end
      object MaxPlayerEdit: TSpinEdit
        Left = 83
        Top = 7
        Width = 57
        Height = 33
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Verdana'
        Font.Style = [fsBold]
        MaxValue = 64
        MinValue = 1
        ParentFont = False
        TabOrder = 0
        Value = 10
        OnChange = BigChange
      end
      object TeamCountEdit: TSpinEdit
        Left = 235
        Top = 7
        Width = 57
        Height = 33
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Verdana'
        Font.Style = [fsBold]
        MaxValue = 64
        MinValue = 1
        ParentFont = False
        TabOrder = 1
        Value = 2
      end
    end
  end
  object ReferencePopupMenu: TPopupMenu
    Left = 112
    Top = 581
    object CopyEntitiesToClipboardBtn: TMenuItem
      Caption = 'Copy Entities to Clipboard'
      OnClick = CopyEntitiesToClipboardBtnClick
    end
  end
  object ZoneSaveDialog: TSaveDialog
    DefaultExt = '.obj'
    Filter = 'OBJ-File (*.obj)|*.obj'
    Left = 160
    Top = 816
  end
end
