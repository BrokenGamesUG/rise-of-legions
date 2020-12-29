unit MapEditorToolBox;

interface

uses
  BaseConflict.Constants,
  BaseConflict.Globals,
  BaseConflict.Map,
  BaseConflict.Map.Client,
  BaseConflict.Globals.Client,

  Engine.Helferlein.Windows,

  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.Samples.Spin,
  Vcl.Buttons,
  Vcl.ExtCtrls,
  Vcl.Menus;

type
  TToolWindow = class(TForm)
    ToolBox : TCategoryPanelGroup;
    ZonePanel : TCategoryPanel;
    Label7 : TLabel;
    ZoneList : TListBox;
    ZoneEdit : TEdit;
    ZoneAddBtn : TButton;
    ReferenceEntitiesTab : TCategoryPanel;
    Label10 : TLabel;
    Label11 : TLabel;
    ReferenceEntityPatternList : TListBox;
    ReferenceEntitiesList : TListBox;
    FreezeReferenceCheck : TCheckBox;
    DecoTab : TCategoryPanel;
    Label5 : TLabel;
    Label6 : TLabel;
    DecoUnitsList : TListBox;
    ExistingDecoList : TListBox;
    DecoPatternRefreshBtn : TButton;
    DecoValueGroup : TGroupBox;
    Label12 : TLabel;
    Label13 : TLabel;
    Label14 : TLabel;
    DecoValuePositionXEdit : TEdit;
    DecoValuePositionYEdit : TEdit;
    DecoValuePositionZEdit : TEdit;
    DecoValueRotationEdit : TEdit;
    DecoValueSizeEdit : TEdit;
    DecoValueFreezeCheck : TCheckBox;
    LaneTab : TCategoryPanel;
    PlaceLaneSpeed : TSpeedButton;
    LanesList : TListBox;
    GeneralTab : TCategoryPanel;
    Label1 : TLabel;
    Label2 : TLabel;
    MaxPlayerEdit : TSpinEdit;
    TeamCountEdit : TSpinEdit;
    Memo1 : TMemo;
    ReferencePopupMenu : TPopupMenu;
    CopyEntitiesToClipboardBtn : TMenuItem;
    ZoneExportBtn: TButton;
    ZoneSaveDialog: TSaveDialog;
    procedure BigChange(Sender : TObject);
    procedure ZoneListDblClick(Sender : TObject);
    procedure FormCreate(Sender : TObject);
    procedure CopyEntitiesToClipboardBtnClick(Sender : TObject);
    private
      { Private-Deklarationen }
    public
      { Public-Deklarationen }
      procedure Init;
  end;

var
  ToolWindow : TToolWindow;

implementation

uses
  MapEditorMain;

{$R *.dfm}


procedure TToolWindow.BigChange(Sender : TObject);
begin
  if (Map = nil) or (ClientMap = nil) then exit;
  ModuleManager.GUIEvent(Sender);
  if Sender = GeneralTab then
  begin
    MaxPlayerEdit.Value := Map.PlayerCount;
    TeamCountEdit.Value := Map.TeamCount;
  end;
  if Sender = MaxPlayerEdit then
  begin
    Map.PlayerCount := MaxPlayerEdit.Value;
  end;
  if Sender = TeamCountEdit then
  begin
    Map.TeamCount := TeamCountEdit.Value;
  end;
end;

procedure TToolWindow.CopyEntitiesToClipboardBtnClick(Sender : TObject);
begin
  ModuleManager.GetModule<TReferenceModule>.CopyEntitiesToClipboard
end;

procedure TToolWindow.FormCreate(Sender : TObject);
var
  TargetMonitor : integer;
begin
  if Screen.MonitorCount > 1 then
  begin
    if Screen.PrimaryMonitor.MonitorNum = 0 then TargetMonitor := 1
    else TargetMonitor := 0;
    Left := Screen.Monitors[TargetMonitor].WorkareaRect.Left + Screen.Monitors[TargetMonitor].WorkareaRect.Width - Width;
    Top := Screen.Monitors[TargetMonitor].WorkareaRect.Top;
    Height := Screen.Monitors[TargetMonitor].WorkareaRect.Height;
  end;
  Init;
end;

procedure TToolWindow.Init;
begin
  BigChange(GeneralTab);
  BigChange(DecoTab);
  BigChange(ReferenceEntitiesTab);
  BigChange(LaneTab);
  BigChange(ZonePanel);
  BigChange(Hauptform.ShowReferenceEntities1);
end;

procedure TToolWindow.ZoneListDblClick(Sender : TObject);
var
  str : string;
begin
  if ZoneList.ItemIndex <> -1 then
  begin
    str := InputBox('Rename', 'Type in new name for Zone', ZoneList.Items[ZoneList.ItemIndex]);
    if Map.Zones.ContainsKey(str) then exit;
    Map.Zones.Add(str, Map.Zones.ExtractPair(ZoneList.Items[ZoneList.ItemIndex]).Value);
    ZoneList.Items[ZoneList.ItemIndex] := str;
  end;
end;

end.
