unit main;

{$mode objfpc}{$H+}

interface

uses
  // Dev Add
  ElgWOL, FilesManager, Windows, Registry,
  // Automatic Add
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  Buttons, ExtCtrls, StdCtrls, Menus, Types;

type

  { TForm1 }

  TForm1 = class(TForm)
    BtnAdd: TSpeedButton;
    BtnRemove: TSpeedButton;
    CheckBoxLoadOnBoot: TCheckBox;
    Image1: TImage;
    ImageBackground: TImage;
    LabelLoadOnBoot: TLabel;
    ListMAC: TListView;
    BtnWakeup: TSpeedButton;
    MenuItemModify: TMenuItem;
    MenuItemName: TMenuItem;
    MenuItemMac: TMenuItem;
    MenuItemRemove: TMenuItem;
    MenuItemAdd: TMenuItem;
    MenuItemWakeUp: TMenuItem;
    MenuItemExit: TMenuItem;
    MenuItemHide: TMenuItem;
    MenuItemShow: TMenuItem;
    PopupMenu1: TPopupMenu;
    PopupMenuListMAC: TPopupMenu;
    TrayIcon1: TTrayIcon;
    procedure CheckBoxLoadOnBootChange(Sender: TObject);
    procedure ConfigLoad;
    procedure ConfigSave;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnRemoveClick(Sender: TObject);
    procedure BtnWakeupClick(Sender: TObject);
    procedure LabelLoadOnBootClick(Sender: TObject);
    procedure ListMACContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure MenuItemMacClick(Sender: TObject);
    procedure MenuItemNameClick(Sender: TObject);
    procedure MenuItemExitClick(Sender: TObject);
    procedure MenuItemHideClick(Sender: TObject);
    procedure MenuItemShowClick(Sender: TObject);
    procedure MenuItemWakeUpClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  SelectedListItem :TListItem;

implementation

{$R *.lfm}

{ TForm1 }
procedure TForm1.ConfigLoad;
var
  i: Integer;
  dataName, dataMac: TStringList;
  NewColumn: TListColumn;
  NewRow: TListItem;
  Reg: TRegistry;
begin
  // Check load on boot
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  if Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run', True) then
  begin
    CheckBoxLoadOnBoot.Checked := Reg.ValueExists(ExtractFileName(Application.ExeName));
    Reg.CloseKey;
  end;
  Reg.Free;

  // Load ListMAC
  ListMAC.Clear;
  NewColumn := ListMAC.Columns.Add;
  NewColumn.Caption := 'Name';
  NewColumn.Width := 110;
  NewColumn := ListMAC.Columns.Add;
  NewColumn.Caption := 'MAC';
  NewColumn.Width := 110;
  if not FileExists('NameList.txt') then Exit;
  dataName := FilesManager.ReadFileToStringList('NameList.txt');
  if not FileExists('MacList.txt') then Exit;
  dataMac := FilesManager.ReadFileToStringList('MacList.txt');
  if dataName.Count = 0 then Exit;
  if dataMac.Count = 0 then Exit;
  for i := 0 to dataName.Count -1 do
  begin
    NewRow := ListMAC.Items.Add;
    NewRow.Caption := dataName.Strings[i];
    if i < dataMac.Count then
      NewRow.SubItems.Add(dataMac.Strings[i]);
  end;

end;


procedure TForm1.ConfigSave;
var
  i: Integer;
  data: TStringList;
begin
  // Save Name
  data := TStringList.Create;
  for i := 0 to ListMAC.Items.Count -1 do
    data.Add(ListMAC.Items.Item[i].Caption);
  if data.Count = 0 then Exit;
  FilesManager.WriteStringListInFile('NameList.txt', data);
  if not FileExists('NameList.txt') then MessageBoxA( Handle, PChar('Warning : Database save fail!'), PChar('Warning'), MB_ICONERROR );
  // Save Mac
  data := TStringList.Create;
  for i := 0 to ListMAC.Items.Count -1 do
    data.Add(ListMAC.Items.Item[i].SubItems[0]);
  if data.Count = 0 then Exit;
  FilesManager.WriteStringListInFile('MacList.txt', data);
  if not FileExists('MacList.txt') then MessageBoxA( Handle, PChar('Warning : Database save fail!'), PChar('Warning'), MB_ICONERROR );
end;

procedure TForm1.BtnWakeupClick(Sender: TObject);
var
  Cmpt : Integer;
begin
  if ( ListMAC.Items.Count = 0 ) then
  begin
    MessageBoxA( Handle, PChar('First, add a computer in list!'), PChar('Stop'), MB_ICONWARNING );
    Exit;
  end;
  BtnWakeup.Enabled := False;
  for Cmpt := 0 to ( ListMAC.Items.Count - 1 ) do
  begin
    GoWOL( ListMAC.Items.Item[Cmpt].SubItems[0] );
    Sleep( 1500 );
  end;
  BtnWakeup.Enabled := True;
end;


procedure TForm1.MenuItemShowClick(Sender: TObject);
begin
  Application.ShowMainForm := True;
  Show;
end;



procedure TForm1.MenuItemHideClick(Sender: TObject);
begin
  Application.ShowMainForm := False;
  Hide;
end;

