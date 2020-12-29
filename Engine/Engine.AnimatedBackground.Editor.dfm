object AnimatedImageEditorForm: TAnimatedImageEditorForm
  Left = 1035
  Top = 57
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsToolWindow
  Caption = 'Animated Image Editor'
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
    object CategoryPanel2: TCategoryPanel
      Top = 0
      Height = 353
      Caption = 'Layer'
      TabOrder = 0
      object Label1: TLabel
        Left = 8
        Top = 128
        Width = 146
        Height = 26
        Caption = 'Shift + L-Mouse - Place Vertex Strg + L-Mouse - Set Index'
        WordWrap = True
      end
      object Label2: TLabel
        Left = 8
        Top = 200
        Width = 47
        Height = 13
        Caption = 'TimeScale'
      end
      object Label3: TLabel
        Left = 152
        Top = 200
        Width = 29
        Height = 13
        Caption = 'Depth'
      end
      object LayerList: TListBox
        Left = 0
        Top = 0
        Width = 298
        Height = 121
        Align = alTop
        ItemHeight = 13
        TabOrder = 0
        OnClick = BigChange
      end
      object Panel2: TPanel
        Left = 0
        Top = 121
        Width = 298
        Height = 0
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
      end
      object TimeLineTrack: TTrackBar
        Left = -1
        Top = 168
        Width = 298
        Height = 33
        Max = 300
        ParentShowHint = False
        PositionToolTip = ptTop
        ShowHint = False
        TabOrder = 2
        TickMarks = tmBoth
        TickStyle = tsNone
      end
      object TimeScaleEdit: TEdit
        Left = 8
        Top = 216
        Width = 121
        Height = 21
        TabOrder = 3
        Text = '1'
        OnChange = BigChange
      end
      object ClearKeyframesBtn: TButton
        Left = 8
        Top = 243
        Width = 146
        Height = 25
        Caption = 'Clear Keyframes for Vertex'
        TabOrder = 4
        OnClick = BigChange
      end
      object RemoveVertexButton: TButton
        Left = 8
        Top = 274
        Width = 177
        Height = 25
        Caption = 'Remove Vertex and its Triangles'
        TabOrder = 5
        OnClick = BigChange
      end
      object LayerDepthEdit: TEdit
        Left = 152
        Top = 216
        Width = 121
        Height = 21
        TabOrder = 6
        Text = '1'
        OnChange = BigChange
      end
    end
  end
  object MainMenu1: TMainMenu
    Left = 136
    Top = 8
    object File1: TMenuItem
      Caption = 'File'
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
      object Animated1: TMenuItem
        AutoCheck = True
        Caption = 'Animated'
      end
    end
  end
  object OpenDialog: TOpenDialog
    DefaultExt = 'anb'
    Filter = 'Animated Background (*.anb)|*.anb|All Files (*.*)|*.*'
    Left = 208
    Top = 8
  end
  object SaveDialog: TSaveDialog
    DefaultExt = 'anb'
    Filter = 'Animated Background (*.anb)|*.anb|All Files (*.*)|*.*'
    Left = 168
    Top = 8
  end
end
