object Hauptform: THauptform
  Left = 563
  Top = 157
  Caption = 'Hauptform'
  ClientHeight = 737
  ClientWidth = 956
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Verdana'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object RenderPanel: TPanel
    Left = 0
    Top = 0
    Width = 956
    Height = 718
    Align = alClient
    TabOrder = 0
    OnResize = RenderPanelResize
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 718
    Width = 956
    Height = 19
    Panels = <
      item
        Width = 50
      end>
  end
  object ApplicationEvents1: TApplicationEvents
    OnActivate = FormActivate
    OnDeactivate = FormDeactivate
    OnException = ApplicationEvents1Exception
    OnIdle = ApplicationEvents1Idle
    Left = 32
    Top = 32
  end
  object MainMenu1: TMainMenu
    Left = 120
    Top = 32
    object Datei1: TMenuItem
      Caption = 'Datei'
      object Neu1: TMenuItem
        Caption = 'New'
        ShortCut = 16462
        OnClick = Neu1Click
      end
      object Open1: TMenuItem
        Caption = 'Open'
        ShortCut = 16463
        OnClick = Open1Click
      end
      object Save1: TMenuItem
        Caption = 'Save'
        ShortCut = 16467
        OnClick = Save1Click
      end
      object Saveas1: TMenuItem
        Caption = 'Save as'
        ShortCut = 49235
        OnClick = Saveas1Click
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Beenden1: TMenuItem
        Caption = 'Beenden'
        ShortCut = 16472
        OnClick = Beenden1Click
      end
    end
    object View1: TMenuItem
      Caption = 'View'
      object ShowGrid1: TMenuItem
        AutoCheck = True
        Caption = 'Show Grid'
      end
      object ShowWater1: TMenuItem
        AutoCheck = True
        Caption = 'Show Water'
        Checked = True
      end
      object ShowVegetation1: TMenuItem
        AutoCheck = True
        Caption = 'Show Vegetation'
        Checked = True
      end
      object ResetCamera1: TMenuItem
        Caption = 'Reset Camera'
        OnClick = Bigchange
      end
      object ShowZonesCheck: TMenuItem
        AutoCheck = True
        Caption = 'Show Zones'
      end
      object ShowDropzonesCheck: TMenuItem
        AutoCheck = True
        Caption = 'Show Dropzones'
      end
      object ShowReferenceEntities1: TMenuItem
        AutoCheck = True
        Caption = 'Show Reference Entities'
        Checked = True
        OnClick = Bigchange
      end
      object LoadReferenceEntitiesfromFile1: TMenuItem
        Caption = 'Load Reference Entities from File'
        OnClick = LoadReferenceEntitiesfromFile1Click
      end
      object GraphicReduction1: TMenuItem
        Caption = 'Graphic Reduction'
        OnClick = GraphicReduction1Click
      end
    end
    object SnaptoGrid1: TMenuItem
      Caption = 'Options'
      object Snaptogrid: TMenuItem
        AutoCheck = True
        Caption = 'Snap to grid'
      end
      object Limitcamera1: TMenuItem
        AutoCheck = True
        Caption = 'Limit camera'
        Checked = True
        OnClick = Bigchange
      end
      object TargetGamePlaneCheck: TMenuItem
        AutoCheck = True
        Caption = 'Target Game Plane'
        Checked = True
      end
      object VerticalCamera1: TMenuItem
        AutoCheck = True
        Caption = 'Vertical Camera'
      end
      object FreeCameraCheck: TMenuItem
        AutoCheck = True
        Caption = 'FPS Camera'
      end
      object SetBackgroundColor1: TMenuItem
        Caption = 'Set BackgroundColor'
        OnClick = SetBackgroundColor1Click
      end
    end
    object Window1: TMenuItem
      Caption = 'Window'
      object MapEditor1: TMenuItem
        Caption = 'Map Editor'
        OnClick = MapEditor1Click
      end
      object erraineditor1: TMenuItem
        Caption = 'Terraineditor'
        OnClick = ShowEditorClick
      end
      object WaterEditor1: TMenuItem
        Tag = 1
        Caption = 'Watereditor'
        OnClick = ShowEditorClick
      end
      object Vegetationeditor1: TMenuItem
        Tag = 2
        Caption = 'Vegetationeditor'
        OnClick = ShowEditorClick
      end
      object Sceneeditor1: TMenuItem
        Tag = 3
        Caption = 'Sceneeditor'
        OnClick = ShowEditorClick
      end
      object Posteffects1: TMenuItem
        Caption = 'Posteffects'
        OnClick = Posteffects1Click
      end
      object ShowMaterialEditorBtn: TMenuItem
        Caption = 'Material Editor'
        OnClick = ShowMaterialEditorBtnClick
      end
    end
  end
  object MapSaveDialog: TSaveDialog
    DefaultExt = 'bcm'
    Filter = 'BaseConflict-Map (*.bcm)|*.bcm'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 120
    Top = 96
  end
  object MapOpenDialog: TOpenDialog
    DefaultExt = 'bcm'
    Filter = 'BaseConflict-Map (*.bcm)|*.bcm'
    Left = 32
    Top = 96
  end
  object BuildPopupMenu: TPopupMenu
    Left = 37
    Top = 160
    object BuildAddGrid: TMenuItem
      Caption = 'Add Grid'
      OnClick = Bigchange
    end
    object BuildDeleteGrid: TMenuItem
      Caption = 'Delete Grid'
      OnClick = Bigchange
    end
  end
  object ColorDialog1: TColorDialog
    Color = clGray
    Options = [cdFullOpen]
    Left = 120
    Top = 160
  end
  object ReferenceOpenDialog: TOpenDialog
    DefaultExt = 'dme'
    Filter = 'BaseConflict-References (*.dme)|*.dme'
    Left = 32
    Top = 224
  end
end
