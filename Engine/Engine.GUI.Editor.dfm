object GUIDebugForm: TGUIDebugForm
  Left = 523
  Top = 103
  Caption = 'GUIDebugForm'
  ClientHeight = 758
  ClientWidth = 700
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  Menu = MainMenu1
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Column2Panel: TPanel
    Left = 350
    Top = 0
    Width = 350
    Height = 758
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 0
    object Label5: TLabel
      Left = 0
      Top = 0
      Width = 350
      Height = 13
      Align = alTop
      Caption = 'Classes'
      ExplicitWidth = 36
    end
    object ClassesMemo: TMemo
      Left = 0
      Top = 13
      Width = 350
      Height = 51
      Align = alTop
      TabOrder = 0
      OnChange = ClassesMemoChange
    end
    object Panel2: TPanel
      Left = 0
      Top = 64
      Width = 350
      Height = 694
      Align = alClient
      TabOrder = 1
      object DomTree: TTreeView
        Left = 1
        Top = 25
        Width = 348
        Height = 668
        Align = alClient
        DragMode = dmAutomatic
        HideSelection = False
        Indent = 19
        PopupMenu = TreePopUp
        TabOrder = 0
        OnClick = DomTreeClick
        OnDragDrop = DomTreeDragDrop
        OnDragOver = DomTreeDragOver
        OnEdited = DomTreeEdited
        OnMouseDown = DomTreeMouseDown
      end
      object Panel4: TPanel
        Left = 1
        Top = 1
        Width = 348
        Height = 24
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        object TreeExpandAllBtn: TButton
          Left = 75
          Top = 0
          Width = 75
          Height = 24
          Align = alLeft
          Caption = 'Expand All'
          TabOrder = 0
          OnClick = TreeExpandSubBtnClick
        end
        object TreeCollapseAllBtn: TButton
          Left = 0
          Top = 0
          Width = 75
          Height = 24
          Align = alLeft
          Caption = 'Collapse All'
          TabOrder = 1
          OnClick = TreeExpandSubBtnClick
        end
        object TreeCollapseSubBtn: TButton
          Left = 150
          Top = 0
          Width = 75
          Height = 24
          Align = alLeft
          Caption = 'Collapse Other'
          TabOrder = 2
          OnClick = TreeExpandSubBtnClick
        end
        object TreeExpandSubBtn: TButton
          Left = 225
          Top = 0
          Width = 75
          Height = 24
          Align = alLeft
          Caption = 'Expand Sub'
          TabOrder = 3
          OnClick = TreeExpandSubBtnClick
        end
      end
    end
  end
  object Column1Panel: TPanel
    Left = 0
    Top = 0
    Width = 350
    Height = 758
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object Label4: TLabel
      Left = 0
      Top = 406
      Width = 81
      Height = 13
      Align = alTop
      Caption = 'Computed Styles'
    end
    object Panel1: TPanel
      Left = 0
      Top = 0
      Width = 350
      Height = 257
      Align = alTop
      TabOrder = 0
      object Label1: TLabel
        Left = 1
        Top = 1
        Width = 44
        Height = 13
        Align = alTop
        Caption = 'Template'
      end
      object TemplateBox: TMemo
        Left = 1
        Top = 14
        Width = 348
        Height = 207
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Courier New'
        Font.Pitch = fpFixed
        Font.Style = []
        Font.Quality = fqClearType
        ParentFont = False
        TabOrder = 0
        WantTabs = True
        WordWrap = False
        OnChange = TemplateBoxChange
      end
      object ErrorBox: TMemo
        Left = 1
        Top = 221
        Width = 348
        Height = 35
        Align = alBottom
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        ReadOnly = True
        TabOrder = 1
      end
    end
    object Panel3: TPanel
      Left = 0
      Top = 257
      Width = 350
      Height = 149
      Align = alTop
      TabOrder = 1
      object Label2: TLabel
        Left = 3
        Top = 2
        Width = 83
        Height = 13
        Caption = 'Computed Values'
      end
      object ComputedList: TValueListEditor
        Left = 1
        Top = 18
        Width = 348
        Height = 130
        Align = alBottom
        Enabled = False
        ScrollBars = ssVertical
        TabOrder = 0
        TitleCaptions.Strings = (
          'Key'
          'Value')
        ColWidths = (
          185
          157)
        RowHeights = (
          18
          18)
      end
    end
    object ComputedStylesMemo: TMemo
      Left = 0
      Top = 419
      Width = 350
      Height = 339
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Courier New'
      Font.Pitch = fpFixed
      Font.Style = []
      Font.Quality = fqClearType
      ParentFont = False
      ReadOnly = True
      TabOrder = 2
      WantTabs = True
      WordWrap = False
      OnChange = TemplateBoxChange
    end
  end
  object TreePopUp: TPopupMenu
    OnPopup = TreePopUpPopup
    Left = 240
    Top = 672
    object Load2: TMenuItem
      Caption = 'Load'
      OnClick = Load2Click
    end
    object Save2: TMenuItem
      Caption = 'Save'
      OnClick = Save2Click
    end
    object Delete1: TMenuItem
      Caption = 'Delete'
      OnClick = Delete1Click
    end
    object ExtractGSS1: TMenuItem
      Caption = 'Extract GSS'
      OnClick = ExtractGSS1Click
    end
    object ExtractdXML1: TMenuItem
      Caption = 'Extract dXML'
      OnClick = ExtractdXML1Click
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object AddComponent1: TMenuItem
      Caption = 'Add Component'
      OnClick = AddComponent1Click
    end
    object AddStack1: TMenuItem
      Caption = 'Add Stack'
      OnClick = AddStack1Click
    end
    object AddEdit1: TMenuItem
      Caption = 'Add Edit'
      OnClick = AddEdit1Click
    end
    object AddProgressbar1: TMenuItem
      Caption = 'Add Progressbar'
      OnClick = AddProgressbar1Click
    end
    object AddCheckbox1: TMenuItem
      Caption = 'Add Checkbox'
      OnClick = AddCheckbox1Click
    end
  end
  object MainMenu1: TMainMenu
    Left = 56
    Top = 672
    object File1: TMenuItem
      Caption = 'File'
      object New1: TMenuItem
        Caption = 'New'
        OnClick = New1Click
      end
      object Load1: TMenuItem
        Caption = 'Load'
        OnClick = Load1Click
      end
      object Save1: TMenuItem
        Caption = 'Save'
        OnClick = Save1Click
      end
    end
    object ChangeGraphicspath1: TMenuItem
      Caption = 'Change Graphicspath'
      OnClick = ChangeGraphicspath1Click
    end
    object Dirty1: TMenuItem
      Caption = 'Dirty'
      OnClick = Dirty1Click
    end
    object Settings1: TMenuItem
      Caption = 'Settings'
      object ShowElementborders1: TMenuItem
        AutoCheck = True
        Caption = 'Show Elementborders'
        Checked = True
      end
    end
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'gui'
    Filter = 'GUI-File|*.gui'
    Left = 120
    Top = 672
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = 'gui'
    Filter = 'GUI-File|*.gui'
    Left = 184
    Top = 672
  end
  object SaveDialogComponent: TSaveDialog
    DefaultExt = 'gco'
    Filter = 'GUI-Component-File|*.gco|All Files|*.*'
    Left = 296
    Top = 672
  end
  object OpenDialogComponent: TOpenDialog
    DefaultExt = 'gco'
    Filter = 'GUI-Component-File|*.gco|All Files|*.*'
    Left = 296
    Top = 720
  end
end
