object VegetationEditorForm: TVegetationEditorForm
  Left = 1510
  Top = 99
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsToolWindow
  Caption = 'Vegetation Editor'
  ClientHeight = 769
  ClientWidth = 302
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  Menu = MainMenu1
  OldCreateOrder = False
  ScreenSnap = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object StatBox: TListBox
    Left = 0
    Top = 0
    Width = 302
    Height = 75
    Align = alTop
    DoubleBuffered = True
    ItemHeight = 13
    ParentDoubleBuffered = False
    TabOrder = 0
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 75
    Width = 302
    Height = 694
    ActivePage = MeshSheet
    Align = alClient
    TabOrder = 1
    OnChange = BigChange
    object GeneralSheet: TTabSheet
      Caption = 'General'
      ImageIndex = 2
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object GeneralCategoryPanel: TPanel
        Left = 0
        Top = 0
        Width = 294
        Height = 41
        Align = alTop
        AutoSize = True
        TabOrder = 0
      end
    end
    object TreeSheet: TTabSheet
      Caption = 'Trees'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object MouseModeRadio: TRadioGroup
        Left = 0
        Top = 0
        Width = 294
        Height = 41
        Align = alTop
        Caption = 'Mode'
        Columns = 2
        ItemIndex = 0
        Items.Strings = (
          'Select'
          'Add')
        TabOrder = 0
        OnClick = BigChange
      end
      object TreeDetailPanelPanel: TPanel
        Left = 0
        Top = 41
        Width = 294
        Height = 41
        Align = alTop
        AutoSize = True
        TabOrder = 1
      end
    end
    object GrassSheet: TTabSheet
      Caption = 'Grass'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object GrassGeneralPanelPanel: TPanel
        Left = 0
        Top = 0
        Width = 294
        Height = 41
        Align = alTop
        AutoSize = True
        TabOrder = 0
      end
      object GrassDetailPanelPanel: TPanel
        Left = 0
        Top = 41
        Width = 294
        Height = 41
        Align = alTop
        AutoSize = True
        TabOrder = 1
      end
    end
    object MeshSheet: TTabSheet
      Caption = 'MeshSheet'
      ImageIndex = 3
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object MeshGeneralPanel: TPanel
        Left = 0
        Top = 0
        Width = 294
        Height = 41
        Align = alTop
        AutoSize = True
        TabOrder = 0
      end
      object MeshDetailPanel: TPanel
        Left = 0
        Top = 41
        Width = 294
        Height = 41
        Align = alTop
        AutoSize = True
        TabOrder = 1
      end
    end
  end
  object TextureOpenDialog: TOpenDialog
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 240
    Top = 8
  end
  object MainMenu1: TMainMenu
    Left = 24
    Top = 8
    object File1: TMenuItem
      Caption = 'File'
      object New1: TMenuItem
        Caption = 'New'
        OnClick = New1Click
      end
      object Open1: TMenuItem
        Caption = 'Open'
        OnClick = Open1Click
      end
      object Save2: TMenuItem
        Caption = 'Save'
        OnClick = Save2Click
      end
      object Saveas1: TMenuItem
        Caption = 'Save as'
        OnClick = Saveas1Click
      end
    end
    object Save1: TMenuItem
      Caption = 'Options'
      object WireFrameCheck: TMenuItem
        AutoCheck = True
        Caption = 'Wireframe'
        OnClick = BigChange
      end
      object DrawkdTree1: TMenuItem
        AutoCheck = True
        Caption = 'Draw kdTree'
        OnClick = BigChange
      end
    end
    object Action1: TMenuItem
      Caption = 'Actions'
      object Mirror1: TMenuItem
        Caption = 'Symmetry'
        object MirrorXToNegativeXBtn: TMenuItem
          Caption = 'X -> -X'
          OnClick = BigChange
        end
        object MirrorNegativeXToXBtn: TMenuItem
          Caption = '-X -> X'
          OnClick = BigChange
        end
        object MirrorZToNegativeZBtn: TMenuItem
          Caption = 'Z -> -Z'
          OnClick = BigChange
        end
        object MirrorNegativeZToZBtn: TMenuItem
          Caption = '-Z -> Z'
          OnClick = BigChange
        end
        object N1: TMenuItem
          Caption = '-'
        end
        object PointMirrorXToNegativeXBtn: TMenuItem
          Caption = 'XZ -> -X(1-Z)'
          OnClick = BigChange
        end
        object PointMirrorNegativeXToXBtn: TMenuItem
          Caption = '-XZ -> X(1-Z)'
          OnClick = BigChange
        end
        object PointMirrorZToNegativeZBtn: TMenuItem
          Caption = 'XZ -> (1-X)-Z'
          OnClick = BigChange
        end
        object PointMirrorNegativeZToZBtn: TMenuItem
          Caption = 'X-Z -> (1-X)Z'
          OnClick = BigChange
        end
      end
    end
  end
  object VegetationOpenDialog: TOpenDialog
    DefaultExt = 'veg'
    Filter = 'Vegetation (*.veg)|*.veg'
    Left = 96
    Top = 8
  end
  object VegetationSaveDialog: TSaveDialog
    DefaultExt = 'veg'
    Filter = 'Vegetation (*.veg)|*.veg'
    Left = 168
    Top = 8
  end
end
