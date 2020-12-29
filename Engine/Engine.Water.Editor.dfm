object WaterEditorForm: TWaterEditorForm
  Left = 1035
  Top = 57
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsToolWindow
  Caption = 'Water Editor'
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
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ToolBox: TCategoryPanelGroup
    Left = 0
    Top = 0
    Width = 302
    Height = 769
    VertScrollBar.Tracking = True
    Align = alClient
    HeaderFont.Charset = DEFAULT_CHARSET
    HeaderFont.Color = clWindowText
    HeaderFont.Height = -11
    HeaderFont.Name = 'Tahoma'
    HeaderFont.Style = []
    TabOrder = 0
    object CategoryPanel1: TCategoryPanel
      Top = 379
      Height = 1000
      Caption = 'Surface Water Options'
      TabOrder = 0
      ExplicitWidth = 300
      object WaveHeight: TLabel
        Left = 0
        Top = 0
        Width = 59
        Height = 13
        Align = alTop
        Caption = 'WaveHeight'
      end
      object Label1: TLabel
        Left = 0
        Top = 41
        Width = 53
        Height = 13
        Align = alTop
        Caption = 'Roughness'
      end
      object Label2: TLabel
        Left = 0
        Top = 79
        Width = 45
        Height = 13
        Align = alTop
        Caption = 'Exposure'
      end
      object Label3: TLabel
        Left = 0
        Top = 417
        Width = 71
        Height = 13
        Align = alTop
        Caption = 'Specularpower'
      end
      object Label5: TLabel
        Left = 0
        Top = 493
        Width = 33
        Height = 13
        Align = alTop
        Caption = 'Scaling'
      end
      object Label6: TLabel
        Left = 0
        Top = 569
        Width = 66
        Height = 13
        Align = alTop
        Caption = 'Transparency'
      end
      object Label4: TLabel
        Left = 0
        Top = 455
        Width = 84
        Height = 13
        Align = alTop
        Caption = 'SpecularIntensity'
      end
      object Label9: TLabel
        Left = 0
        Top = 531
        Width = 64
        Height = 13
        Align = alTop
        Caption = 'Fresneloffset'
      end
      object Label10: TLabel
        Left = 0
        Top = 607
        Width = 113
        Height = 13
        Align = alTop
        Caption = 'Range of depth opacity'
      end
      object Label11: TLabel
        Left = 0
        Top = 662
        Width = 79
        Height = 13
        Align = alTop
        Caption = 'Refraction index'
      end
      object Label12: TLabel
        Left = 0
        Top = 700
        Width = 92
        Height = 13
        Align = alTop
        Caption = 'Refraction Samples'
      end
      object Label13: TLabel
        Left = 0
        Top = 738
        Width = 105
        Height = 13
        Align = alTop
        Caption = 'Refraction Steplength'
      end
      object Label16: TLabel
        Left = 0
        Top = 793
        Width = 120
        Height = 13
        Align = alTop
        Caption = 'Range of color extinction'
      end
      object Label17: TLabel
        Left = 0
        Top = 831
        Width = 85
        Height = 13
        Align = alTop
        Caption = 'Range of caustics'
      end
      object Label18: TLabel
        Left = 0
        Top = 869
        Width = 67
        Height = 13
        Align = alTop
        Caption = 'Caustics scale'
      end
      object WaveHeightTrack: TTrackBar
        Tag = 20
        Left = 0
        Top = 13
        Width = 281
        Height = 28
        Align = alTop
        Max = 250
        Position = 130
        PositionToolTip = ptTop
        TabOrder = 0
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
      end
      object RoughnessTrack: TTrackBar
        Tag = 1
        Left = 0
        Top = 54
        Width = 281
        Height = 25
        Align = alTop
        Max = 250
        Position = 170
        PositionToolTip = ptTop
        TabOrder = 1
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
      end
      object ExposureTrack: TTrackBar
        Tag = 5
        Left = 0
        Top = 92
        Width = 281
        Height = 25
        Align = alTop
        Max = 250
        ParentShowHint = False
        Position = 18
        PositionToolTip = ptTop
        ShowHint = True
        TabOrder = 2
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
      end
      object ColorRadio: TRadioGroup
        Left = 0
        Top = 117
        Width = 281
        Height = 44
        Align = alTop
        Caption = 'ColorRadio'
        Columns = 2
        ItemIndex = 0
        Items.Strings = (
          'Sky'
          'Water')
        TabOrder = 3
        OnClick = BigChange
      end
      object SpecularPowerTrack: TTrackBar
        Tag = 200
        Left = 0
        Top = 430
        Width = 281
        Height = 25
        Align = alTop
        Max = 250
        Position = 100
        PositionToolTip = ptTop
        TabOrder = 4
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
      end
      object SpecularIntensityTrack: TTrackBar
        Tag = 1
        Left = 0
        Top = 468
        Width = 281
        Height = 25
        Align = alTop
        Max = 250
        ParentShowHint = False
        Position = 250
        PositionToolTip = ptTop
        ShowHint = True
        TabOrder = 5
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
      end
      object ScalingTrack: TTrackBar
        Tag = 500
        Left = 0
        Top = 506
        Width = 281
        Height = 25
        Align = alTop
        Max = 250
        ParentShowHint = False
        Position = 50
        PositionToolTip = ptTop
        ShowHint = True
        TabOrder = 6
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
      end
      object FresnelOffsetTrack: TTrackBar
        Tag = 1
        Left = 0
        Top = 544
        Width = 281
        Height = 25
        Align = alTop
        Max = 250
        ParentShowHint = False
        Position = 5
        PositionToolTip = ptTop
        ShowHint = True
        TabOrder = 7
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
      end
      object Panel1: TPanel
        Left = 0
        Top = 161
        Width = 281
        Height = 256
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 8
        object SaturationValueImage: TImage
          Left = 0
          Top = 0
          Width = 256
          Height = 256
          Align = alLeft
        end
        object HueImage: TImage
          Left = 256
          Top = 0
          Width = 25
          Height = 256
          Align = alRight
          ExplicitTop = -208
          ExplicitHeight = 249
        end
      end
      object TransparencyTrack: TTrackBar
        Tag = 1
        Left = 0
        Top = 582
        Width = 281
        Height = 25
        Align = alTop
        Max = 250
        ParentShowHint = False
        Position = 5
        PositionToolTip = ptTop
        ShowHint = True
        TabOrder = 9
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
      end
      object DepthOpacityRangeTrack: TTrackBar
        Tag = 30
        Left = 0
        Top = 620
        Width = 281
        Height = 25
        Align = alTop
        Max = 250
        ParentShowHint = False
        Position = 5
        PositionToolTip = ptTop
        ShowHint = True
        TabOrder = 10
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
      end
      object RefractionIndexTrack: TTrackBar
        Tag = 5
        Left = 0
        Top = 675
        Width = 281
        Height = 25
        Align = alTop
        Max = 250
        ParentShowHint = False
        Position = 75
        PositionToolTip = ptTop
        ShowHint = True
        TabOrder = 11
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
      end
      object RefractionSamplesTrack: TTrackBar
        Tag = 50
        Left = 0
        Top = 713
        Width = 281
        Height = 25
        Align = alTop
        Max = 250
        ParentShowHint = False
        Position = 75
        PositionToolTip = ptTop
        ShowHint = True
        TabOrder = 12
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
      end
      object RefractionSteplength: TTrackBar
        Tag = 20
        Left = 0
        Top = 751
        Width = 281
        Height = 25
        Align = alTop
        Max = 250
        ParentShowHint = False
        Position = 75
        PositionToolTip = ptTop
        ShowHint = True
        TabOrder = 13
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
      end
      object ColorExtinctionTrack: TTrackBar
        Tag = 250
        Left = 0
        Top = 806
        Width = 281
        Height = 25
        Align = alTop
        Max = 250
        ParentShowHint = False
        Position = 5
        PositionToolTip = ptTop
        ShowHint = True
        TabOrder = 14
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
      end
      object ReflectionCheck: TCheckBox
        Left = 0
        Top = 776
        Width = 281
        Height = 17
        Align = alTop
        Caption = 'Reflection'
        TabOrder = 15
        OnClick = BigChange
      end
      object RefractionCheck: TCheckBox
        Left = 0
        Top = 645
        Width = 281
        Height = 17
        Align = alTop
        Caption = 'Refraction'
        TabOrder = 16
        OnClick = BigChange
      end
      object CausticsRangeTrack: TTrackBar
        Tag = 250
        Left = 0
        Top = 844
        Width = 281
        Height = 25
        Align = alTop
        Max = 250
        ParentShowHint = False
        Position = 5
        PositionToolTip = ptTop
        ShowHint = True
        TabOrder = 17
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
      end
      object CausticsScaleTrack: TTrackBar
        Tag = 25
        Left = 0
        Top = 882
        Width = 281
        Height = 25
        Align = alTop
        Max = 250
        ParentShowHint = False
        Position = 10
        PositionToolTip = ptTop
        ShowHint = True
        TabOrder = 18
        TickMarks = tmBoth
        TickStyle = tsNone
        OnChange = BigChange
        ExplicitLeft = 8
        ExplicitTop = 940
      end
    end
    object CategoryPanel3: TCategoryPanel
      Top = 200
      Height = 179
      Caption = 'General Surface Options'
      TabOrder = 1
      ExplicitWidth = 300
      object Label7: TLabel
        Left = 0
        Top = 0
        Width = 100
        Height = 13
        Align = alTop
        Caption = 'Geometry Resolution'
      end
      object Label8: TLabel
        Left = 0
        Top = 34
        Width = 17
        Height = 13
        Align = alTop
        Caption = 'Sky'
      end
      object Label14: TLabel
        Left = 0
        Top = 70
        Width = 38
        Height = 13
        Align = alTop
        Caption = 'Texture'
      end
      object Label15: TLabel
        Left = 0
        Top = 106
        Width = 40
        Height = 13
        Align = alTop
        Caption = 'Caustics'
      end
      object GeometryResolutionEdit: TEdit
        Left = 0
        Top = 13
        Width = 281
        Height = 21
        Align = alTop
        TabOrder = 0
        Text = '200'
        OnChange = BigChange
      end
      object Panel3: TPanel
        Left = 0
        Top = 83
        Width = 281
        Height = 23
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        object TextureEdit: TEdit
          Left = 0
          Top = 0
          Width = 256
          Height = 23
          Align = alLeft
          ParentShowHint = False
          ReadOnly = True
          ShowHint = True
          TabOrder = 0
          OnClick = BigChange
          ExplicitHeight = 21
        end
        object TextureRemoveBtn: TButton
          Left = 256
          Top = 0
          Width = 25
          Height = 23
          Align = alRight
          Caption = 'X'
          TabOrder = 1
          OnClick = BigChange
        end
      end
      object Panel4: TPanel
        Left = 0
        Top = 47
        Width = 281
        Height = 23
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 2
        object SkyEdit: TEdit
          Left = 0
          Top = 0
          Width = 256
          Height = 23
          Align = alLeft
          ParentShowHint = False
          ReadOnly = True
          ShowHint = True
          TabOrder = 0
          OnClick = BigChange
          ExplicitHeight = 21
        end
        object SkyRemoveBtn: TButton
          Left = 256
          Top = 0
          Width = 25
          Height = 23
          Align = alRight
          Caption = 'X'
          TabOrder = 1
          OnClick = BigChange
        end
      end
      object Panel5: TPanel
        Left = 0
        Top = 119
        Width = 281
        Height = 23
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 3
        object CausticsEdit: TEdit
          Left = 0
          Top = 0
          Width = 256
          Height = 23
          Align = alLeft
          ParentShowHint = False
          ReadOnly = True
          ShowHint = True
          TabOrder = 0
          OnClick = BigChange
          ExplicitHeight = 21
        end
        object CausticsRemoveBtn: TButton
          Left = 256
          Top = 0
          Width = 25
          Height = 23
          Align = alRight
          Caption = 'X'
          TabOrder = 1
          OnClick = BigChange
        end
      end
    end
    object CategoryPanel2: TCategoryPanel
      Top = 0
      Caption = 'Water Surfaces'
      TabOrder = 2
      ExplicitWidth = 300
      object WaterSurfaceList: TListBox
        Left = 0
        Top = 0
        Width = 281
        Height = 121
        Align = alTop
        ItemHeight = 13
        TabOrder = 0
        OnClick = BigChange
      end
      object SelectionCheck: TCheckBox
        Left = 0
        Top = 145
        Width = 281
        Height = 18
        Align = alTop
        Caption = 'Show Selection'
        Checked = True
        State = cbChecked
        TabOrder = 1
      end
      object Panel2: TPanel
        Left = 0
        Top = 121
        Width = 281
        Height = 24
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 2
        object AddSurfaceBtn: TButton
          Left = 0
          Top = 0
          Width = 140
          Height = 24
          Align = alLeft
          Caption = 'Add'
          TabOrder = 0
          OnClick = BigChange
        end
        object DeleteSurfaceBtn: TButton
          Left = 141
          Top = 0
          Width = 140
          Height = 24
          Align = alRight
          Caption = 'Delete'
          TabOrder = 1
          OnClick = BigChange
        end
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
    end
  end
  object WaterOpenDialog: TOpenDialog
    DefaultExt = 'wat'
    Filter = 'Water (*.wat)|*.wat'
    Left = 96
    Top = 8
  end
  object WaterSaveDialog: TSaveDialog
    DefaultExt = 'wat'
    Filter = 'Water (*.wat)|*.wat'
    Left = 168
    Top = 8
  end
end