procedure TForm1.MenuItemExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  mac: String;
begin
  SetCurrentDir(ExtractFileDir(Application.ExeName));
  // Command line (use: WakeOnLan.exe "MAC")
  if ParamCount() > 0 then
  begin
    if LowerCase(ParamStr(1)).Contains('background') then
    begin
      MenuItemHideClick(nil);
    end else begin
      mac := LowerCase(ParamStr(1));
      GoWOL(mac);
      Application.Terminate;
      Exit;
    end;
  end;
  ImageBackground.Align := alClient;
  Form1.DoubleBuffered := True;
  ConfigLoad;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  ConfigSave;
end;

procedure TForm1.BtnAddClick(Sender: TObject);
var
  NewMAC, NewName : String;
  NewRow: TListItem;
const
  DEFAULT_MAC = '00-00-00-00-00-00';
begin
  NewMAC := InputBox( 'Add a computer', 'Please enter a MAC adress:', DEFAULT_MAC );
  NewMAC := Trim(NewMAC);
  if (NewMAC = '') or (NewMAC = DEFAULT_MAC) then Exit;
  if Length(NewMAC) <> 17 then
  begin
    MessageBoxA( Handle, PChar('Mac adress is not valid!'), PChar('Incorrect'), MB_ICONWARNING );
  end;

  NewName := InputBox('Add a computer', 'Please enter a computer name:', '');
  NewName := Trim(NewName);
  if NewName = '' then NewName := NewMAC;

  NewRow := ListMAC.Items.Add;
  NewRow.Caption := NewName;
  NewRow.SubItems.Add(NewMAC);

  ConfigSave;
end;

procedure TForm1.BtnRemoveClick(Sender: TObject);
begin
  if MessageDlg(PChar('Remove "'+ListMAC.Selected.Caption+'"?'),  mtConfirmation, [mbYes, mbNo], 0) <> IDYES then Exit;
  if ( ListMAC.ItemIndex < 0 ) then
  begin
    MessageBoxA( Handle, PChar('Please select an item before delete it!'), PChar('Warning'), MB_ICONWARNING );
    Exit;
  end;
  ListMAC.Items.Delete( ListMAC.ItemIndex );
  ConfigSave;
end;


procedure TForm1.CheckBoxLoadOnBootChange(Sender: TObject);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  try
  if Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run', True) then
  begin
    if TCheckBox(Sender).Checked then
      Reg.WriteString(ExtractFileName(Application.ExeName), '"'+Application.ExeName+'" /background')
    else
      Reg.DeleteValue(ExtractFileName(Application.ExeName));
    Reg.CloseKey;
  end;
  finally
    Reg.Free;
  end;
end;

procedure TForm1.LabelLoadOnBootClick(Sender: TObject);
begin
  CheckBoxLoadOnBoot.Checked:= not CheckBoxLoadOnBoot.Checked;
end;

procedure TForm1.ListMACContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var
  ListItem:TListItem;
  CurPos:TPoint;
  isItemSelected: Boolean;
begin
  GetcursorPos(MousePos);
  CurPos:=TListView(Sender).ScreenToClient(MousePos);
  ListItem:=TListView(Sender).GetItemAt(CurPos.x,CurPos.y);
  isItemSelected := Assigned(ListItem);
  MenuItemWakeUp.Visible:= isItemSelected;
  MenuItemRemove.Visible:= isItemSelected;
  MenuItemModify.Visible:= isItemSelected;
  if isItemSelected then
  begin
    MenuItemWakeUp.Caption := 'WakeUp "'+ListItem.Caption+'"';
    MenuItemRemove.Caption := 'Remove "'+ListItem.Caption+'"';
  end;
  PopupMenuListMAC.Popup(MousePos.x, MousePos.y);
end;

procedure TForm1.MenuItemMacClick(Sender: TObject);
var
  i: Integer;
  default, NewMAC: String;
begin
  i := ListMAC.ItemIndex;
  if i = -1  then
  begin
    MessageBoxA( Handle, PChar('Please select an item before modify it!'), PChar('Warning'), MB_ICONWARNING );
    Exit;
  end;
  default := ListMAC.Items[i].SubItems[0];
  NewMAC := InputBox( 'Add a computer', 'Please enter a MAC adress:', default );
  NewMAC := Trim(NewMAC);
  if NewMAC = '' then Exit;
  if Length(NewMAC) <> 17 then
  begin
    MessageBoxA( Handle, PChar('Mac adress is not valid!'), PChar('Incorrect'), MB_ICONWARNING );
  end;
  ListMAC.Items[i].SubItems[0] := NewMAC;
  ConfigSave;
end;

procedure TForm1.MenuItemNameClick(Sender: TObject);
var
  i: Integer;
  default, NewName: String;
begin
  i := ListMAC.ItemIndex;
  if i = -1  then
  begin
    MessageBoxA( Handle, PChar('Please select an item before modify it!'), PChar('Warning'), MB_ICONWARNING );
    Exit;
  end;
  default := ListMAC.Items[ListMAC.ItemIndex].Caption;
  NewName := InputBox('Add a computer', 'Please enter a computer name:', default);
  NewName := Trim(NewName);
  if NewName = '' then Exit;
  ListMAC.Items[ListMAC.ItemIndex].Caption := NewName;
  ConfigSave;
end;

procedure TForm1.MenuItemWakeUpClick(Sender: TObject);
begin
  if not Assigned(ListMAC.Selected) then Exit;
  GoWOL(ListMAC.Selected.SubItems[0]);
  //ShowMessage(ListMAC.Selected.SubItems[0]);
end;

end.

